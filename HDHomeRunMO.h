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

@interface HDHomeRun : NSManagedObject {
  struct hdhomerun_device_t *mHDHomeRunDevice;
}

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *) fetchHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

+ (HDHomeRun *) createHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

- (NSNumber *)deviceID;
- (void)setDeviceID:(NSNumber *)value;
- (NSString *)name;
- (void)setName:(NSString*)value;

- (void) addTuner:(HDHomeRunTuner *)aTuner;

- (HDHomeRunTuner*) tuner0;
//- (void)setTuner0:(HDHomeRunTuner*) value;

- (HDHomeRunTuner*) tuner1;
//- (void)setTuner1:(HDHomeRunTuner*) value;
@end
