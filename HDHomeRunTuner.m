//
//  HDHomeRunTuner.m
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HDHomeRunTuner.h"
#import "HDHomeRunMO.h"
#import "CoreData_Macros.h"
#import "hdhomerun_channelscan.h"
#import "ChannelScanProgressDisplayProtocol.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"
#import "Z2ITStation.h"

@interface HDHomeRunTunerChannelScanThread : NSObject

+ (void) performScan:(HDHomeRunTuner*)aTuner;

@end;

@implementation HDHomeRunTuner

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"device",@"index", @"lineup", nil]
      triggerChangeNotificationsForDependentKey:@"longName"];
}

- (NSNumber *) index;
{
COREDATA_ACCESSOR(NSNumber*, @"index")
}

- (void) setIndex:(NSNumber*)value;
{
COREDATA_MUTATOR(NSNumber*, @"index")
}

- (HDHomeRun*) device
{
COREDATA_ACCESSOR(HDHomeRun*, @"device")
}

- (void) setDevice:(HDHomeRun *)value
{
  if ([self device])
    [[self device] removeObserver:self forKeyPath:@"name"];
    
COREDATA_MUTATOR(HDHomeRun*, @"device")

  // Register to be told when the device name changes
  [value addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
}

- (Z2ITLineup*)lineup
{
COREDATA_ACCESSOR(Z2ITLineup*, @"lineup");
}

- (void) setLineup:(Z2ITLineup*)value
{
COREDATA_MUTATOR(Z2ITLineup*, @"lineup");
}

- (void) addChannel:(HDHomeRunChannel*)aChannel
{
  NSMutableSet *channels = [self mutableSetValueForKey:@"channels"];
  [aChannel setTuner:self];
  [channels addObject:aChannel];
}

- (NSString*) longName
{
  NSString *name = [NSString stringWithFormat:@"%@:%d %@", [[self device] name], [[self index] intValue]+1, [[self lineup] name]];
  return name;
}

- (void) deleteAllChannelsInMOC:(NSManagedObjectContext *)inMOC
{
  NSMutableSet *channels = [self mutableSetValueForKey:@"channels"];
  while ([channels count] > 0)
  {
    HDHomeRunChannel *aChannel = [channels anyObject];
    [inMOC deleteObject:aChannel];
    [channels removeObject:aChannel];
  }
}

#pragma mark - Actions

- (void) scanActionReportingProgressTo:(id)progressDisplay
{
      // Delete any channels we might currently have - they're going to get replaced in the scan
      [self deleteAllChannelsInMOC:[self managedObjectContext]];
      
  mCurrentProgressDisplay = [progressDisplay retain];
    [NSThread detachNewThreadSelector:@selector(performScan:) toTarget:[HDHomeRunTunerChannelScanThread class] withObject:self];
}

- (void) startStreaming
{
  char value[64];
  int ret = 0;

  @try
  {
    @synchronized(self)
    {
      uint32_t local_ip = hdhomerun_device_get_local_machine_addr(mHDHomeRunDevice);

      sprintf(value, "%u.%u.%u.%u:%d",
              (unsigned int)(local_ip >> 24) & 0xFF, (unsigned int)(local_ip >> 16) & 0xFF,
              (unsigned int)(local_ip >> 8) & 0xFF, (unsigned int)(local_ip >> 0) & 0xFF,
              kDefaultPortNumber);

      ret = hdhomerun_device_set_tuner_target(mHDHomeRunDevice, value);
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
      NSLog(@"startStreaming - communication error sending request to hdhomerun device - set target\n");
      return;
    }
  }
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
              NSLog(@"setFilterForProgramNumber - communication error sending request to hdhomerun device - set tuner program\n");
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
            NSLog(@"tuneTo - communication error sending request to hdhomerun device\n");
      }
    }
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
    // get the context and the list of updated objects
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];

    NSMutableSet *allObjectsSet = [NSMutableSet setWithSet:updatedObjects];
    [allObjectsSet unionSet:[[notification userInfo] objectForKey:NSInsertedObjectsKey]];
    
    [[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(updateForSavedContext:) withObject:allObjectsSet waitUntilDone:NO];
}

#pragma mark - Thread Functions

