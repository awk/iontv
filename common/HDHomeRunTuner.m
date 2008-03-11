// libRecSchedCommon - Common code shared between UI application and background server
// Copyright (C) 2007 Andrew Kimpton
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "HDHomeRunTuner.h"
#import "HDHomeRunMO.h"
#import "hdhomerun_channelscan.h"
#import "hdhomerun_video.h"
#import "RSActivityDisplayProtocol.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"
#import "Z2ITStation.h"
#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSNotifications.h"

const int kCallSignStringLength = 10;

@interface HDHomeRunTunerChannelScanThread : NSObject

+ (void) performScan:(HDHomeRunTuner*)aTuner;

@end;

// coalesce these into one @interface HDHomeRunTuner (CoreDataGeneratedPrimitiveAccessors) section
@interface HDHomeRunTuner (CoreDataGeneratedPrimitiveAccessors)

- (HDHomeRun*)primitiveDevice;
- (void)setPrimitiveDevice:(HDHomeRun*)value;
- (NSMutableSet*)primitiveChannels;
- (void)setPrimitiveChannels:(NSMutableSet*)value;

@end

@interface HDHomeRunTuner (Private)
- (void) createHDHRDevice;
- (void) releaseHDHRDevice;
@end

@implementation HDHomeRunTuner

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"device",@"index", @"lineup", nil]
      triggerChangeNotificationsForDependentKey:@"longName"];
}

+ (NSArray *) allTunersInManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

@dynamic index;
@dynamic channels;
@dynamic device;
@dynamic lineup;
@dynamic longName;
@dynamic recordings;

- (NSString*) longName
{
  NSString *name = [NSString stringWithFormat:@"%@:%d %@", [[self device] name], [[self index] intValue]+1, [[self lineup] name]];
  return name;
}

- (void) deleteAllChannelsInMOC:(NSManagedObjectContext *)inMOC
{
  NSArray *channelsArray = [self.channels allObjects];
  for (HDHomeRunChannel *aChannel in channelsArray)
  {
	// We need to be careful here since the MOC that 'self' is in may not be the same as the MOC
	// we're using - the data will lineup but pointers to objects in relationships will be different.
	// So use objectWithID: to retrieve the relevant channel object from the other MOC.
	HDHomeRunChannel *channelInMOC = (HDHomeRunChannel*) [inMOC objectWithID:[aChannel objectID]];
    [inMOC deleteObject:channelInMOC];
  }
}

@dynamic device;


- (HDHomeRun *)device 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"device"];
    tmpObject = [self primitiveDevice];
    [self didAccessValueForKey:@"device"];
    
    return tmpObject;
}

- (void)setDevice:(HDHomeRun *)value 
{
    [self willChangeValueForKey:@"device"];
	if (self.device)
	{
		[self.device removeObserver:self forKeyPath:@"name"];
		[self releaseHDHRDevice];
	}
    [self setPrimitiveDevice:value];
	if (value)
	{
		[self createHDHRDevice];
		[self.device addObserver:self forKeyPath:@"name" options:0 context:nil];
	}
    [self didChangeValueForKey:@"device"];
}


- (BOOL)validateDevice:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

#pragma mark - Actions

- (void) scanActionReportingProgressTo:(id)progressDisplay
{
  mCurrentProgressDisplay = progressDisplay;
    [NSThread detachNewThreadSelector:@selector(performScan:) toTarget:[HDHomeRunTunerChannelScanThread class] withObject:self];
}

- (void) startStreaming
{
  int ret = 0;

  @try
  {
    @synchronized(self)
    {
      ret = hdhomerun_device_stream_start(mHDHomeRunDevice);

    }
  }
  @catch (NSException *exception)
  {
    NSLog(@"startStreaming Exception name: name: %@ reason: %@", [exception name], [exception reason]);
  }
  @finally 
  {
    if (ret < 1)
    {
      NSLog(@"startStreaming - communication error sending request to hdhomerun device - stream start (error = %d)", ret);
      return;
    }
  }
}

