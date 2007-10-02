//
//  HDHomeRunTuner.m
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HDHomeRunTuner.h"
#import "HDHomeRunMO.h"
#import "CoreData_Macros.h"

@implementation HDHomeRunTuner

- (NSNumber *) index;
{
COREDATA_ACCESSOR(NSNumber*, @"index")
}

- (void) setIndex:(NSNumber*)value;
{
COREDATA_MUTATOR(NSNumber*, @"index")
}

- (HDHomeRun*) device
{
COREDATA_ACCESSOR(HDHomeRun*, @"device")
}

- (void) setDevice:(HDHomeRun *)value
{
COREDATA_MUTATOR(HDHomeRun*, @"device")
}

- (Z2ITLineup*)lineup
{
COREDATA_ACCESSOR(Z2ITLineup*, @"lineup");
}

- (void) setLineup:(Z2ITLineup*)value
{
COREDATA_MUTATOR(Z2ITLineup*, @"lineup");
}

- (NSString*) longName
{
  NSString *name = [NSString stringWithFormat:@"%@ - %@ - %@", [[self device] name], [self index], [[self lineup] name]];
  return name;
}

#pragma Actions

- (void) scanAction
{
  NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);
}

#pragma Initialization

- (void) createHDHRDevice
{
  uint32_t deviceID = [[[self device] deviceID] intValue];
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
  NSLog(@"HDHomeRunMO - awakeFromInsert");
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
