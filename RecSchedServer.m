//
//  RecSchedServer.m
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecSchedServer.h"
#import "recsched_bkgd_AppDelegate.h"
#import "HDHomeRunMO.h"
#import "tvDataDelivery.h"
#import "Z2ITLineup.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "RSRecording.h"
#import "XTVDParser.h"
#import "RecordingThread.h"
#import "HDHomeRunTuner.h"
#import "RSStoreUpdateProtocol.h"

const int kDefaultScheduleFetchDuration = 3;

@implementation RecSchedServer

- (id) init {
  self = [super init];
  if (self != nil) {
    mExitServer = NO;
  }
  return self;
}

- (void) initializeUIActivityConnection
{
  // Connect to server
  mUIActivity = [[NSConnection rootProxyForConnectionWithRegisteredName:kRecUIActivityConnectionName  host:nil] retain];
   
  // check if connection worked.
  if (mUIActivity == nil) 
  {
    NSLog(@"couldn't connect with User Interface Application");
  }
  else
  {
    //
    // set protocol for the remote object & then register ourselves with the 
    // messaging server.
    [mUIActivity setProtocolForProxy:@protocol(RSActivityDisplay)];
  }
}

- (void) initializeStoreUpdateConnection
{
  // Connect to server
  mStoreUpdate = [[NSConnection rootProxyForConnectionWithRegisteredName:kRSStoreUpdateConnectionName  host:nil] retain];
   
  // check if connection worked.
  if (mStoreUpdate == nil) 
  {
    NSLog(@"couldn't connect with User Interface (store update) Application");
  }
  else
  {
    //
    // set protocol for the remote object & then register ourselves with the 
    // messaging server.
    [mStoreUpdate setProtocolForProxy:@protocol(RSStoreUpdate)];
  }
}

- (id) uiActivity
{
	return mUIActivity;
}

- (id) storeUpdate
{
	return mStoreUpdate;
}

#pragma mark - Internal Methods

- (void) fetchScheduleWithDuration:(int)inHours
{
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  
  // Converting the current time to a Gregorian Date with no timezone gives us a GMT time that
  // SchedulesDirect expects
  CFGregorianDate startDate = CFAbsoluteTimeGetGregorianDate(currentTime,NULL);
  
  // Retrieve 'n' hours of data
  CFGregorianUnits retrieveRange;
  memset(&retrieveRange, 0, sizeof(retrieveRange));
  retrieveRange.hours = inHours;
    
  CFAbsoluteTime endTime = CFAbsoluteTimeAddGregorianUnits(currentTime, NULL, retrieveRange);
  CFGregorianDate endDate = CFAbsoluteTimeGetGregorianDate(endTime,NULL);
  
  NSString *startDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", startDate.year, startDate.month, startDate.day, startDate.hour];
  NSString *endDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", endDate.year, endDate.month, endDate.day, endDate.hour];
  
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:startDateStr, @"startDateStr", endDateStr, @"endDateStr", self, @"dataRecipient", self, @"reportProgressTo", nil];
  [NSThread detachNewThreadSelector:@selector(performDownload:) toTarget:[xtvdDownloadThread class] withObject:callData];
  [callData release];
}

#pragma mark Callback Methods