- (void) startStreamingToPort:(int)portNumber
{
  int ret = 0;

  @try
  {
    @synchronized(self)
    {
		/* Set target. */
		char target[64];
		uint32_t local_ip = hdhomerun_device_get_local_machine_addr(mHDHomeRunDevice);
		sprintf(target, "%u.%u.%u.%u:%u",
			(unsigned int)(local_ip >> 24) & 0xFF, (unsigned int)(local_ip >> 16) & 0xFF,
			(unsigned int)(local_ip >> 8) & 0xFF, (unsigned int)(local_ip >> 0) & 0xFF,
			(unsigned int)portNumber);

		ret = hdhomerun_device_set_tuner_target(mHDHomeRunDevice, target);
    }
  }
  @catch (NSException *exception)
  {
    NSLog(@"startStreaming Exception name: name: %@ reason: %@", [exception name], [exception reason]);
  }
  @finally 
  {
    if (ret < 1)
    {
      NSLog(@"startStreaming - communication error sending request to hdhomerun device - stream start (error = %d)", ret);
      return;
    }
  }
}

- (void) stopStreaming
{
 @try
 {
	 @synchronized(self)
	 {
		hdhomerun_device_stream_stop(mHDHomeRunDevice);
	 }
 }
 @catch (NSException * e) {
	NSLog(@"stopStreaming exception name: %@ reason: %@", [e name], [e reason]);
 }
 @finally {
 }
}

// Note that this method allocates and initializes a new NSData object. It's the callers responsiblity to release
// the object when the caller has finished with it in order to avoid leaks.
- (NSData *) receiveVideoData
{
	size_t numBytesReceived;
	uint8* bytesReceived = NULL;
	bytesReceived = hdhomerun_device_stream_recv(mHDHomeRunDevice, VIDEO_DATA_BUFFER_SIZE_1S, &numBytesReceived);
	
	NSData *dataReceived = NULL;
	if (bytesReceived && (numBytesReceived > 0))
	{
		// Create a data object 
		dataReceived = [[NSData alloc] initWithBytesNoCopy:bytesReceived length:numBytesReceived freeWhenDone:NO];
	}
	return dataReceived;
}

- (void) setFilterForProgramNumber:(NSNumber*)inProgramNumber
{
  int ret = 0;

  if (inProgramNumber && (inProgramNumber != NSNoSelectionMarker))
  {
    @try 
    {
      @synchronized(self)
      {
        const char *programNumString = [[inProgramNumber stringValue] cStringUsingEncoding:NSASCIIStringEncoding];
        ret = hdhomerun_device_set_tuner_program(mHDHomeRunDevice, programNumString);
      }
    }
    @catch (NSException * e) 
    {
      NSLog(@"setFilterForProgramNumber: exception name: %@ reason: %@", [e name], [e reason]);
    }
    @finally 
    {
      if (ret < 1)
      {
              NSLog(@"setFilterForProgramNumber - communication error sending request to hdhomerun device - set tuner program (error = %d)\n", ret);
      }
    }
  }
}

- (void) tuneToChannel:(HDHomeRunChannel*)inChannel
{
  int ret = 0;

  if (inChannel)
  {
    @try 
    {
      @synchronized(self)
      {
        char value[64];
        sprintf(value, "%s:%d", [[inChannel tuningType]  cStringUsingEncoding:NSASCIIStringEncoding], [[inChannel channelNumber] intValue] );
        
        ret = hdhomerun_device_set_tuner_channel(mHDHomeRunDevice, value);
      }
    }
    @catch (NSException * e) 
    {
      NSLog(@"tuneTo: exception name: %@ reason: %@", [e name], [e reason]);
    }
    @finally 
    {
      if (ret < 1)
      {
            NSLog(@"tuneTo - communication error sending request to hdhomerun device (error = %d)\n", ret);
      }
    }
  }
}

