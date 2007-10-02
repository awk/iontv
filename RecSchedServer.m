//
//  RecSchedServer.m
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecSchedServer.h"

#import "HDHomeRunMO.h"
#import "tvDataDelivery.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "XTVDParser.h"
#import "RecordingThread.h"

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

// If the current schedule data is more than one hour out of date then download new
// schedule data and update the database.
- (void) updateSchedule
{
	// Find the start time of the most 'recent' schedule item.
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [[[[NSApplication sharedApplication] delegate] managedObjectContext] executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find latest schedule");
      return;
  }
	
  BOOL fetchSchedule = NO;
  if ([array count] > 0)
  {
	NSDate *latestScheduleTime = [[array objectAtIndex:0] time];
	NSLog(@"latestScheduleTime = %@", latestScheduleTime);
  }
  else
	fetchSchedule = YES;		// No schedules - fetch some
  
  if (fetchSchedule)
  {
	[self fetchScheduleWithDuration:3];
  }
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
    [[RecordingThreadController alloc]initWithProgram:myProgram andSchedule:mySchedule];
    return YES;
  }
  else
  {
    NSLog(@"Could not find matching local schedule for the program");
    return NO;
  }
}

- (BOOL) addRecordingWithName:(NSString*) name
{
	NSLog(@"addRecordingWithName - name  = %@", name);
	return YES;
}

- (void) performParse:(NSDictionary *)parseInfo
{
  NSDictionary *newParseInfo = [NSDictionary dictionaryWithObjectsAndKeys:[parseInfo objectForKey:@"xmlFilePath"], @"xmlFilePath", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", NULL];
  
  NSLog(@"performParse - newParseInfo = %@", newParseInfo);
//  [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:[xtvdParseThread class] withObject:newParseInfo];
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
