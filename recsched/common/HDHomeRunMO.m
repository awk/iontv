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
#import "Z2ITLineup.h"

const int kDefaultPortNumber = 1234;
NSString *kLatestFirmwareFilename = @"hdhomerun_firmware_20080427";
const int kLatestFirmwareVersion = 20080427;

@implementation HDHomeRun

@dynamic deviceID;
@dynamic name;
@dynamic tuners;
@synthesize newFirmwareAvailable = mNewFirmwareAvailable;
@synthesize deviceOnline = mDeviceOnline;

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *)fetchHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext *)inMOC {
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
  if (array == nil) {
    NSLog(@"Error executing fetch request to find HDHomeRun with ID %@", inDeviceID);
    return nil;
  }
  if ([array count] == 1) {
    return [array objectAtIndex:0];
  } else {
    return nil;
  }
}

+ (HDHomeRun *)createHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext *)inMOC {
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

  if (!array) {
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

  anHDHomeRunTuner = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunTuner" inManagedObjectContext:inMOC];
  [anHDHomeRunTuner setIndex:[NSNumber numberWithInt:1]];
  anHDHomeRunTuner.lineup = aLineup;
  [anHDHomeRun addTunersObject:anHDHomeRunTuner];

  return anHDHomeRun;
}

- (HDHomeRunTuner *)tunerWithIndex:(int)inIndex {
  NSMutableSet *tuners = [self mutableSetValueForKey:@"tuners"];
  HDHomeRunTuner *aTuner = nil;
  for (aTuner in tuners) {
    if ([[aTuner index] intValue] == inIndex) {
      break;
    }
  }
  return aTuner;
}

- (HDHomeRunTuner *)tuner0 {
  return [self tunerWithIndex:0];
}

- (HDHomeRunTuner *)tuner1 {
  return [self tunerWithIndex:1];
}

#pragma mark - Initialization

- (void)createHDHRDevice {
  uint32_t deviceID = [[self deviceID] intValue];
  if ((deviceID != 0) && (mHDHomeRunDevice == nil)) {
    uint32_t version;
    mHDHomeRunDevice = hdhomerun_device_create(deviceID, 0, 0, NULL);

    int versionCheck = hdhomerun_device_get_version(mHDHomeRunDevice, NULL, &version);
    if (versionCheck > 0) {
      mDeviceOnline = YES;
      if (version < kLatestFirmwareVersion) {
        mNewFirmwareAvailable = YES;
      }
    } else {
      // Device offline - exit
      return;
    }
  }
}

- (void)awakeFromFetch {
  [super awakeFromFetch];
  [self createHDHRDevice];
}

- (void) awakeFromInsert {
  [super awakeFromInsert];
  [self createHDHRDevice];
}

#pragma mark - Uninitialization

- (void)releaseHDHRDevice {
  if (mHDHomeRunDevice) {
    hdhomerun_device_destroy(mHDHomeRunDevice);
  }
  mHDHomeRunDevice = nil;
}

- (void)willTurnIntoFault {
  [self releaseHDHRDevice];
}

- (BOOL) upgradeFirmware {
  NSString *firmwareFilename = [[NSBundle mainBundle] pathForResource:kLatestFirmwareFilename ofType:@"bin"];
  FILE *upgradeFile = NULL;

  upgradeFile = fopen([firmwareFilename UTF8String], "rb");
  if (upgradeFile == NULL) {
    NSAlert *upgradeAlert = [[NSAlert alloc] init];
    [upgradeAlert setMessageText:@"Unable to find firmware image."];
    [upgradeAlert setInformativeText:@"The firmware on the HDHomeRun needs to be upgraded but the appropriate firmware file cannot be found."];
    [upgradeAlert addButtonWithTitle:@"OK"];
    [upgradeAlert runModal];
    [upgradeAlert release];
    return NO;
  }

  int upgradeResult = hdhomerun_device_upgrade(mHDHomeRunDevice, upgradeFile);
  if (upgradeResult == 0) {
    // Upload rejected
    NSAlert *upgradeAlert = [[NSAlert alloc] init];
    [upgradeAlert setMessageText:@"Unable to apply firmware upgrade."];
    [upgradeAlert setInformativeText:@"The firmware image was rejected by the HDHomeRun it may be corrupt or incompatible with the device."];
    [upgradeAlert addButtonWithTitle:@"OK"];
    [upgradeAlert runModal];
    [upgradeAlert release];
  } else if (upgradeResult == 1) {
    // Upgrade successful
    return YES;
  } else {
    NSAlert *upgradeAlert = [[NSAlert alloc] init];
    [upgradeAlert setMessageText:@"Unable to upgrade firmware."];
    [upgradeAlert setInformativeText:@"The firmware on the HDHomeRun could not be upgraded."];
    [upgradeAlert addButtonWithTitle:@"OK"];
    [upgradeAlert runModal];
    [upgradeAlert release];
  }
  return NO;
}

@end