- (void) exportChannelMapTo:(NSURL *)inURL
{
	// Start by adding all the channels on this tuner to an array
	NSMutableSet *channelsSet = [self mutableSetValueForKey:@"channels"];

	// Create an array to hold the dictionaries of channel info
	NSMutableArray *channelsOnTuner = [NSMutableArray arrayWithCapacity:[channelsSet count]];

	// Ask each HDHomeRunChannel in the set to add their info (in dictionary form) to the array
	[channelsSet makeObjectsPerformSelector:@selector(addChannelInfoDictionaryTo:) withObject:channelsOnTuner];
	
	NSSortDescriptor *channelDescriptor =[[[NSSortDescriptor alloc] initWithKey:@"channelNumber" ascending:YES] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObject:channelDescriptor];
	NSArray *sortedArray=[channelsOnTuner sortedArrayUsingDescriptors:sortDescriptors];
	
	NSData *xmlData;
	NSString *error;
	 
	xmlData = [NSPropertyListSerialization dataFromPropertyList:sortedArray
										   format:NSPropertyListXMLFormat_v1_0
										   errorDescription:&error];
	if(xmlData)
	{
		NSLog(@"No error creating XML data.");
		[xmlData writeToURL:inURL atomically:YES];
	}
	else
	{
		NSLog(error);
		[error release];
	}
}

- (void) importChannelMapFrom:(NSURL *)inURL
{
	NSData *xmlData = [NSData dataWithContentsOfURL:inURL];
	
	if (xmlData)
	{
		NSString *error;
		NSArray *channelsToImport = [NSPropertyListSerialization propertyListFromData:xmlData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error];
		if (channelsToImport)
		{
			[self deleteAllChannelsInMOC:[self managedObjectContext]];
			NSDictionary *channelInfoDictionary;
			for (channelInfoDictionary in channelsToImport)
			{
				HDHomeRunChannel *aChannel = [HDHomeRunChannel createChannelWithType:[channelInfoDictionary valueForKey:@"channelType"] andNumber:[channelInfoDictionary valueForKey:@"channelNumber"] inManagedObjectContext:[self managedObjectContext]];
				[aChannel setTuningType:[channelInfoDictionary valueForKey:@"tuningType"]];
				[aChannel importStationsFrom:[channelInfoDictionary valueForKey:@"stations"]];
				[self addChannelsObject:aChannel];
			}
		}
		else
		{
			NSLog(error);
			[error release];
		}
	}
}

- (void)addChannelsObject:(HDHomeRunChannel *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveChannels] addObject:value];
    [self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void) pushHDHomeRunStationsToServer
{ 
	if ([[NSApp delegate] recServer]) 
	{ 
		// Start by adding all the channels on this tuner to an array 
		NSMutableSet *channelsSet = [self mutableSetValueForKey:@"channels"]; 

		// Create an array to hold the dictionaries of channel info 
		NSMutableArray *channelsOnTuner = [NSMutableArray arrayWithCapacity:[channelsSet count]]; 

		// Ask each HDHomeRunChannel in the set to add their info (in dictionary form) to the array 
		[channelsSet makeObjectsPerformSelector:@selector(addChannelInfoDictionaryTo:) withObject:channelsOnTuner]; 

		NSSortDescriptor *channelDescriptor =[[[NSSortDescriptor alloc] initWithKey:@"channelNumber" ascending:YES] autorelease]; 
		NSArray *sortDescriptors=[NSArray arrayWithObject:channelDescriptor]; 
		NSArray *sortedArray=[channelsOnTuner sortedArrayUsingDescriptors:sortDescriptors]; 

		[[[NSApp delegate] recServer] setHDHomeRunChannelsAndStations:sortedArray onDeviceID:[self.device.deviceID intValue] forTunerIndex:[self.index intValue]]; 
	} 
}

