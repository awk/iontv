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
#import "HDHomeRunChannelStationMap.h"
#import "hdhomerun.h"
#import "RSActivityDisplayProtocol.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"
#import "Z2ITStation.h"
#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSNotifications.h"

#define USE_MOCK_CHANNEL_SCAN 0
#if USE_MOCK_CHANNEL_SCAN
#import "mock_channel_scan.h"
#endif // USE_MOCK_CHANNEL_SCAN

const int kCallSignStringLength = 10;

@interface ScanOperation : NSOperation
{
  NSManagedObjectID *mTunerObjectID;
  HDHomeRunTuner *mTuner;
  NSManagedObjectContext *mManagedObjectContext;
  NSObject<RSActivityDisplay> *mCurrentProgressDisplay;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) HDHomeRunTuner *tuner;

- (id) initWithTunerObjectID:(NSManagedObjectID *)aTunerObjectID
            progressReporter:(NSObject<RSActivityDisplay> *)progressReporter;

@end

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
- (struct hdhomerun_device_t *) getHDHRDevice;
@end

@implementation HDHomeRunTuner

@synthesize mOperationQueue;

+ (void)initialize {
}

+ (NSSet *)keyPathsForValuesAffectingLongName:(NSString *)key {
  return [NSSet setWithObjects:@"device",@"index", @"lineup", nil];
}


