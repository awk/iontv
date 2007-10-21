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
	RSRecordingNotYetStartedStatus = 0,
	RSRecordingInProgressStatus = 1,
	RSRecordingFinishedStatus = 2,
	RSRecordingErrorStatus = 3,
};

@interface RSRecording : NSManagedObject {

}

@property (retain) NSString * mediaFile;
@property (retain) NSNumber * status;
@property (retain) Z2ITSchedule * schedule;

+ (RSRecording*) insertRecordingOfSchedule:(Z2ITSchedule*)aSchedule;
+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC afterDate:(NSDate*)date; 
+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC beforeDate:(NSDate*)date; 

@end

// coalesce these into one @interface RSRecording (CoreDataGeneratedAccessors) section
@interface RSRecording (CoreDataGeneratedAccessors)
@end
