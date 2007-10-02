//
//  HDHomeRun.h
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HDHomeRunTuner;

@interface HDHomeRun : NSManagedObject {

}

// Fetch the HDHomeRun with the given ID from the Managed Object Context
+ (HDHomeRun *) fetchHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

+ (HDHomeRun *) createHDHomeRunWithID:(NSNumber*)inDeviceID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

- (void) addTuner:(HDHomeRunTuner *)aTuner;

- (NSNumber *)deviceID;
- (void)setDeviceID:(NSNumber *)value;

@end