- (void) copyChannelsAndStationsFrom:(HDHomeRunTuner*)sourceTuner
{
  if (sourceTuner == self)
  {
    return; // No point copying from self
  }
  
  // Remove all our channels first !
  NSArray *oldChannels = [[self channels] allObjects];
  for (HDHomeRunChannel *aChannel in oldChannels)
  {
          [[[NSApp delegate] managedObjectContext] deleteObject:aChannel];
  }
  [self removeChannels:self.channels];
  
  // The interate over the channels in the source tuner and add them and the associated stations.
  for (HDHomeRunChannel *aChannel in sourceTuner.channels)
  {
    HDHomeRunChannel *newChannel = [HDHomeRunChannel createChannelWithType:aChannel.channelType andNumber:aChannel.channelNumber inManagedObjectContext:[self managedObjectContext]];
    newChannel.tuningType = aChannel.tuningType;
    for (HDHomeRunStation *aStation in aChannel.stations)
    {
      HDHomeRunStation *newStation = [HDHomeRunStation createStationWithProgramNumber:aStation.programNumber forChannel:newChannel inManagedObjectContext:[self managedObjectContext]];
      newStation.callSign = aStation.callSign;
      newStation.z2itStation = aStation.z2itStation;
    }
    [self addChannelsObject:newChannel];
  }
}

#pragma mark - Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ((object == [self device]) && ([keyPath compare:@"name"] == NSOrderedSame))
  {
    [self willChangeValueForKey:@"longName"];
    [self didChangeValueForKey:@"longName"];
  }
}

/**
    Notification sent out when the threads own managedObjectContext has been.  This method
    ensures updates from the thread (which has its own managed object
    context) are merged into the application managed object content, so the 
    user always sees the most current information.
*/

- (void)threadContextDidSave:(NSNotification *)notification
{
    [[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateForSavedContext:) withObject:notification waitUntilDone:YES];
}

#pragma mark - Thread Functions

