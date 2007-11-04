//  recsched_bkgd - Background server application retrieves schedule data, performs recordings,
//  transcodes recordings in to H.264 format for iTunes, iPod etc.
//  
//  Copyright (C) 2007 Andrew Kimpton
//  
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "RecSchedServer.h"
#import "recsched_bkgd_AppDelegate.h"
#import "HDHomeRunMO.h"
#import "hdhomerun.h"
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
NSString *RSNotificationUIActivityAvailable = @"RSNotificationUIActivityAvailable";

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
  
  // Post a notification that the activity connection is available
  [[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationUIActivityAvailable object:self];
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
    NSMutableDictionary *callData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[xtvd valueForKey:@"xmlFilePath"], @"xmlFilePath",
        notificationProxy, @"reportProgressTo", 
        completionProxy, @"reportCompletionTo", 
        [[NSApp  delegate] persistentStoreCoordinator], @"persistentStoreCoordinator",
        nil];

	if ([downloadResult valueForKey:@"lineupsOnly"] != nil)
		[callData setValue:[downloadResult valueForKey:@"lineupsOnly"] forKey:@"lineupsOnly"];
		
    // Start our local parsing
    xtvdParseThread *aParseThread = [[xtvdParseThread alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:aParseThread withObject:callData];
    
    [callData release];
  }
}

#pragma mark Activity Protocol Methods

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

- (BOOL) shouldCancelActivity:(size_t)activityToken
{
	return NO;
}

#pragma mark Store Update Protocol Methods

- (void) parsingComplete:(id)info
{
	NSLog(@"parsingComplete");
  // Clear all old items from the store
#if 0
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportProgressTo", self, @"reportCompletionTo", [[NSApp  delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];

  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
#else
	// No cleanup performed - just send a fake cleanup complete notification
	[self cleanupComplete:info];
#endif
}

- (void) cleanupComplete:(id)info
{
	NSLog(@"cleanupComplete");
}

- (void) downloadError:(id)info
{
	NSLog(@"downloadError %@", info);
}

- (void) deviceScanComplete:(id)info
{
	NSLog(@"deviceScanComplete %@", info);
}

- (void) channelScanComplete:(id)info
{
	NSLog(@"channelScanComplete %@", info);
}

- (void) recordingComplete:(NSManagedObjectID *)aRecordingObjectID
{
	[[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationRecordingFinished object:aRecordingObjectID];
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
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:[[NSApp  delegate] managedObjectContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callSign == %@", @"WGBH"];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array = [[[NSApp  delegate] managedObjectContext] executeFetchRequest:request error:&error];
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
		RSRecording *aRecording = [RSRecording insertRecordingOfSchedule:mySchedule];
		if (aRecording)
		{
			[[RecordingThreadController alloc]initWithRecording:aRecording recordingServer:self];
			NSError *error = nil;
			if (![[[NSApp delegate] managedObjectContext] save:&error])
				NSLog(@"addRecordingOfSchedule - error occured during save %@", error);
		}
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

- (void) scanForHDHomeRunDevices:(id)sender
{
	struct hdhomerun_discover_device_t result_list[64];
	NSMutableArray *newHDHomeRuns = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray *existingHDHomeRuns = [NSMutableArray arrayWithCapacity:5];
	size_t activityToken = [[self uiActivity] createActivity];
  
	[[self uiActivity] setActivity:activityToken infoString:[NSString stringWithFormat:@"Looking for HDHomeRun Devices"]]; 
	[[self uiActivity] setActivity:activityToken progressIndeterminate:YES];
	
	int count = hdhomerun_discover_find_devices(HDHOMERUN_DEVICE_TYPE_TUNER, result_list, 64);
	
	if (count > 0)
	{
		int i=0;
		for (i=0; i < count; i++)
		{
			// See if an entry already exists
			HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:[NSNumber numberWithInt:result_list[i].device_id] inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
			if (!anHDHomeRun)
			{
			  // Otherwise we just create a new one
			  anHDHomeRun = [HDHomeRun createHDHomeRunWithID:[NSNumber numberWithInt:result_list[i].device_id] inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
			  [newHDHomeRuns addObject:anHDHomeRun];
			  [anHDHomeRun setName:[NSString stringWithFormat:@"Tuner 0x%x", result_list[i].device_id]];
			}
			else
				[existingHDHomeRuns addObject:anHDHomeRun];
		}
	}
	[[self uiActivity] endActivity:activityToken];
	NSError *error = nil;
	if (![[[NSApp delegate] managedObjectContext] save:&error])
	{
		NSLog(@"scanForHDHomeRunDevices - saving context reported error %@", error);
	}
	NSDictionary *scanInfo = [NSDictionary dictionaryWithObjectsAndKeys:existingHDHomeRuns, @"existingHDHomeRuns", newHDHomeRuns, @"newHDHomeRuns", nil];
	[[self storeUpdate] deviceScanComplete:scanInfo];
}


- (void) scanForChannelsOnHDHomeRunDeviceID:(NSNumber*)deviceID tunerIndex:(NSNumber*)tunerIndex
{
	HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:deviceID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	if (!anHDHomeRun)
	{
		NSLog(@"scanForChannelsOnHDHomeRunDeviceID:%@ - No Device Found !", deviceID);
		return;
	}
	HDHomeRunTuner *aTuner = [anHDHomeRun tunerWithIndex:[tunerIndex intValue]];
	if (!aTuner)
	{
		NSLog(@"scanForChannelsOnHDHomeRunDeviceID:%@ tunerIndex:%@ - No Tuner Found !", deviceID, tunerIndex);
		return;
	}
	[aTuner scanActionReportingProgressTo:[self uiActivity]];
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
		anHDHomeRun.tuner0.lineup = aLineup;
		aLineup = [Z2ITLineup fetchLineupWithID:tuner1LineupID inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		anHDHomeRun.tuner1.lineup = aLineup;

		NSError *error = nil;
		if (![[[NSApp delegate] managedObjectContext] save:&error])
		{
			NSLog(@"setHDHomeRunDeviceWithID - saving context reported error %@, info = %@", error, [error userInfo]);
		}
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
				NSError *error = nil;
				if (![[[NSApp delegate] managedObjectContext] save:&error])
					NSLog(@"setHDHomeRunChannelsAndStations - error occured during save %@", error);
			} 
		} 
	} 
}

- (void) quitServer:(id)sender
{
	[NSApp  terminate:self];
//  if ([self applicationShouldTerminate:NSApp ])
  {
    NSLog(@"Server shutting down");
    mExitServer = YES;
  }
}

- (void) reloadPreferences:(id)sender
{
	[NSUserDefaults resetStandardUserDefaults];
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:@"org.awkward.iontv"];
}

@synthesize mStoreUpdate;
@synthesize mUIActivity;
@synthesize mExitServer;
@end
