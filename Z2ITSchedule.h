//
//  Z2ITSchedule.h
//  recsched
//
//  Created by Andrew Kimpton on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Z2ITProgram;
@class Z2ITStation;

@interface Z2ITSchedule : NSManagedObject {

}

+ (void) clearAllSchedulesInManagedObjectContext:(NSManagedObjectContext *)inMOC;

- (void) setDurationHours:(int)inHours minutes:(int)inMinutes;

@property (retain) NSNumber * closeCaptioned;
@property (retain) NSString * dolby;
@property (retain) NSDate * endTime;
@property (retain) NSNumber * hdtv;
@property (retain) NSNumber * new;
@property (retain) NSNumber * partNumber;
@property (retain) NSString * recordedMediaPath;
@property (retain) NSNumber * recordingStatus;
@property (retain) NSNumber * stereo;
@property (retain) NSNumber * subtitled;
@property (retain) NSDate * time;
@property (retain) NSNumber * toBeRecorded;
@property (retain) NSNumber * totalNumberParts;
@property (retain) NSString * tvRating;
@property (retain) Z2ITProgram * program;
@property (retain) Z2ITStation * station;

- (NSString *) programDetailsStr;
- (NSString *) tvRatingImageName;

@end

// coalesce these into one @interface Z2ITSchedule (CoreDataGeneratedAccessors) section
@interface Z2ITSchedule (CoreDataGeneratedAccessors)
@end
