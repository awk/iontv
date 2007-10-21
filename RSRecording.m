//
//  RSRecording.m
//  recsched
//
//  Created by Andrew Kimpton on 9/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSRecording.h"
#import "RecSchedProtocol.h"
#import "Z2ITSchedule.h"

@implementation RSRecording

@dynamic mediaFile;
@dynamic status;
@dynamic schedule;

+ (RSRecording*) insertRecordingOfSchedule:(Z2ITSchedule*)aSchedule
{
	RSRecording *aRecording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	[aRecording setSchedule:aSchedule];
	[aSchedule setRecording:aRecording];
	[aRecording setStatus:[NSNumber numberWithInt:RSRecordingNotYetStartedStatus]];
	return aRecording;
}

+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC afterDate:(NSDate*)aDate
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.endTime > %@", [NSDate dateWithTimeIntervalSinceNow:0]];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC beforeDate:(NSDate*)aDate
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.time < %@", [NSDate dateWithTimeIntervalSinceNow:0]];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

@end
