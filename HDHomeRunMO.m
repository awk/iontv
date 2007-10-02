//
//  HDHomeRun.m
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HDHomeRunMO.h"
#import "HDHomeRunTuner.h"
#import "CoreData_Macros.h"


@implementation HDHomeRun


// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *) fetchHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRun" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deviceID == %@", inDeviceID];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"deviceID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find HDHomeRun with ID %@", inDeviceID);
      return nil;
  }
  if ([array count] == 1)
  {
    HDHomeRun *aHDHomeRun = [array objectAtIndex:0];
    [aHDHomeRun retain];
    return aHDHomeRun;
  }
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchHDHomeRunWithID - multiple (%d) HDHomeRuns with ID %@", [array count], inDeviceID);
      return nil;
  }
}

+ (HDHomeRun *) createHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
	HDHomeRun *anHDHomeRun;
	
	// Otherwise we just create a new one
	anHDHomeRun = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRun" inManagedObjectContext:inMOC];
	[anHDHomeRun setDeviceID:inDeviceID];
	
	// Create the Tuner objects too
	HDHomeRunTuner *anHDHomeRunTuner;
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:0]];
	[anHDHomeRun addTuner:anHDHomeRunTuner];
	[anHDHomeRunTuner release];
	
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:1]];
	[anHDHomeRun addTuner:anHDHomeRunTuner];

	return anHDHomeRun;
}

- (void) addTuner:(HDHomeRunTuner *)aTuner
{
  NSMutableSet *tuners = [self mutableSetValueForKey:@"tuners"];
  [aTuner setDevice:self];
  [tuners addObject:aTuner];
}

- (NSNumber *)deviceID
{
COREDATA_ACCESSOR(NSNumber*, @"deviceID")
}

- (void)setDeviceID:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*, @"deviceID")
}

@end
