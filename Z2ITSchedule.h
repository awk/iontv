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

// Accessor and mutator for the Program relationship
- (Z2ITProgram *)program;
- (void)setProgram:(Z2ITProgram *)value;

// Accessor and mutator for the station relationship
- (Z2ITStation *)station;
- (void)setStation:(Z2ITStation *)value;

// Accessor and mutator for the close captioned attribute
- (bool)closeCaptioned;
- (void)setCloseCaptioned:(bool)value;

// Accessor and mutator for the dolby attribute
- (NSString *)dolby;
- (void)setDolby:(NSString *)value;

// Accessor and mutator for the close captioned attribute
- (bool)hdtv;
- (void)setHdtv:(bool)value;

// Accessor and mutator for the user lineup name attribute
- (NSNumber *)partNumber;
- (void)setPartNumber:(NSNumber *)value;

// Accessor and mutator for the user lineup name attribute
- (NSNumber *)totalNumberParts;
- (void)setTotalNumberParts:(NSNumber *)value;

// Accessor and mutator for the close captioned attribute
- (bool)repeat;
- (void)setRepeat:(bool)value;

// Accessor and mutator for the close captioned attribute
- (bool)stereo;
- (void)setStereo:(bool)value;

// Accessor and mutator for the close captioned attribute
- (bool)subtitled;
- (void)setSubtitled:(bool)value;

// Accessor and mutator for the (start) time attribute
- (NSDate *)time;
- (void)setTime:(NSDate*)value;

// Accessor and mutator for the end time attribute
- (NSDate *)endTime;
- (void)setEndTime:(NSDate*)value;

// Accessor and mutator for the to be recorded attribute
- (bool)toBeRecorded;
- (void)setToBeRecorded:(bool)value;

// Accessor and mutator for the TV Rating attribute
- (NSString *)tvRating;
- (void)setTvRating:(NSString *)value;
- (NSString *) tvRatingImageName;

- (NSString *) programDetailsStr;
@end
