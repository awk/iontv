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
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "XTVDParser.h"
#import "RecordingThread.h"
#import "HDHomeRunTuner.h"

const int kDefaultScheduleFetchDuration = 3;

@implementation RecSchedServer

- (id) init {
  self = [super init];
  if (self != nil) {
    mExitServer = NO;
  }
  return self;
}

#pragma mark - Internal Methods

- (void) fetchScheduleWithDuration:(int)inHours
{
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  
  // Converting the current time to a Gregorian Date with no timezone gives us a GMT time that
  // Zap2It expects
  CFGregorianDate startDate = CFAbsoluteTimeGetGregorianDate(currentTime,NULL);
  
  // Retrieve 'n' hours of data
  CFGregorianUnits retrieveRange;
  memset(&retrieveRange, 0, sizeof(retrieveRange));
  retrieveRange.hours = inHours;
    
  CFAbsoluteTime endTime = CFAbsoluteTimeAddGregorianUnits(currentTime, NULL, retrieveRange);
  CFGregorianDate endDate = CFAbsoluteTimeGetGregorianDate(endTime,NULL);
  
  NSString *startDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", startDate.year, startDate.month, startDate.day, startDate.hour];
  NSString *endDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", endDate.year, endDate.month, endDate.day, endDate.hour];
  
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:startDateStr, @"startDateStr", endDateStr, @"endDateStr", self, @"dataRecipient", nil];
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
    NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:[xtvd valueForKey:@"xmlFilePath"], @"xmlFilePath",
        self, @"reportProgressTo", 
        self, @"reportCompletionTo", 
        [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator",
        nil];
    
    // Start our local parsing
    xtvdParseThread *aParseThread = [[xtvdParseThread alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:aParseThread withObject:callData];
    
    [callData release];
  }
}

- (void) setParsingInfoString:(NSString*)inInfoString
{
	NSLog(@"Parsing - %@", inInfoString);
}

- (void) setParsingProgressMaxValue:(double)inTotal
{
}

- (void) setParsingProgressDoubleValue:(double)inValue
{
}

- (void) parsingComplete:(id)info
{
	NSLog(@"parsingComplete");
  // Clear all old items from the store
//  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
//  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportProgressTo", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];
//
//  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
}

- (void) cleanupComplete:(id)info
{
	NSLog(@"cleanupComplete");
}

#pragma mark - Server Methods

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
  int i=0;
  for (i=0; i < [array count]; i++)
  {
	Z2ITStation *aStation = [array objectAtIndex:i];
	NSSet *hdhrStations = [aStation hdhrStations];
	NSLog(@"Station Callsign = %@, hdhrStations = %@, hdhrStation callSign = %@, hdhrStation programNumber = %@",
		[aStation callSign], hdhrStations, [[hdhrStations anyObject] callSign], [[hdhrStations anyObject] programNumber]);
  }
}

// If the current schedule data is more than one hour out of date then download new
// schedule data and update the database.
- (void) updateSchedule
{
	[self findStations];

	// Set up a timer to fire one hour before the about to be fetched schedule data 'runs out'
	[NSTimer scheduledTimerWithTimeInterval:(kDefaultScheduleFetchDuration - 1) * 60 * 60 target:self selector:@selector(updateScheduleTimer:) userInfo:nil repeats:YES]; 

//	[self fetchScheduleWithDuration:kDefaultScheduleFetchDuration];
}

- (void) updateScheduleTimer:(NSTimer*)aTimer
{
	NSLog(@"Time to update the schedule!");
	[self fetchScheduleWithDuration:kDefaultScheduleFetchDuration];
}

- (BOOL) addRecordingOfProgram:(NSManagedObject*) aProgram
            withSchedule:(NSManagedObject*)aSchedule
{
  Z2ITStation *aStation = [(Z2ITSchedule *)aSchedule station];
  Z2ITProgram *myProgram = [Z2ITProgram fetchProgramWithID:[(Z2ITProgram *)(aProgram) programID] inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
  NSSet *mySchedules = [myProgram schedules];
  NSEnumerator *anEnumerator = [mySchedules objectEnumerator];
  Z2ITSchedule *mySchedule = nil;
  BOOL foundMatch = NO;
  while (mySchedule = [anEnumerator nextObject])
  {
    // Compare with time intervals since that will take into account any timezone discrepancies
    if (([[aStation stationID] intValue] == [[[mySchedule station] stationID] intValue]) && ([[mySchedule time] timeIntervalSinceDate:[(Z2ITSchedule*)aSchedule time]] == 0))
    {
      foundMatch = YES;
      break;
    }
  }
  if (foundMatch)
  {
	NSLog(@"My Program = %@, My Schedule = %@", myProgram, mySchedule);
    [[RecordingThreadController alloc]initWithProgram:myProgram andSchedule:mySchedule];
    return YES;
  }
  else
  {
    NSLog(@"Could not find matching local schedule for the program");
    return NO;
  }
}

- (oneway void) pushHDHomeRunChannelsAndStations:(NSArray*)channelsArray onDeviceID:(int)deviceID forTunerIndex:(int)tunerIndex
{
	NSLog(@"pushHDHomeRunChannelsAndStations deviceID = %d, tunerIndex = %d, channels = %@", deviceID, tunerIndex, channelsArray);

	HDHomeRun *anHDHomeRun = [HDHomeRun fetchHDHomeRunWithID:[NSNumber numberWithInt:deviceID] inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	if (anHDHomeRun)
	{
		HDHomeRunTuner *aTuner = [anHDHomeRun tunerWithIndex:tunerIndex];
		if (aTuner)
		{
			// Fetch a sorted (by channelNumber) array from the managed object context.
			// This should entirely match (one for one) the channelNumber array that has been passed in to this method.
			NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRunChannel" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
			NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
			[request setEntity:entityDescription];

			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tuner == %@", aTuner];
			[request setPredicate:predicate];

			NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"channelNumber" ascending:YES];
			[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
			[sortDescriptor release];

			NSError *error = nil;
			NSArray *myChannelsArray = [[[NSApp delegate] managedObjectContext] executeFetchRequest:request error:&error];
			if (error || myChannelsArray == nil)
			{
				NSLog(@"pushHDHomeRunChannelsAndStations: Error executing fetch to find channels - error = %@", error);
				return;
			}
			
			int channelIdx = 0;
			for ( ; channelIdx < [channelsArray count]; channelIdx++)
			{
				NSDictionary *aChannelDictionary = [channelsArray objectAtIndex:channelIdx];
				
				// Get the channel from the tuner
				HDHomeRunChannel *aChannel = [myChannelsArray objectAtIndex:channelIdx];
				if ([[aChannel channelNumber] compare:[aChannelDictionary valueForKey:@"channelNumber"]] != NSOrderedSame)
				{
					NSLog(@"Unexpected misalignment in channel arrays %@ != %@", aChannel, aChannelDictionary);
					break;
				}
				
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

@end