- (int) scanCallBackForType:(NSString *)type andData:(NSString *) data withMOC:(NSManagedObjectContext *)inMOC
{
  int continueScan = 1;
  
  NSLog(@"%@ %@", type, data);
  
  if ([type compare:@"SCANNING"] == NSOrderedSame)
  {
	mCurrentActivityToken = [mCurrentProgressDisplay setActivity:mCurrentActivityToken infoString:[NSString stringWithFormat:@"Scanning on Device %@ Tuner:%d %@", self.device.name, [self.index intValue]+1, data]];
	mCurrentActivityToken = [mCurrentProgressDisplay setActivity:mCurrentActivityToken incrementBy:1.0];
	
	if (mCurrentHDHomeRunChannel)
	{
	  // We have a current channel - does it have any stations ?
	  if ([[mCurrentHDHomeRunChannel stations] count] == 0)
	  {
		// No - so delete it
		[inMOC deleteObject:mCurrentHDHomeRunChannel];
		mCurrentHDHomeRunChannel = nil;
	  }
	}
	
	// Parse the channel type and number details from the data string
	NSString *channelTypeStr;
	NSNumber *channelNumber;
	
	// Channel scanning data has the form : 489000000 (us-cable:68, us-irc:68)  -OR- 485000000 (us-bcast:16)
	// We need to take the data after the opening bracket and use it to create the channel type and number
	NSRange openingBracket = [data rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"("]];
	NSString *typeNumberStr = [data substringFromIndex:openingBracket.location+1];
	NSRange colon = [typeNumberStr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
	channelTypeStr = [typeNumberStr substringToIndex:colon.location];
	NSString *channelNumberStr = [typeNumberStr substringFromIndex:colon.location+1];
	NSRange endOfNumber = [channelNumberStr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@",)"]];
	channelNumber = [NSNumber numberWithInt:[[channelNumberStr substringToIndex:endOfNumber.location] intValue]];
	
	// Create a HDHomeRunChannel to match
	HDHomeRunChannel *aChannel = [HDHomeRunChannel createChannelWithType:channelTypeStr andNumber:channelNumber inManagedObjectContext:inMOC];
	
	// Set the 'current' scanning channel to the one we just created - if there's no lock or programs on this channel we'll delete
	// it later.
	mCurrentHDHomeRunChannel = aChannel;
  }

  if ([type compare:@"LOCK"] == NSOrderedSame)
  {
	// We have some type of lock (perhaps none though).
	if ([data rangeOfString:@"none"].location != NSNotFound)
	{
	  // No Lock - delete and reset the current channel
	  [inMOC deleteObject:mCurrentHDHomeRunChannel];
	  mCurrentHDHomeRunChannel = nil;
	}
	else if ([data rangeOfString:@"(ntsc)"].location != NSNotFound)
	{
	  // Lock, but on an ntsc channel, nothing we can do here - delete and reset the current channel
	  [inMOC deleteObject:mCurrentHDHomeRunChannel];
	  mCurrentHDHomeRunChannel = nil;
	}
	else
	{
	  // Extract the tuningType (qam256, qam64, 8vsb etc.)
	  NSString *tuningTypeStr = [data substringToIndex:[data rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]].location];
	  
	  // Set the tuningType on the current Channel object
	  [mCurrentHDHomeRunChannel setTuningType:tuningTypeStr];
	  
	  // And add it to this tuners list of channels - however we can't just use 'self' here since that object
	  // may be in a different managed object context. Instead we'll use objectForID to find the matching Tuner in
	  // the inMoc context
	  HDHomeRunTuner *tunerInThreadMOC = (HDHomeRunTuner*) [inMOC objectWithID:[self objectID]];
	  [tunerInThreadMOC addChannelsObject:mCurrentHDHomeRunChannel];
	}
  }
  
  if ([type compare:@"PROGRAM"] == NSOrderedSame)
  {
	// We have a program - is it encrypted ?
	if (([data rangeOfString:@"(encrypted)"].location == NSNotFound)
		  && ([data rangeOfString:@"(no data)"].location == NSNotFound)
		  && ([data rangeOfString:@"internet"].location == NSNotFound)
		  && ([data rangeOfString:@"none"].location == NSNotFound))
	{
	  // The data line will look like :
	  //    30103: 2.2 WGBH-HD
	  // or
	  //    13668: 0.0
	  // if there's no encoded FCC Channel details or callsign. We need to break up the details add build an HDHomeRunStation object
	  NSRange colonRange = [data rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
	  NSString *programNumberString = [data substringToIndex:colonRange.location];
	  NSString *channelNumberAndCallsignString = [data substringFromIndex:colonRange.location+2];
	  NSString *channelNumberString;
	  NSString *callSignString = nil;
	  
	  NSRange spaceRange = [channelNumberAndCallsignString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
	  if (spaceRange.location != NSNotFound)
	  {
		channelNumberString = [channelNumberAndCallsignString substringToIndex:spaceRange.location];
		callSignString = [channelNumberAndCallsignString substringFromIndex:spaceRange.location+1];
	  }
	  else
	  {
		// No Callsign
		channelNumberString = channelNumberAndCallsignString;
	  }
	  
	  // SchedulesDirect listings use a number for minor part of the channel details, and a string for the major part
	  NSNumber *channelMinor;
	  NSString *channelMajor;
	  
	  NSRange sepRange = [channelNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
	  channelMajor = [channelNumberString substringToIndex:sepRange.location];
	  channelMinor = [NSNumber numberWithInt:[[channelNumberString substringFromIndex:sepRange.location+1] intValue]];

	  NSNumber *programNumber = [NSNumber numberWithInt:[programNumberString intValue]];
	  HDHomeRunStation *aStation = [HDHomeRunStation createStationWithProgramNumber:programNumber forChannel:mCurrentHDHomeRunChannel inManagedObjectContext:inMOC];

	  if (callSignString)
	  {
                if ([callSignString length] > kCallSignStringLength)
                  [aStation setCallSign:[callSignString substringToIndex:kCallSignStringLength+1]];
                else
                  [aStation setCallSign:callSignString];
		Z2ITLineup *lineupInThreadMOC =  (Z2ITLineup*)[inMOC objectWithID:[[self lineup] objectID]];
		Z2ITStation *aZ2ITStation = [Z2ITStation fetchStationWithCallSign:callSignString inLineup:lineupInThreadMOC inManagedObjectContext:inMOC];
		if (aZ2ITStation)
		  [aStation setZ2itStation:aZ2ITStation];
	  }
	}
  }
  
  BOOL shouldCancel = NO;
  mCurrentActivityToken = [mCurrentProgressDisplay shouldCancelActivity:mCurrentActivityToken cancel:&shouldCancel];
  if (shouldCancel)
  {
	NSLog(@"Abort Channel Scan");
	continueScan = 0;
        if (mCurrentHDHomeRunChannel && [[mCurrentHDHomeRunChannel stations] count] == 0)
        {
          // Destroy the current and channel and make sure it's not in the database
          [inMOC deleteObject:mCurrentHDHomeRunChannel];
        }
        mCurrentHDHomeRunChannel = nil;
  }
  return continueScan;
}

static int cmd_scan_callback(va_list ap, const char *type, const char *str)
{
	HDHomeRunTuner *theTuner = va_arg(ap, HDHomeRunTuner *);
        NSManagedObjectContext *theMOC = va_arg(ap, NSManagedObjectContext*);
        
        return [theTuner scanCallBackForType:[NSString stringWithCString:type] andData:[NSString stringWithCString:str] withMOC:theMOC];
}

// Typically called from a seperate thread to carry out the scanning
- (void) performScan
{
  int scanResult = 0;
    NSPersistentStoreCoordinator *psc = [[NSApp delegate] persistentStoreCoordinator];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: psc];
	
  HDHomeRunTuner *tunerInThreadMOC = (HDHomeRunTuner*) [managedObjectContext objectWithID:[self objectID]];

      // Delete any channels we might currently have - they're going to get replaced in the scan
      [tunerInThreadMOC deleteAllChannelsInMOC:managedObjectContext];
      
	mCurrentActivityToken = 0;
	if (mCurrentProgressDisplay)
	{
		mCurrentActivityToken = [mCurrentProgressDisplay createActivity];
		mCurrentActivityToken = [mCurrentProgressDisplay setActivity:mCurrentActivityToken progressMaxValue:390.0f];		// There are a maximum of 390 channels to scan per tuner !
	}
	
    mCurrentHDHomeRunChannel = nil;
    
  @try
  {
    @synchronized(self)  
    {
      NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);

      scanResult = channelscan_execute_all(mHDHomeRunDevice, HDHOMERUN_CHANNELSCAN_MODE_SCAN, cmd_scan_callback, self, managedObjectContext);
    }
  }
  @catch (NSException *anException)
  {
    NSLog(@"Exception during scan = %@, reason: %@", [anException name], [anException reason]); 
  }
  
  if (mCurrentActivityToken)
	[mCurrentProgressDisplay endActivity:mCurrentActivityToken];
  
  if (mCurrentHDHomeRunChannel && [[mCurrentHDHomeRunChannel stations] count] == 0)
  {
    // Destroy the current and channel and make sure it's not in the database
    [managedObjectContext deleteObject:mCurrentHDHomeRunChannel];
  }
  
  mCurrentHDHomeRunChannel = nil;
  
  if (scanResult > 0)
  {
    // when we save, we want to update the same object in the UI's MOC. 
    // So listen for the did save notification from the retrieval/parsing thread MOC
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadContextDidSave:) 
        name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    
    NSError *error = nil;
    if (![managedObjectContext save:&error])
    {
      NSLog(@"Channel scan - save returned an error %@", error);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
  }
  NSLog(@"HDHomeRunTuner - performScan complete - sending notification");
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:RSChannelScanCompleteNotification object:RSBackgroundApplication userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:scanResult], @"scanResult", nil] deliverImmediately:NO];
  
  mCurrentProgressDisplay = nil;
}

