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

+ (void) createRecordingOfSchedule:(Z2ITSchedule*)aSchedule withServer:(id)recServer
{
	RSRecording *aRecording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	[aRecording setSchedule:aSchedule];
	[aSchedule setRecording:aRecording];
	[aRecording setStatus:[NSNumber numberWithInt:RSRecordingNoStatus]];
	
	if (recServer)
		[recServer addRecordingOfSchedule:[aSchedule objectID]];
}

+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}

@end
