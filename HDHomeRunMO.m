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
#import "hdhomerun_os.h"
#import "hdhomerun_device.h"

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
	
	// Find a lineup to initialize the tuners with.
	Z2ITLineup *aLineup = nil;
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lineup" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
	
  if ([array count] > 0)
	aLineup = [array objectAtIndex:0];		// Just take the first lineup we have.
	
	// Create the Tuner objects too
	HDHomeRunTuner *anHDHomeRunTuner;
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:0]];
	[anHDHomeRunTuner setLineup:aLineup];
	[anHDHomeRun addTuner:anHDHomeRunTuner];
	[anHDHomeRunTuner release];
	
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:1]];
	[anHDHomeRunTuner setLineup:aLineup];
	[anHDHomeRun addTuner:anHDHomeRunTuner];
	[anHDHomeRunTuner release];
	
	return anHDHomeRun;
}

#pragma mark Property Accessors

- (NSNumber *)deviceID
{
COREDATA_ACCESSOR(NSNumber*, @"deviceID")
}

- (void)setDeviceID:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*, @"deviceID")
}

- (NSString *)name
{
COREDATA_ACCESSOR(NSString*, @"name");
}

- (void) setName:(NSString*)value
{
COREDATA_MUTATOR(NSString*, @"name");
}

- (void) addTuner:(HDHomeRunTuner *)aTuner
{
  NSMutableSet *tuners = [self mutableSetValueForKey:@"tuners"];
  [aTuner setDevice:self];
  [tuners addObject:aTuner];
}

- (HDHomeRunTuner *)tunerWithIndex:(int) inIndex
{
  NSMutableSet *tuners = [self mutableSetValueForKey:@"tuners"];
  NSEnumerator *anEnumerator = [tuners objectEnumerator];
  HDHomeRunTuner *aTuner = nil;
  while ((aTuner = [anEnumerator nextObject]) != nil)
  {
	if ([aTuner index] == [NSNumber numberWithInt:inIndex])
		break;
  }
  return aTuner;
}

- (HDHomeRunTuner *)tuner0
{
	return [self tunerWithIndex:0];
}

- (HDHomeRunTuner *)tuner1
{
	return [self tunerWithIndex:1];
}

#pragma Initialization

- (void) createHDHRDevice
{
  uint32_t deviceID = [[self deviceID] intValue];
  if ((deviceID != 0) && (mHDHomeRunDevice == nil))
  {
    mHDHomeRunDevice = hdhomerun_device_create(deviceID, 0, 0);
  }
}

- (void) awakeFromFetch
{
  [super awakeFromFetch];
  [self createHDHRDevice];
}

- (void) awakeFromInsert
{
  [super awakeFromInsert];
  [self createHDHRDevice];
}

#pragma Uninitialization

- (void) releaseHDHRDevice
{
  if (mHDHomeRunDevice)
    hdhomerun_device_destroy(mHDHomeRunDevice);
  mHDHomeRunDevice = nil;
}

- (void) didTurnIntoFault
{
  [self releaseHDHRDevice];
  
  [super didTurnIntoFault];
}

@end