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

#import "RSRecording.h"
#import "RSRecordingOptions.h"
#import "RecSchedProtocol.h"
#import "Z2ITSchedule.h"

@implementation RSRecording

@dynamic mediaFile;
@dynamic status;
@dynamic schedule;
@dynamic tuner;
@dynamic recordingOptions;
@dynamic seasonPass;
@synthesize recordingOperation;
@synthesize recordingQueue;

+ (RSRecording *)insertRecordingOfSchedule:(Z2ITSchedule *)aSchedule {
  RSRecording *aRecording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
  [aRecording setSchedule:aSchedule];
  [aSchedule setRecording:aRecording];
  [aRecording setStatus:[NSNumber numberWithInt:RSRecordingNotYetStartedStatus]];

  RSRecordingOptions *options = [NSEntityDescription insertNewObjectForEntityForName:@"RecordingOptions" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
  options.keepUntil = kRSRecordingOptionsKeepUntilSpaceNeeded;
  aRecording.recordingOptions = options;
  return aRecording;
}

+ (NSArray *)fetchRecordingsInManagedObjectContext:(NSManagedObjectContext *)inMOC afterDate:(NSDate *)aDate withStatus:(int)status {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.endTime > %@ and status == %@", aDate, [NSNumber numberWithInt:status]];
  [request setPredicate:predicate];

  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"schedule.time" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

+ (NSArray *)fetchRecordingsInManagedObjectContext:(NSManagedObjectContext *)inMOC beforeDate:(NSDate *)aDate {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.time < %@", aDate];
  [request setPredicate:predicate];

  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"schedule.time" ascending:NO];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

+ (NSArray *)fetchRecordingsInManagedObjectContext:(NSManagedObjectContext *)inMOC afterDate:(NSDate*)afterDate beforeDate:(NSDate *)beforeDate {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(schedule.time < %@ AND schedule.time > %@) OR (schedule.endTime < %@ AND schedule.endTime > %@)", beforeDate, afterDate, beforeDate, afterDate];
  [request setPredicate:predicate];

  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"schedule.time" ascending:NO];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

@end
