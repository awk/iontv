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

#import "HDHomeRunMO.h"
#import "HDHomeRunTuner.h"
#import "hdhomerun_os.h"
#import "hdhomerun_device.h"
#import "Z2ITLineup.h"

const int kDefaultPortNumber = 1234;

@implementation HDHomeRun

@dynamic deviceID;
@dynamic name;
@dynamic tuners;

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *) fetchHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRun" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];
   
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
      return [array objectAtIndex:0];
  }
  else
  {
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
  [request setFetchLimit:1];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];

  if (!array)
  {
	NSLog(@"createHDHomeRunWithID %d - no lineups !");
	return nil;
  }

	aLineup = [array objectAtIndex:0];
  
	// Create the Tuner objects too
	HDHomeRunTuner *anHDHomeRunTuner;
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:0]];
	anHDHomeRunTuner.lineup = aLineup;
	[anHDHomeRun addTunersObject:anHDHomeRunTuner];
	[anHDHomeRunTuner release];
	
	anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
	[anHDHomeRunTuner setIndex:[NSNumber numberWithInt:1]];
	anHDHomeRunTuner.lineup = aLineup;
	[anHDHomeRun addTunersObject:anHDHomeRunTuner];
	[anHDHomeRunTuner release];
	
	return anHDHomeRun;
}

- (HDHomeRunTuner *)tunerWithIndex:(int) inIndex
{
  NSMutableSet *tuners = [self mutableSetValueForKey:@"tuners"];
  HDHomeRunTuner *aTuner = nil;
  for (aTuner in tuners)
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

#pragma mark - Initialization

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

#pragma mark - Uninitialization

- (void) releaseHDHRDevice
{
  if (mHDHomeRunDevice)
    hdhomerun_device_destroy(mHDHomeRunDevice);
  mHDHomeRunDevice = nil;
}

- (void) willTurnIntoFault
{
  [self releaseHDHRDevice];
}

@end