#pragma Initialization

- (void) createHDHRDevice
{
  uint32_t deviceID = [[[self device] deviceID] intValue];
  if ((deviceID != 0) && (mHDHomeRunDevice == nil))
  {
    mHDHomeRunDevice = hdhomerun_device_create(deviceID, 0, [[self index] intValue]);
  }
}

- (void) awakeFromFetch
{
  [super awakeFromFetch];
  [self createHDHRDevice];

  // Register to be told when the device name changes
  if ([self device])
    [[self device] addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) awakeFromInsert
{
  [super awakeFromInsert];
  [self createHDHRDevice];
}

#pragma Uninitialization

- (void) releaseHDHRDevice
{
  if (mHDHomeRunDevice)
    hdhomerun_device_destroy(mHDHomeRunDevice);
  mHDHomeRunDevice = nil;
}

- (void) willTurnIntoFault
{
  [self releaseHDHRDevice];
  if ([self device])
  {
	[[self device] removeObserver:self forKeyPath:@"name"];
  }
}

@end

@implementation HDHomeRunTunerChannelScanThread

+ (void) performScan:(HDHomeRunTuner*)aTuner
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [aTuner performScan];
  
  [pool release];
}

@end

@implementation HDHomeRunChannel

+ (HDHomeRunChannel*) createChannelWithType:(NSString*)inChannelType andNumber:(NSNumber*)inChannelNumber inManagedObjectContext:(NSManagedObjectContext*) inMOC
{
  HDHomeRunChannel *anHDHomeRunChannel = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunChannel" inManagedObjectContext:inMOC];
  [anHDHomeRunChannel setChannelType:inChannelType];
  [anHDHomeRunChannel setChannelNumber:inChannelNumber];
  return anHDHomeRunChannel;
}

