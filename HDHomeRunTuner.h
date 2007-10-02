//
//  HDHomeRunTuner.h
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HDHomeRun;
@class Z2ITLineup;

@interface HDHomeRunTuner : NSManagedObject {

}

- (NSNumber *) index;
- (void) setIndex:(NSNumber*)value;
- (HDHomeRun*) device;
- (void) setDevice:(HDHomeRun *)value;

- (Z2ITLineup*)lineup;
- (void) setLineup:(Z2ITLineup*)value;
@end