- (void) handleDownloadData:(id)inDownloadResult
{
  NSDictionary *downloadResult = (NSDictionary*)inDownloadResult;
  NSDictionary *messages = [downloadResult valueForKey:@"messages"];
  NSDictionary *xtvd = [downloadResult valueForKey:@"xtvd"];
  NSLog(@"getScheduleAction downloadResult messages = %@", messages);
  NSLog(@"getScheduleAction downloadResult xtvd = %@", xtvd);
  [downloadResult release];

  if (xtvd != nil)
  {
	id notificationProxy = [self uiActivity];
	if (notificationProxy == nil)
		notificationProxy = self;
	id completionProxy = [self storeUpdate];
	if (completionProxy == nil)
		completionProxy = self;
    NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:[xtvd valueForKey:@"xmlFilePath"], @"xmlFilePath",
        notificationProxy, @"reportProgressTo", 
        completionProxy, @"reportCompletionTo", 
        [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator",
        nil];
    
    // Start our local parsing
    xtvdParseThread *aParseThread = [[xtvdParseThread alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:aParseThread withObject:callData];
    
    [callData release];
  }
}

- (size_t) createActivity
{
	NSDictionary *anActivity = [[NSMutableDictionary alloc] initWithCapacity:3]; 
	return (size_t) anActivity;
}

- (void) endActivity:(size_t)activityToken
{
	[(NSDictionary *)activityToken release];
}

- (void) setActivity:(size_t)activityToken infoString:(NSString*)inInfoString
{
	NSLog(@"setActivityInfoString - %@", inInfoString);
}

- (void) setActivity:(size_t)activityToken progressIndeterminate:(BOOL) isIndeterminate
{
}

- (void) setActivity:(size_t)activityToken progressMaxValue:(double)inTotal
{
}

- (void) setActivity:(size_t)activityToken progressDoubleValue:(double)inValue
{
}

- (void) setActivity:(size_t)activityToken incrementBy:(double)delta
{
}

- (void) parsingComplete:(id)info
{
	NSLog(@"parsingComplete");
  // Clear all old items from the store
#if 0
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportProgressTo", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];

  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
#else
	// No cleanup performed - just send a fake cleanup complete notification
	[self cleanupComplete:info];
#endif
}

- (void) cleanupComplete:(id)info
{
	NSLog(@"cleanupComplete");
	
#if USE_SYNCSERVICES
	[[NSApp delegate] syncAction:nil];
#endif // USE_SYNCSERVICES
}

#pragma mark - Server Methods

- (void) activityDisplayAvailable
{
	[self initializeUIActivityConnection];
}

- (void) activityDisplayUnavailable
{
	[mUIActivity release];
	mUIActivity = nil;
}

- (void) storeUpdateAvailable
{
	[self initializeStoreUpdateConnection];
}

- (void) storeUpdateUnavailable
{
	[mStoreUpdate release];
	mStoreUpdate = nil;
}

- (bool) shouldExit
{
	return mExitServer;
}

- (void) findStations
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callSign == %@", @"WGBH"];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array = [[[[NSApplication sharedApplication] delegate] managedObjectContext] executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find latest schedule");
      return;
  }
  for (Z2ITStation *aStation in array)
  {
	NSSet *hdhrStations = [aStation hdhrStations];
	NSLog(@"Station Callsign = %@, hdhrStations = %@, hdhrStation callSign = %@, hdhrStation programNumber = %@",
		[aStation callSign], hdhrStations, [[hdhrStations anyObject] callSign], [[hdhrStations anyObject] programNumber]);
  }
}

// If the current schedule data is more than one hour out of date then download new
// schedule data and update the database.
- (void) updateSchedule
{
	// For now we'll just determine the 'up to date' ness by using the last written date on the CoreData store
	NSURL *storeURL = [[NSApp delegate] urlForPersistentStore];
	NSError *error = nil;
	NSDictionary *storeAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[storeURL path] error:&error];
	BOOL updateScheduleNow = YES;
	if (!error)
	{
		// -3600 is one hour in the past
		if ([[storeAttributes valueForKey:NSFileModificationDate] timeIntervalSinceNow] > -3600)
			updateScheduleNow = NO;
	}
	
	// Set up a timer to fire one hour before the about to be fetched schedule data 'runs out'
	[NSTimer scheduledTimerWithTimeInterval:(kDefaultScheduleFetchDuration - 1) * 60 * 60 target:self selector:@selector(updateScheduleTimer:) userInfo:nil repeats:YES]; 
	
	if (updateScheduleNow)
		[self fetchScheduleWithDuration:kDefaultScheduleFetchDuration];
}

- (void) updateScheduleTimer:(NSTimer*)aTimer
{
	NSLog(@"Time to update the schedule!");
	[self fetchScheduleWithDuration:kDefaultScheduleFetchDuration];
}

- (BOOL) addRecordingOfSchedule:(NSManagedObjectID*)scheduleObjectID
{
  Z2ITSchedule *mySchedule = nil;
  mySchedule = (Z2ITSchedule*) [[[NSApp delegate] managedObjectContext] objectWithID:scheduleObjectID];
  
  if (mySchedule)
  {
	NSLog(@"My Program title = %@, My Schedule start time = %@ channel = %@, recording = %@", mySchedule.program.title, mySchedule.time, mySchedule.station.callSign, [mySchedule recording]);
	if ([mySchedule recording] == nil)
	{
		RSRecording *aRecording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		[mySchedule setRecording:aRecording];
		[aRecording setSchedule:mySchedule];
		[aRecording setStatus:[NSNumber numberWithInt:RSRecordingNoStatus]];
		
		[[RecordingThreadController alloc]initWithSchedule:mySchedule recordingServer:self];
		
		[[NSApp delegate] saveAction:self];
	}
    return YES;
  }
  else
  {
    NSLog(@"Could not find matching local schedule for the program");
    return NO;
  }
}