- (void) addChannelInfoDictionaryTo:(NSMutableArray *)inOutputArray
{
	// Create an array and use it to hold serialized info for each station on this channel
	NSMutableArray *stationsOnChannelArray = [NSMutableArray arrayWithCapacity:[[self stations] count]];
	
	// Call each station in turn to add their details to the array
	[[self stations] makeObjectsPerformSelector:@selector(addStationInfoDictionaryTo:) withObject:stationsOnChannelArray];
	
	// Add the station array and other channel info to a dictionary and add that to the output array
	
	NSDictionary *infoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[self channelType], @"channelType", [self channelNumber], @"channelNumber", [self tuningType], @"tuningType", stationsOnChannelArray, @"stations", nil];
	[inOutputArray addObject:infoDictionary];
}

- (void) importStationsFrom:(NSArray*)inArrayOfStationDictionaries
{
	NSDictionary *stationInfo;
	for (stationInfo in inArrayOfStationDictionaries)
	{
		// Create a station and add it to the channel
		HDHomeRunStation *aStation = [HDHomeRunStation createStationWithProgramNumber:[stationInfo valueForKey:@"programNumber"] forChannel:self inManagedObjectContext:[self managedObjectContext]];
		if ([stationInfo valueForKey:@"callSign"])
			[aStation setCallSign:[stationInfo valueForKey:@"callSign"]];
		
		// If there's a SchedulesDirect station ID use that to find the matching SchedulesDirect station
		if ([stationInfo valueForKey:@"Z2ITStationID"])
		{
			Z2ITStation *aZ2ITStation = [Z2ITStation fetchStationWithID:[stationInfo valueForKey:@"Z2ITStationID"] inManagedObjectContext:[self managedObjectContext]];
			if (!aZ2ITStation)
			{
				// No Station ID match - perhaps the callsign ?
				aZ2ITStation = [Z2ITStation fetchStationWithCallSign:[stationInfo valueForKey:@"Z2ITCallSign"] inLineup:[[self tuner] lineup] inManagedObjectContext:[self managedObjectContext]];
			}
			if (aZ2ITStation)
			{
				[aStation setZ2itStation:aZ2ITStation];
			}
		}
	}
}

- (void) clearAllStations 
{ 
  NSMutableSet *stations = [self mutableSetValueForKey:@"stations"]; 
  while ([stations count] > 0) 
  { 
        HDHomeRunStation *aStation = [stations anyObject]; 
        [stations removeObject:aStation]; 
        [[self managedObjectContext] deleteObject:aStation]; 
  } 
}
	
@dynamic channelNumber;
@dynamic channelType;
@dynamic tuningType;
@dynamic stations;
@dynamic tuner;

@end

// coalesce these into one @interface HDHomeRunStation (CoreDataGeneratedPrimitiveAccessors) section
@interface HDHomeRunStation (CoreDataGeneratedPrimitiveAccessors)

- (HDHomeRunChannel*)primitiveChannel;
- (void)setPrimitiveChannel:(HDHomeRunChannel*)value;

@end

@implementation HDHomeRunStation

