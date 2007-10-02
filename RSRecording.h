//
//  RSRecording.h
//  recsched
//
//  Created by Andrew Kimpton on 9/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITSchedule;

enum {
    RSRecordingNoStatus			=  0
};

@interface RSRecording : NSManagedObject {

}

@property (retain) NSString * mediaFile;
@property (retain) NSNumber * status;
@property (retain) Z2ITSchedule * schedule;

+ (void) createRecordingOfSchedule:(Z2ITSchedule*)aSchedule withServer:(id)recServer;
+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC;

@end

// coalesce these into one @interface RSRecording (CoreDataGeneratedAccessors) section
@interface RSRecording (CoreDataGeneratedAccessors)
@end
