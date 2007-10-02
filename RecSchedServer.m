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
	// Set up a timer to fire one hour before the about to be fetched schedule data 'runs out'
	[NSTimer scheduledTimerWithTimeInterval:(kDefaultScheduleFetchDuration - 1) * 60 * 60 target:self selector:@selector(updateScheduleTimer:) userInfo:nil repeats:YES]; 

	[self fetchScheduleWithDuration:kDefaultScheduleFetchDuration];
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
	[mySchedule setToBeRecorded:[NSNumber numberWithBool:YES]];
    [[RecordingThreadController alloc]initWithProgram:myProgram andSchedule:mySchedule];
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
  [NSThread detachNewThreadSelector:@selector(performDownload:) toTarget:[xtvdDownloadThread class] withObject:callData];
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
