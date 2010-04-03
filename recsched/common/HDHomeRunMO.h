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

#import <Cocoa/Cocoa.h>
#import "hdhomerun.h"

extern const int kDefaultPortNumber;

@class HDHomeRunTuner;

@interface HDHomeRun : NSManagedObject {
  struct hdhomerun_device_t *mHDHomeRunDevice;
  BOOL mNewFirmwareAvailable;
  BOOL mDeviceOnline;
}

@property (retain) NSNumber * deviceID;
@property (retain) NSString * name;
@property (retain) NSSet * tuners;
@property (readonly) BOOL newFirmwareAvailable;
@property (readonly) BOOL deviceOnline;
@property (readonly) HDHomeRunTuner * tuner0;
@property (readonly) HDHomeRunTuner * tuner1;

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *)fetchHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext *)inMOC;

+ (HDHomeRun *)createHDHomeRunWithID:(NSNumber *)inDeviceID inManagedObjectContext:(NSManagedObjectContext *)inMOC;

- (HDHomeRunTuner *)tunerWithIndex:(int)index;

- (BOOL) upgradeFirmware;
@end

// coalesce these into one @interface HDHomeRun (CoreDataGeneratedAccessors) section
@interface HDHomeRun (CoreDataGeneratedAccessors)
- (void)addTunersObject:(HDHomeRunTuner *)value;
- (void)removeTunersObject:(HDHomeRunTuner *)value;
- (void)addTuners:(NSSet *)value;
- (void)removeTuners:(NSSet *)value;

@end