- (oneway void) performDownload:(NSDictionary*)callData
{
  NSMutableDictionary *updatedCallData = [NSMutableDictionary dictionaryWithDictionary:callData];
  [updatedCallData setValue:self forKey:@"dataRecipient"];
  [updatedCallData setValue:[self uiActivity] forKey:@"reportProgressTo"];
  [NSThread detachNewThreadSelector:@selector(performDownload:) toTarget:[xtvdDownloadThread class] withObject:updatedCallData];
}

// Add an HDHomeRun device with the specified ID - return YES if a new device was created and added.
- (BOOL) addHDHomeRunWithID:(NSNumber*)deviceID
{
	// See if an entry already exists
	HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:deviceID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	if (!anHDHomeRun)
	{
	  // Otherwise we just create a new one
	  [HDHomeRun createHDHomeRunWithID:deviceID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	  return YES;
	}
	return NO;
}

- (void) setHDHomeRunDeviceWithID:(NSNumber*)deviceID nameTo:(NSString*)name tuner0LineupIDTo:(NSString*)tuner0LineupID tuner1LineupIDTo:(NSString*) tuner1LineupID
{
	// See if an entry already exists
	HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:deviceID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	if (anHDHomeRun)
	{
		[anHDHomeRun setName:name];
		
		Z2ITLineup *aLineup = [Z2ITLineup fetchLineupWithID:tuner0LineupID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		[[anHDHomeRun tuner0] setLineup:aLineup];
		aLineup = [Z2ITLineup fetchLineupWithID:tuner1LineupID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		[[anHDHomeRun tuner1] setLineup:aLineup];
	}
	else
	{
		NSLog(@"setHDHomeRunDeviceWithID - cannot find device with ID %@", deviceID);
	}
}

- (oneway void) setHDHomeRunChannelsAndStations:(NSArray*)channelsArray onDeviceID:(int)deviceID forTunerIndex:(int)tunerIndex
{
	NSLog(@"setHDHomeRunChannelsAndStations deviceID = %d, tunerIndex = %d", deviceID, tunerIndex); 

	HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:[NSNumber numberWithInt:deviceID] inManagedObjectContext:[[NSApp delegate] managedObjectContext]]; 
	if (anHDHomeRun) 
	{ 
		HDHomeRunTuner *aTuner = [anHDHomeRun tunerWithIndex:tunerIndex]; 
		if (aTuner) 
		{ 
			// Remove all the channels current on the tuner - we're going to replace them.
			[aTuner removeChannels:[aTuner channels]];
			
			int channelIdx = 0; 
			for (NSDictionary *aChannelDictionary in channelsArray) 
			{ 
				NSLog(@"setHDHomeRunChannelsAndStations new channel number %d type %@ stations %@", [aChannelDictionary valueForKey:@"channelNumber"], [aChannelDictionary valueForKey:@"channelType"], [aChannelDictionary valueForKey:@"stations"]);
				// Create a new channel for this tuner
				HDHomeRunChannel *aChannel = [HDHomeRunChannel createChannelWithType:[aChannelDictionary valueForKey:@"channelType"] andNumber:[aChannelDictionary valueForKey:@"channelNumber"] inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
				[aTuner addChannelsObject:aChannel];
				
				// Remove all the stations on the given channel - they'll be replaced with the data from the array 
				[aChannel clearAllStations]; 

				// Add all the stations in the array for this channel 
				[aChannel importStationsFrom:[aChannelDictionary valueForKey:@"stations"]]; 
			} 

			if (channelIdx > 0) 
			{ 
				// processed some stations - save the MOC 
				[[NSApp delegate] saveAction:self]; 
			} 
		} 
	} 
}

- (void) quitServer:(id)sender
{
	[[NSApplication sharedApplication] terminate:self];
//  if ([self applicationShouldTerminate:[NSApplication sharedApplication]])
  {
    NSLog(@"Server shutting down");
    mExitServer = YES;
  }
}

@synthesize mStoreUpdate;
@synthesize mUIActivity;
@synthesize mExitServer;
@end