+ (HDHomeRunStation*) createStationWithProgramNumber:(NSNumber*)inProgramNumber forChannel:(HDHomeRunChannel*)inChannel inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  HDHomeRunStation *anHDHomeRunStation = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunStation" inManagedObjectContext:inMOC];
  [anHDHomeRunStation setProgramNumber:inProgramNumber];
  [inChannel addStationsObject:anHDHomeRunStation];
  return anHDHomeRunStation;
}

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"programNumber", nil]
      triggerChangeNotificationsForDependentKey:@"channelAndProgramNumber"];
}

- (void) awakeFromFetch
{
  [super awakeFromFetch];

  // Register to be told when the device name changes
  if ([self channel])
    [[self channel] addObserver:self forKeyPath:@"channelNumber" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) willTurnIntoFault
{
	if ([self channel])
		[[self channel] removeObserver:self forKeyPath:@"channelNumber"];
}
@dynamic channel;

- (HDHomeRunChannel *)channel 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"channel"];
    tmpObject = [self primitiveChannel];
    [self didAccessValueForKey:@"channel"];
    
    return tmpObject;
}

- (void)setChannel:(HDHomeRunChannel *)value 
{
	if (self.channel)
	{
		[self.channel removeObserver:self forKeyPath:@"channelNumber"];
	}
    [self willChangeValueForKey:@"channel"];
    [self setPrimitiveChannel:value];
    [self didChangeValueForKey:@"channel"];
	if (self.channel)
	{
		[self.channel addObserver:self forKeyPath:@"channelNumber" options:0 context:nil];
	}
}


- (BOOL)validateChannel:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ((object == [self channel]) && ([keyPath compare:@"channelNumber"] == NSOrderedSame))
  {
    [self willChangeValueForKey:@"channelAndProgramNumber"];
    [self didChangeValueForKey:@"channelAndProgramNumber"];
  }
}

- (void) startStreaming
{
	// Make sure we have a HDHR Device for the Tuner
  [[[self channel] tuner] createHDHRDevice];
  
	// Set our tuner to the channel
  [[[self channel] tuner] tuneToChannel:[self channel]];
  
  // Set our tuners filter for this program
  [[[self channel] tuner] setFilterForProgramNumber:[self programNumber]];
  
  // Set our tuner to start streaming
  [[[self channel] tuner] startStreaming];
}

- (void) startStreamingToPort:(int)portNumber
{
	// Make sure we have a HDHR Device for the Tuner
  [[[self channel] tuner] createHDHRDevice];
  
	// Set our tuner to the channel
  [[[self channel] tuner] tuneToChannel:[self channel]];
  
  // Set our tuners filter for this program
  [[[self channel] tuner] setFilterForProgramNumber:[self programNumber]];
  
  // Set our tuner to start streaming
  [[[self channel] tuner] startStreamingToPort:portNumber];
}

- (void) stopStreaming
{
	[[[self channel] tuner] stopStreaming];
}

- (NSData*) receiveVideoData
{
	return [[[self channel] tuner] receiveVideoData];
}

- (void) addStationInfoDictionaryTo:(NSMutableArray*)inOutputArray
{
	// Build a dictionary of info about this station (program number, scanned callsign and Z2ITStation mapped callsign - if any).
	NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
	[infoDictionary setValue:[self programNumber] forKey:@"programNumber"];
	if ([self callSign])
		[infoDictionary setValue:[self callSign] forKey:@"callSign"];
	if ([self z2itStation])
	{
		[infoDictionary setValue:[[self z2itStation] stationID] forKey:@"Z2ITStationID"];
		if ([[self z2itStation] callSign])
			[infoDictionary setValue:[[self z2itStation] callSign] forKey:@"Z2ITCallSign"];
	}
	
	// and add it to the output array
	[inOutputArray addObject:infoDictionary];
}

@dynamic callSign;
@dynamic programNumber;
@dynamic z2itStation;

- (NSString*) channelAndProgramNumber
{
  return [NSString stringWithFormat:@"%@:%@", [[self channel] channelNumber], [self programNumber]];
}

@end