+ (NSArray *) allTunersInManagedObjectContext:(NSManagedObjectContext *)inMOC {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

@dynamic index;
@dynamic device;
@dynamic longName;
@dynamic recordings;
@dynamic lineup;

- (NSString *)longName {
  NSString *name = [NSString stringWithFormat:@"%@:%d %@", self.device.name, [[self index] intValue]+1, self.lineup.name];
  return name;
}

- (HDHomeRun *)device {
    id tmpObject;

    [self willAccessValueForKey:@"device"];
    tmpObject = [self primitiveDevice];
    [self didAccessValueForKey:@"device"];

    return tmpObject;
}

- (void)setDevice:(HDHomeRun *)value {
    [self willChangeValueForKey:@"device"];
  if (self.device) {
    [self.device removeObserver:self forKeyPath:@"name"];
    [self releaseHDHRDevice];
  }
  [self setPrimitiveDevice:value];
  if (value) {
    [self createHDHRDevice];
    [self.device addObserver:self forKeyPath:@"name" options:0 context:nil];
  }
  [self didChangeValueForKey:@"device"];
}


- (BOOL)validateDevice:(id *)valueRef error:(NSError **)outError {
    // Insert custom validation logic here.
    return YES;
}

#pragma mark - Actions

- (void)scanActionReportingProgressTo:(id)progressDisplay {
  NSOperation *scanOperation = [[ScanOperation alloc] initWithTunerObjectID:[self objectID]
                                                           progressReporter:progressDisplay];
  [mOperationQueue addOperation:scanOperation];
  [scanOperation release];
}

- (void)startStreaming {
  int ret = 0;

  @try {
    @synchronized(self) {
      ret = hdhomerun_device_stream_start(mHDHomeRunDevice);
    }
  }
  @catch (NSException *exception) {
    NSLog(@"startStreaming Exception name: name: %@ reason: %@", [exception name], [exception reason]);
  }
  @finally {
    if (ret < 1) {
      NSLog(@"startStreaming - communication error sending request to hdhomerun device - stream start (error = %d)", ret);
      return;
    }
  }
}

- (void)startStreamingToPort:(int)portNumber {
  int ret = 0;

  @try {
    @synchronized(self) {
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
  @catch (NSException *exception) {
    NSLog(@"startStreaming Exception name: name: %@ reason: %@", [exception name], [exception reason]);
  }
  @finally {
    if (ret < 1) {
      NSLog(@"startStreaming - communication error sending request to hdhomerun device - stream start (error = %d)", ret);
      return;
    }
  }
}

- (void)stopStreaming {
  @try {
    @synchronized(self) {
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
- (NSData *)copyVideoData {
  size_t numBytesReceived;
  uint8* bytesReceived = NULL;
  bytesReceived = hdhomerun_device_stream_recv(mHDHomeRunDevice, VIDEO_DATA_BUFFER_SIZE_1S, &numBytesReceived);

  NSData *dataReceived = NULL;
  if (bytesReceived && (numBytesReceived > 0)) {
    // Create a data object
    dataReceived = [[NSData alloc] initWithBytesNoCopy:bytesReceived length:numBytesReceived freeWhenDone:NO];
  }
  return dataReceived;
}

- (void)setFilterForProgramNumber:(NSNumber *)inProgramNumber {
  int ret = 0;

  if (inProgramNumber && (inProgramNumber != NSNoSelectionMarker)) {
    @try {
      @synchronized(self) {
        const char *programNumString = [[inProgramNumber stringValue] cStringUsingEncoding:NSASCIIStringEncoding];
        ret = hdhomerun_device_set_tuner_program(mHDHomeRunDevice, programNumString);
      }
    }
    @catch (NSException * e) {
      NSLog(@"setFilterForProgramNumber: exception name: %@ reason: %@", [e name], [e reason]);
    }
    @finally {
      if (ret < 1) {
        NSLog(@"setFilterForProgramNumber - communication error sending request to hdhomerun device - set tuner program (error = %d)\n", ret);
      }
    }
  }
}

- (void)tuneToChannel:(HDHomeRunChannel *)inChannel {
  int ret = 0;

  if (inChannel) {
    @try {
      @synchronized(self) {
        char value[64];
        sprintf(value, "%s:%d", [[inChannel tuningType]  cStringUsingEncoding:NSASCIIStringEncoding], [[inChannel channelNumber] intValue] );

        ret = hdhomerun_device_set_tuner_channel(mHDHomeRunDevice, value);
      }
    }
    @catch (NSException * e) {
      NSLog(@"tuneTo: exception name: %@ reason: %@", [e name], [e reason]);
    }
    @finally {
      if (ret < 1) {
        NSLog(@"tuneTo - communication error sending request to hdhomerun device (error = %d)\n", ret);
      }
    }
  }
}

- (void)exportChannelMapTo:(NSURL *)inURL {
  NSData *xmlData = [self.lineup.channelStationMap createChannelMapExportXMLDataWithDeviceID:[self.device.deviceID intValue]];
  NSString *error = NULL;
  
  if(xmlData) {
    NSLog(@"No error creating XML data.");
    [xmlData writeToURL:inURL atomically:YES];
  } else {
    NSLog(@"Error creating XML Data %@", error);
    [error release];
  }
}

#if 0
- (void)importChannelMapFrom:(NSURL *)inURL {
  NSData *xmlData = [NSData dataWithContentsOfURL:inURL];

  if (xmlData) {
    NSString *error;
    NSArray *channelsToImport = [NSPropertyListSerialization propertyListFromData:xmlData mutabilityOption:NSPropertyListImmutable format:nil errorDescription:&error];
    if (channelsToImport) {
      [self.channelStationMap deleteAllChannelsInMOC:[self managedObjectContext]];
      NSDictionary *channelInfoDictionary;
      for (channelInfoDictionary in channelsToImport) {
        HDHomeRunChannel *aChannel = [HDHomeRunChannel createChannelWithType:[channelInfoDictionary valueForKey:@"channelType"] andNumber:[channelInfoDictionary valueForKey:@"channelNumber"] inManagedObjectContext:[self managedObjectContext]];
        [aChannel setTuningType:[channelInfoDictionary valueForKey:@"tuningType"]];
        [aChannel setFrequency:[channelInfoDictionary valueForKey:@"frequency"]];
        [aChannel setTransportStreamID:[channelInfoDictionary valueForKey:@"transportStreamID"]];
        [aChannel importStationsFrom:[channelInfoDictionary valueForKey:@"stations"]];
        [self addChannelsObject:aChannel];
      }
    } else {
      NSLog(error);
      [error release];
    }
  }
}

- (void)copyChannelsAndStationsFrom:(HDHomeRunTuner *)sourceTuner {
  if (sourceTuner == self) {
    return; // No point copying from self
  }

  // Remove all our channels first !
  NSArray *oldChannels = [[self channels] allObjects];
  for (HDHomeRunChannel *aChannel in oldChannels) {
    [[[NSApp delegate] managedObjectContext] deleteObject:aChannel];
  }
  [self removeChannels:self.channels];

  // The interate over the channels in the source tuner and add them and the associated stations.
  for (HDHomeRunChannel *aChannel in sourceTuner.channels) {
    HDHomeRunChannel *newChannel = [HDHomeRunChannel createChannelWithType:aChannel.channelType andNumber:aChannel.channelNumber inManagedObjectContext:[self managedObjectContext]];
    newChannel.tuningType = aChannel.tuningType;
    for (HDHomeRunStation *aStation in aChannel.stations) {
      HDHomeRunStation *newStation = [HDHomeRunStation createStationWithProgramNumber:aStation.programNumber forChannel:newChannel inManagedObjectContext:[self managedObjectContext]];
      newStation.callSign = aStation.callSign;
      newStation.z2itStation = aStation.z2itStation;
    }
    [self addChannelsObject:newChannel];
  }
}
#endif

- (struct hdhomerun_device_t *) getHDHRDevice {
  return mHDHomeRunDevice;
}

#pragma mark - Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ((object == [self device]) && ([keyPath compare:@"name"] == NSOrderedSame)) {
    [self willChangeValueForKey:@"longName"];
    [self didChangeValueForKey:@"longName"];
  }
}

#pragma Initialization

- (void)createHDHRDevice {
  uint32_t deviceID = [[[self device] deviceID] intValue];
  if ((deviceID != 0) && (mHDHomeRunDevice == nil))   {
    mHDHomeRunDevice = hdhomerun_device_create(deviceID, 0, [[self index] intValue], NULL);
  }
  mOperationQueue = [[NSOperationQueue alloc] init];
  [mOperationQueue setMaxConcurrentOperationCount:1];
}

- (void)awakeFromFetch {
  [super awakeFromFetch];
  [self createHDHRDevice];

  // Register to be told when the device name changes
  if ([self device]) {
    [[self device] addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
  }
}

- (void)awakeFromInsert {
  [super awakeFromInsert];
  [self createHDHRDevice];
}

#pragma Uninitialization

- (void)releaseHDHRDevice {
  if (mHDHomeRunDevice) {
    hdhomerun_device_destroy(mHDHomeRunDevice);
  }
  mHDHomeRunDevice = nil;

  [mOperationQueue release];
  mOperationQueue = nil;
}

- (void)willTurnIntoFault {
  [self releaseHDHRDevice];
  if ([self device]) {
    [[self device] removeObserver:self forKeyPath:@"name"];
  }
}

@end

@implementation ScanOperation

@synthesize managedObjectContext = mManagedObjectContext, tuner = mTuner;

- (id) initWithTunerObjectID:(NSManagedObjectID *)aTunerObjectID
            progressReporter:(NSObject<RSActivityDisplay> *)progressReporter {
  if (self = [super init]) {
    mTunerObjectID = [aTunerObjectID retain];
    mCurrentProgressDisplay = [progressReporter retain];
  }
  return self;
}

- (void) dealloc {
  [mTunerObjectID release];
  [mCurrentProgressDisplay release];
  [super dealloc];
}

- (HDHomeRunChannel *) newChannelFromScanResult:(struct hdhomerun_channelscan_result_t *)scanResult {
  // Parse the channel type and number details from the data string
  NSNumber *channelNumber = nil;
  NSNumber *frequencyNumber = nil;
  NSString *channelType = nil;
  // Although the scanResult includes the frequency as an integer the channel type and number are supplied as ASCII
  // so we must parse the string : us-irc:68, us-cable:68  -OR- us-bcast:16 -OR- us-hrc:23
  // We need to take the data after the opening bracket and use it to create the channel type and number
  int numChannelsFound = 0;
  int channelNum1, channelNum2;
  numChannelsFound = sscanf(scanResult->channel_str, "us-bcast:%d", &channelNum1);
  if (1 == numChannelsFound) {
    channelNumber = [NSNumber numberWithInt:channelNum1];
    channelType = [NSString stringWithString:@"us-bcast"];
  }
  numChannelsFound = sscanf(scanResult->channel_str, "us-hrc:%d", &channelNum1);
  if (1 == numChannelsFound) {
    channelNumber = [NSNumber numberWithInt:channelNum1];
    channelType = [NSString stringWithString:@"us-hrc"];
  }
  numChannelsFound = sscanf(scanResult->channel_str, "us-irc:%d, us-cable:%d", &channelNum1, &channelNum2);
  if (numChannelsFound == 2) {
    // It doesn't actually matter which number we pick - they'll both be the same
    channelNumber = [NSNumber numberWithInt:channelNum1];
    channelType = [NSString stringWithString:@"us-cable"];
  }
  frequencyNumber = [NSNumber numberWithInt:scanResult->frequency];
  
  // Create a HDHomeRunChannel to match
  HDHomeRunChannel *aChannel = [HDHomeRunChannel createChannelWithType:channelType andNumber:channelNumber inManagedObjectContext:self.managedObjectContext];
  [aChannel setFrequency:frequencyNumber];
  
  return [aChannel retain];
}

- (void) addHDHRStationFromProgramResults:(struct hdhomerun_channelscan_program_t *)program toHDHRChannel:(HDHomeRunChannel *)hdhrChannel {
  NSString *programString = [NSString stringWithUTF8String:program->program_str];
  
  // We have a program - is it encrypted ?
  // The data line will look like :
  //    30103: 2.2 WGBH-HD
  // or
  //    13668: 0.0
  // if there's no encoded FCC Channel details or callsign. We need to break up the details add build an HDHomeRunStation object
  if (([programString rangeOfString:@"(encrypted)"].location == NSNotFound)
      && ([programString rangeOfString:@"(no data)"].location == NSNotFound)
      && ([programString rangeOfString:@"internet"].location == NSNotFound)
      && ([programString rangeOfString:@"none"].location == NSNotFound)) {
    
    HDHomeRunStation *aStation = [HDHomeRunStation createStationWithProgramNumber:[NSNumber numberWithInt:program->program_number] forChannel:hdhrChannel inManagedObjectContext:self.managedObjectContext];
    
    if (program->name && (program->name[0] != '\0')) {
      [aStation setCallSign:[NSString stringWithUTF8String:program->name]];
      Z2ITLineup *lineupInThreadMOC =  (Z2ITLineup*)[self.managedObjectContext objectWithID:[self.tuner.lineup objectID]];
      Z2ITStation *aZ2ITStation = [Z2ITStation fetchStationWithCallSign:[NSString stringWithUTF8String:program->name] inLineup:lineupInThreadMOC inManagedObjectContext:self.managedObjectContext];
      if (aZ2ITStation) {
        [aStation setZ2itStation:aZ2ITStation];
      }
    }
  }
}

- (void) performScan {
  size_t activityToken;
  
  // Delete the old channel station map
  if (self.tuner.lineup.channelStationMap != nil) {
    [self.managedObjectContext deleteObject:self.tuner.lineup.channelStationMap];
  }
  
  // Create a new empty channel station map
  HDHomeRunChannelStationMap *anHDHomeRunChannelStationMap = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunChannelStationMap" inManagedObjectContext:self.managedObjectContext];
  [anHDHomeRunChannelStationMap setLineup:self.tuner.lineup];
  [anHDHomeRunChannelStationMap setLastUpdateDate:[NSDate date]];
  
  activityToken = 0;
  if (mCurrentProgressDisplay) {
    activityToken = [mCurrentProgressDisplay createActivity];
    activityToken = [mCurrentProgressDisplay setActivity:activityToken progressMaxValue:390.0f];    // There are a maximum of 390 channels to scan per tuner !
  }
  
#if USE_MOCK_CHANNEL_SCAN
  @try {
    @synchronized(self) {
      NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);
      
      scanResult = mock_channelscan_execute_all([self.tuner getHDHRDevice], 0, cmd_scan_callback, self, self.managedObjectContext);
    }
  }
  @catch (NSException *anException) {
    NSLog(@"Exception during scan = %@, reason: %@", [anException name], [anException reason]);
  }
#else
  char *channelMap;
  if (hdhomerun_device_get_tuner_channelmap([self.tuner getHDHRDevice], &channelMap) < 0) {
		NSLog(@"performScan failed to query channelmap from device\n");
    return;
  }
  
	const char *channelmap_scan_group = hdhomerun_channelmap_get_channelmap_scan_group(channelMap);
	if (!channelmap_scan_group) {
		NSLog(@"performScan unknown channelmap '%s'\n", channelMap);
		return;
	}
  
	if (hdhomerun_device_channelscan_init([self.tuner getHDHRDevice], channelmap_scan_group) <= 0) {
		NSLog(@"performScan failed to initialize channel scan\n");
		return;
	}
  
  int continueScan = 1;
  int ret;
	while (continueScan) {
    HDHomeRunChannel *currentHDHomeRunChannel = nil;
		struct hdhomerun_channelscan_result_t result;
		ret = hdhomerun_device_channelscan_advance([self.tuner getHDHRDevice], &result);
		if (ret <= 0) {
			break;
		}
    
		NSLog(@"  SCANNING: %lu (%s)\n", (unsigned long)result.frequency, result.channel_str);
    
    activityToken = [mCurrentProgressDisplay setActivity:activityToken infoString:[NSString stringWithFormat:@"Scanning on Device %@ Tuner:%d %s", self.tuner.device.name, [self.tuner.index intValue]+1, result.channel_str]];
    activityToken = [mCurrentProgressDisplay setActivity:activityToken incrementBy:1.0];
    
    currentHDHomeRunChannel = [self newChannelFromScanResult:&result];
    
		ret = hdhomerun_device_channelscan_detect([self.tuner getHDHRDevice], &result);
		if (ret <= 0) {
      [currentHDHomeRunChannel release];
			break;
		}
    
		NSLog(@"  LOCK: %s (ss=%u snq=%u seq=%u)\n",
          result.status.lock_str, result.status.signal_strength,
          result.status.signal_to_noise_quality, result.status.symbol_error_quality);
    
    [currentHDHomeRunChannel setTuningType:[NSString stringWithUTF8String:result.status.lock_str]];
    
		if (result.transport_stream_id_detected) {
			NSLog(@"  TSID: 0x%04X\n", result.transport_stream_id);
      [currentHDHomeRunChannel setTransportStreamID:[NSNumber numberWithInt:result.transport_stream_id]];
		}
    
		int i;
		for (i = 0; i < result.program_count; i++) {
			struct hdhomerun_channelscan_program_t *program = &result.programs[i];
			NSLog(@"  PROGRAM %s\n", program->program_str);
      [self addHDHRStationFromProgramResults:program toHDHRChannel:currentHDHomeRunChannel];
		}
    if ([[currentHDHomeRunChannel stations] count] > 0) {
      [self.tuner.lineup.channelStationMap addChannelsObject:currentHDHomeRunChannel]; 
    } else {
      // No stations we can use on this channel - delete it.
      [self.managedObjectContext deleteObject:currentHDHomeRunChannel];
    }
    
    BOOL shouldCancel = NO;
    activityToken = [mCurrentProgressDisplay shouldCancelActivity:activityToken cancel:&shouldCancel];
    if (shouldCancel) {
      NSLog(@"Abort Channel Scan");
      continueScan = 0;
    }
    [currentHDHomeRunChannel release];
  }
#endif
  
  if (activityToken) {
    [mCurrentProgressDisplay endActivity:activityToken];
  }
  
  if (0 == continueScan) {
    // Scan was aborted, don't do anything more - just return.
    return;
  }
  
  // Post the scan results to the SiliconDust lineup Server, retrieve the results
  // and update our ChannelStationMap.
  [self.tuner.lineup.channelStationMap updateMapUsingSDLineupServerWithDeviceID:[self.tuner.device.deviceID intValue]];
  
  // when we save, we want to update the same object in the UI's MOC.
  // So listen for the did save notification from the retrieval/parsing thread MOC
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(threadContextDidSave:)
                                               name:NSManagedObjectContextDidSaveNotification
                                             object:self.managedObjectContext];
  
  NSError *error = nil;
  
  // This save should overwrite whats in the store
  [self.managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
  if (![self.managedObjectContext save:&error]) {
    NSLog(@"Channel scan - save returned an error %@", error);
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.managedObjectContext];
  
  NSLog(@"HDHomeRunTuner - performScan complete - sending notification");
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:RSChannelScanCompleteNotification object:RSBackgroundApplication userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"scanResult", nil] deliverImmediately:NO];
  
  mCurrentProgressDisplay = nil;
}

/**
 Notification sent out when the threads own managedObjectContext has been.  This method
 ensures updates from the thread (which has its own managed object
 context) are merged into the application managed object content, so the
 user always sees the most current information.
 */

- (void)threadContextDidSave:(NSNotification *)notification {
  RSCommonAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
  [appDelegate performSelectorOnMainThread:@selector(updateForSavedContext:) withObject:notification waitUntilDone:YES];
}

- (void) main {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSPersistentStoreCoordinator *psc = [[NSApp delegate] persistentStoreCoordinator];
  self.managedObjectContext = [[NSManagedObjectContext alloc] init];
  [self.managedObjectContext setPersistentStoreCoordinator:psc];
  self.tuner = (HDHomeRunTuner *) [self.managedObjectContext objectWithID:mTunerObjectID];
  
  [self performScan];
  [pool release];
}

@end

@implementation HDHomeRunChannel

+ (HDHomeRunChannel *)createChannelWithType:(NSString *)inChannelType andNumber:(NSNumber *)inChannelNumber inManagedObjectContext:(NSManagedObjectContext *) inMOC {
  HDHomeRunChannel *anHDHomeRunChannel = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunChannel" inManagedObjectContext:inMOC];
  [anHDHomeRunChannel setChannelType:inChannelType];
  [anHDHomeRunChannel setChannelNumber:inChannelNumber];
  return anHDHomeRunChannel;
}

- (void)addChannelInfoTo:(NSXMLElement *)parentElement {
  // Call each station in turn to add their details to the array
  [[self stations] makeObjectsPerformSelector:@selector(addStationInfoTo:) withObject:parentElement];
}

- (void)addChannelInfoDictionaryTo:(NSMutableArray *)inOutputArray {
  // Create an array and use it to hold serialized info for each station on this channel
  NSMutableArray *stationsOnChannelArray = [NSMutableArray arrayWithCapacity:[[self stations] count]];

  // Call each station in turn to add their details to the array
  [[self stations] makeObjectsPerformSelector:@selector(addStationInfoDictionaryTo:) withObject:stationsOnChannelArray];

  // Add the station array and other channel info to a dictionary and add that to the output array
  NSDictionary *infoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[self channelType], @"channelType",
                                    [self channelNumber], @"channelNumber",
                                    [self tuningType], @"tuningType",
                                    [self frequency], @"frequency",
                                    [self transportStreamID], @"transportStreamID",
                                    stationsOnChannelArray, @"stations",
                                    nil];
  [inOutputArray addObject:infoDictionary];
}

- (void)importStationsFrom:(NSArray *)inArrayOfStationDictionaries {
  NSDictionary *stationInfo;
  for (stationInfo in inArrayOfStationDictionaries) {
    // Create a station and add it to the channel
    HDHomeRunStation *aStation = [HDHomeRunStation createStationWithProgramNumber:[stationInfo valueForKey:@"programNumber"] forChannel:self inManagedObjectContext:[self managedObjectContext]];
    if ([stationInfo valueForKey:@"callSign"]) {
      [aStation setCallSign:[stationInfo valueForKey:@"callSign"]];
    }
    // If there's a SchedulesDirect station ID use that to find the matching SchedulesDirect station
    if ([stationInfo valueForKey:@"Z2ITStationID"]) {
      Z2ITStation *aZ2ITStation = [Z2ITStation fetchStationWithID:[stationInfo valueForKey:@"Z2ITStationID"] inManagedObjectContext:[self managedObjectContext]];
      if (!aZ2ITStation) {
        // No Station ID match - perhaps the callsign ?
        aZ2ITStation = [Z2ITStation fetchStationWithCallSign:[stationInfo valueForKey:@"Z2ITCallSign"] inLineup:self.channelStationMap.lineup inManagedObjectContext:[self managedObjectContext]];
      }
      if (aZ2ITStation) {
        [aStation setZ2itStation:aZ2ITStation];
      }
    }
  }
}

- (void)clearAllStations {
  NSMutableSet *stations = [self mutableSetValueForKey:@"stations"];
  while ([stations count] > 0) {
    HDHomeRunStation *aStation = [stations anyObject];
    [stations removeObject:aStation];
    [[self managedObjectContext] deleteObject:aStation];
  }
}

@dynamic channelNumber;
@dynamic channelType;
@dynamic tuningType;
@dynamic stations;
@dynamic channelStationMap;
@dynamic transportStreamID;
@dynamic frequency;
@end

// coalesce these into one @interface HDHomeRunStation (CoreDataGeneratedPrimitiveAccessors) section
@interface HDHomeRunStation (CoreDataGeneratedPrimitiveAccessors)

- (HDHomeRunChannel *)primitiveChannel;
- (void)setPrimitiveChannel:(HDHomeRunChannel *)value;

@end

@implementation HDHomeRunStation

+ (HDHomeRunStation *)createStationWithProgramNumber:(NSNumber *)inProgramNumber forChannel:(HDHomeRunChannel *)inChannel inManagedObjectContext:(NSManagedObjectContext *)inMOC {
  HDHomeRunStation *anHDHomeRunStation = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunStation" inManagedObjectContext:inMOC];
  [anHDHomeRunStation setProgramNumber:inProgramNumber];
  [inChannel addStationsObject:anHDHomeRunStation];
  return anHDHomeRunStation;
}

+ (void)initialize {
}

+ (NSSet *)keyPathsForValuesAffectingChannelAndProgramNumber {
  return [NSSet setWithObject:@"programNumber"];
}

- (void)awakeFromFetch {
  [super awakeFromFetch];

  // Register to be told when the device name changes
  if ([self channel]) {
    [[self channel] addObserver:self forKeyPath:@"channelNumber" options:NSKeyValueObservingOptionNew context:nil];
  }
}

- (void)willTurnIntoFault {
  if ([self channel]) {
    [[self channel] removeObserver:self forKeyPath:@"channelNumber"];
  }
}

@dynamic channel;

- (HDHomeRunChannel *)channel {
  id tmpObject;

  [self willAccessValueForKey:@"channel"];
  tmpObject = [self primitiveChannel];
  [self didAccessValueForKey:@"channel"];

  return tmpObject;
}

- (void)setChannel:(HDHomeRunChannel *)value {
  if (self.channel) {
    [self.channel removeObserver:self forKeyPath:@"channelNumber"];
  }
  [self willChangeValueForKey:@"channel"];
  [self setPrimitiveChannel:value];
  [self didChangeValueForKey:@"channel"];
  if (self.channel) {
    [self.channel addObserver:self forKeyPath:@"channelNumber" options:0 context:nil];
  }
}


- (BOOL)validateChannel:(id *)valueRef error:(NSError **)outError {
    // Insert custom validation logic here.
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ((object == [self channel]) && ([keyPath compare:@"channelNumber"] == NSOrderedSame)) {
    [self willChangeValueForKey:@"channelAndProgramNumber"];
    [self didChangeValueForKey:@"channelAndProgramNumber"];
  }
}

- (void)startStreaming {
  if (mCurrentStreamingTuner) {
    NSLog(@"startStreaming - already streaming !");
    [self stopStreaming];
  }

  mCurrentStreamingTuner = [self.channel.channelStationMap.lineup.tuners anyObject];

  // Make sure we have a HDHR Device for the Tuner
  [mCurrentStreamingTuner createHDHRDevice];

  // Set our tuner to the channel
  [mCurrentStreamingTuner tuneToChannel:[self channel]];

  // Set our tuners filter for this program
  [mCurrentStreamingTuner setFilterForProgramNumber:[self programNumber]];

  // Set our tuner to start streaming
  [mCurrentStreamingTuner startStreaming];
}

- (void)startStreamingToPort:(int)portNumber {
  if (mCurrentStreamingTuner) {
    NSLog(@"startStreamingToPort - already streaming !");
    [self stopStreaming];
  }

  mCurrentStreamingTuner = [self.channel.channelStationMap.lineup.tuners anyObject];
  // Make sure we have a HDHR Device for the Tuner
  [mCurrentStreamingTuner  createHDHRDevice];

  // Set our tuner to the channel
  [mCurrentStreamingTuner  tuneToChannel:[self channel]];

  // Set our tuners filter for this program
  [mCurrentStreamingTuner  setFilterForProgramNumber:[self programNumber]];

  // Set our tuner to start streaming
  [mCurrentStreamingTuner  startStreamingToPort:portNumber];
}

- (void)stopStreaming {
  [mCurrentStreamingTuner stopStreaming];
  [mCurrentStreamingTuner release];
  mCurrentStreamingTuner = nil;
}

- (NSData *)copyVideoData {
  return [mCurrentStreamingTuner copyVideoData];
}

- (void)addStationInfoTo:(NSXMLElement *)parentElement {
  NSXMLElement *programElement = [[NSXMLElement alloc] initWithName:@"Program"];
  
  // Build an XMLElement that looks like :
  // <Program>
  // <Modulation>qam256</Modulation>
  // <Frequency>519000000</Frequency>
  // <TransportStreamID>0x743</TransportStreamID>
  // <ProgramNumber>11801</ProgramNumber>
  // <SeenTimestamp>2010-03-24 20:00:00</SeenTimestamp>
  // </Program>
  
  NSXMLElement *anElement = nil;
  anElement = [[NSXMLElement alloc] initWithName:@"Modulation"];
  [anElement setStringValue:[[self channel] tuningType]];
  [programElement addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"Frequency"];
  [anElement setStringValue:[[[self channel] frequency] stringValue]];
  [programElement addChild:anElement];
  [anElement release];

  anElement = [[NSXMLElement alloc] initWithName:@"TransportStreamID"];
  [anElement setStringValue:[[[self channel] transportStreamID] stringValue]];
  [programElement addChild:anElement];
  [anElement release];

  anElement = [[NSXMLElement alloc] initWithName:@"ProgramNumber"];
  [anElement setStringValue:[[self programNumber] stringValue]];
  [programElement addChild:anElement];
  [anElement release];

  anElement = [[NSXMLElement alloc] initWithName:@"SeenTimestamp"];
  NSDate *lastUpdateDate = [[[self channel] channelStationMap] lastUpdateDate];
  [anElement setStringValue:[lastUpdateDate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S" timeZone:nil locale:nil]];
  [programElement addChild:anElement];
  [anElement release];

  [parentElement addChild:programElement];
  [programElement release];
}

- (void)addStationInfoDictionaryTo:(NSMutableArray *)inOutputArray {
  // Build a dictionary of info about this station (program number, scanned callsign and Z2ITStation mapped callsign - if any).
  NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithCapacity:4];
  [infoDictionary setValue:[self programNumber] forKey:@"programNumber"];
  if ([self callSign]) {
    [infoDictionary setValue:[self callSign] forKey:@"callSign"];
  }
  if ([self z2itStation]) {
    [infoDictionary setValue:[[self z2itStation] stationID] forKey:@"Z2ITStationID"];
    if ([[self z2itStation] callSign]) {
      [infoDictionary setValue:[[self z2itStation] callSign] forKey:@"Z2ITCallSign"];
    }
  }

  // and add it to the output array
  [inOutputArray addObject:infoDictionary];
}

@dynamic callSign;
@dynamic programNumber;
@dynamic z2itStation;

- (NSString *)channelAndProgramNumber {
  return [NSString stringWithFormat:@"%@:%@", [[self channel] channelNumber], [self programNumber]];
}

@end