- (int) scanCallBackForType:(NSString *)type andData:(NSString *) data withMOC:(NSManagedObjectContext *)inMOC
{
  int continueScan = 1;
  
  NSLog(@"%@ %@", type, data);
  
  if (mCurrentProgressDisplay && [mCurrentProgressDisplay conformsToProtocol:@protocol(ChannelScanProgressDisplay)])
  {
      if ([type compare:@"SCANNING"] == NSOrderedSame)
      {
        [mCurrentProgressDisplay incrementChannelScanProgress];
        
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
          
          // And add it to this tuners list of channels
          [self addChannel:mCurrentHDHomeRunChannel];
        }
      }
      
      if ([type compare:@"PROGRAM"] == NSOrderedSame)
      {
        // We have a program - is it encrypted ?
        if (([data rangeOfString:@"(encrypted)"].location == NSNotFound)
              && ([data rangeOfString:@"(no data)"].location == NSNotFound)
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
          
          // Zap2IT listings use a number for minor part of the channel details, and a string for the major part
          NSNumber *channelMinor;
          NSString *channelMajor;
          
          NSRange sepRange = [channelNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
          channelMajor = [channelNumberString substringToIndex:sepRange.location];
          channelMinor = [NSNumber numberWithInt:[[channelNumberString substringFromIndex:sepRange.location+1] intValue]];

          NSNumber *programNumber = [NSNumber numberWithInt:[programNumberString intValue]];
          HDHomeRunStation *aStation = [HDHomeRunStation createStationWithProgramNumber:programNumber forChannel:mCurrentHDHomeRunChannel inManagedObjectContext:inMOC];

          if (callSignString)
          {
            [aStation setCallSign:callSignString];
            Z2ITStation *aZ2ITStation = [Z2ITStation fetchStationWithCallSign:callSignString inLineup:[self lineup] inManagedObjectContext:inMOC];
            if (aZ2ITStation)
              [aStation setZ2ITStation:aZ2ITStation];
          }
        }
      }
      
      if ([mCurrentProgressDisplay abortChannelScan])
      {
        NSLog(@"Abort Channel Scan");
        continueScan = 0;
      }
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
    NSError *error = nil;

    NSPersistentStoreCoordinator *psc = [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: psc];

    mCurrentHDHomeRunChannel = nil;
    
    [psc lock];
    
  @try
  {
    @synchronized(self)  
    {
      NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);

      channelscan_execute_all(mHDHomeRunDevice, HDHOMERUN_CHANNELSCAN_MODE_SCAN, cmd_scan_callback, self, managedObjectContext);
    }
  }
  @catch (NSException *anException)
  {
    NSLog(@"Exception during scan = %@, reason: %@", [anException name], [anException reason]); 
  }
  [mCurrentProgressDisplay scanCompleted];
  
  if (mCurrentHDHomeRunChannel && [[mCurrentHDHomeRunChannel stations] count] == 0)
  {
    // Destroy the current and channel and make sure it's not in the database
    [managedObjectContext deleteObject:mCurrentHDHomeRunChannel];
  }
  
  mCurrentHDHomeRunChannel = nil;
  
  // when we save, we want to update the same object in the UI's MOC. 
  // So listen for the did save notification from the retrieval/parsing thread MOC
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadContextDidSave:) 
      name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
  
  if (![managedObjectContext save:&error])
  {
    NSLog(@"Channel scan - save returned an error %@", error);
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
  
  [psc unlock];
  
  [mCurrentProgressDisplay release];
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

- (void) didTurnIntoFault
{
  [self releaseHDHRDevice];
  
  [super didTurnIntoFault];
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

- (NSString*) channelType
{
  COREDATA_ACCESSOR(NSString*, @"channelType")
}

- (void) setChannelType:(NSString*)value
{
  COREDATA_MUTATOR(NSString*, @"channelType");
}

- (NSNumber*) channelNumber
{
  COREDATA_ACCESSOR(NSNumber*, @"channelNumber")
}

- (void) setChannelNumber:(NSNumber*)value
{
  COREDATA_MUTATOR(NSNumber*, @"channelNumber");
}

- (NSString*) tuningType;
{
  COREDATA_ACCESSOR(NSString*, @"tuningType")
}

- (void) setTuningType:(NSString*)value
{
  COREDATA_MUTATOR(NSString*, @"tuningType");
}

- (HDHomeRunTuner*)tuner
{
  COREDATA_ACCESSOR(HDHomeRunTuner*, @"tuner")
}

- (void)setTuner:(HDHomeRunTuner*)value
{
  COREDATA_MUTATOR(HDHomeRunTuner*, @"tuner");
}


- (NSMutableSet *)stations;
{
  NSMutableSet *stations = [self mutableSetValueForKey:@"stations"];
  return stations;
}

- (void) addStation:(HDHomeRunStation*)inStation
{
  NSMutableSet *stations = [self mutableSetValueForKey:@"stations"];
  [stations addObject:inStation];
  [inStation setChannel:self];
}

@end

@implementation HDHomeRunStation

+ (HDHomeRunStation*) createStationWithProgramNumber:(NSNumber*)inProgramNumber forChannel:(HDHomeRunChannel*)inChannel inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  HDHomeRunStation *anHDHomeRunStation = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunStation" inManagedObjectContext:inMOC];
  [anHDHomeRunStation setProgramNumber:inProgramNumber];
  [inChannel addStation:anHDHomeRunStation];
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
  // Set our tuner to the channel
  [[[self channel] tuner] tuneToChannel:[self channel]];
  
  // Set our tuners filter for this program
  [[[self channel] tuner] setFilterForProgramNumber:[self programNumber]];
  
  // Set our tuner to start streaming
  [[[self channel] tuner] startStreaming];
}

#pragma mark - CoreData Accessors and Mutators

- (NSNumber*) programNumber
{
COREDATA_ACCESSOR(NSNumber*, @"programNumber");
}

- (void) setProgramNumber:(NSNumber*)value
{
  COREDATA_MUTATOR(NSNumber*, @"programNumber");
}

- (NSString*) channelAndProgramNumber
{
  return [NSString stringWithFormat:@"%@:%@", [[self channel] channelNumber], [self programNumber]];
}

- (NSString*) callSign
{
COREDATA_ACCESSOR(NSString*, @"callSign");
}

- (void) setCallSign:(NSString*)value
{
  COREDATA_MUTATOR(NSString*, @"callSign");
}

- (HDHomeRunChannel*) channel
{
COREDATA_ACCESSOR(HDHomeRunChannel*, @"channel");
}

- (void) setChannel:(HDHomeRunChannel*) value
{
  if ([self channel])
    [[self channel] removeObserver:self forKeyPath:@"channe;"];
    
  COREDATA_MUTATOR(HDHomeRunChannel*, @"channel");

  // Register to be told when the device name changes
  [value addObserver:self forKeyPath:@"channel" options:NSKeyValueObservingOptionNew context:nil];
}

- (Z2ITStation*) Z2ITStation
{
COREDATA_ACCESSOR(Z2ITStation*, @"z2itStation");
}

- (void) setZ2ITStation:(Z2ITStation*) value
{
  COREDATA_MUTATOR(Z2ITLineupMap*, @"z2itStation");
}

@end