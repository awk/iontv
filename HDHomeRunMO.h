//
//  HDHomeRun.h
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "hdhomerun_os.h"
#import "hdhomerun_debug.h"       // Fixes warning from undefined type in device header
#import "hdhomerun_device.h"

extern const int kDefaultPortNumber;

@class HDHomeRunTuner;

@interface HDHomeRun : NSManagedObject
{
  struct hdhomerun_device_t *mHDHomeRunDevice;
}

@property (retain) NSNumber * deviceID;
@property (retain) NSString * name;
@property (retain) NSSet* tuners;

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *) fetchHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

+ (HDHomeRun *) createHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

- (HDHomeRunTuner*) tuner0;
- (HDHomeRunTuner*) tuner1;
@end

// coalesce these into one @interface HDHomeRun (CoreDataGeneratedAccessors) section
@interface HDHomeRun (CoreDataGeneratedAccessors)
- (void)addTunersObject:(HDHomeRunTuner *)value;
- (void)removeTunersObject:(HDHomeRunTuner *)value;
- (void)addTuners:(NSSet *)value;
- (void)removeTuners:(NSSet *)value;

@end
