//
//  Z2ITSchedule.m
//  recsched
//
//  Created by Andrew Kimpton on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITSchedule.h"
#import "CoreData_Macros.h"

@implementation Z2ITSchedule

- (void) setDurationHours:(int)inHours minutes:(int)inMinutes
{
  NSDate *startDate = [self time];
  if (startDate == nil)
    NSLog(@"setDuration - no valid start time for program %@", [[self program] title]);
  NSDate *endDate = [self endTime];
  if (endDate != nil)
    NSLog(@"setDuration - program %@ already has an end time", [[self program] title]);
  
  endDate = [startDate addTimeInterval:(inHours * 60 * 60) + (inMinutes * 60)];
  [self setEndTime:endDate];
}

// Accessor and mutator for the Program relationship
- (Z2ITProgram*)program 
{
COREDATA_ACCESSOR(Z2ITProgram*, @"program")
}

- (void) setProgram:(Z2ITProgram*) value
{
COREDATA_MUTATOR(Z2ITProgram*, @"program")
}

// Accessor and mutator for the station relationship
- (Z2ITStation *)station
{
COREDATA_ACCESSOR(Z2ITStation*, @"station");
}

- (void)setStation:(Z2ITStation *)value
{
COREDATA_MUTATOR(Z2ITStation*, @"station");
}

// Accessor and mutator for the close captioned attribute
- (bool)closeCaptioned
{
COREDATA_BOOL_ACCESSOR(@"closeCaptioned")
}

- (void)setCloseCaptioned:(bool)value
{
COREDATA_BOOL_MUTATOR(@"closeCaptioned")
}

// Accessor and mutator for the dolby attribute
- (NSString *)dolby
{
COREDATA_ACCESSOR(NSString*, @"dolby")
}

- (void)setDolby:(NSString *)value
{
COREDATA_MUTATOR(NSString*, @"dolby")
}

// Accessor and mutator for the type attribute
- (NSNumber *)durationHours
{
COREDATA_ACCESSOR(NSNumber*, @"durationHours")
}

- (void)setDurationHours:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*, @"durationHours")
}


// Accessor and mutator for the user lineup name attribute
- (NSNumber *)durationMinutes
{
COREDATA_ACCESSOR(NSNumber*, @"durationMinutes")
}

- (void)setDurationMinutes:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*, @"durationMinutes")
}



// Accessor and mutator for the close captioned attribute
- (bool)hdtv
{
COREDATA_BOOL_ACCESSOR(@"hdtv")
}

- (void)setHdtv:(bool)value
{
COREDATA_BOOL_MUTATOR(@"hdtv")
}


// Accessor and mutator for the user lineup name attribute
- (NSNumber *)partNumber
{
COREDATA_ACCESSOR(NSNumber*, @"partNumber")
}

- (void)setPartNumber:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*, @"partNumber")
}

// Accessor and mutator for the user lineup name attribute
- (NSNumber *)totalNumberParts
{
COREDATA_ACCESSOR(NSNumber*, @"totalNumberParts")
}

- (void)setTotalNumberParts:(NSNumber *)value;
{
COREDATA_MUTATOR(NSNumber*, @"totalNumberParts")
}

// Accessor and mutator for the close captioned attribute
- (bool)repeat
{
COREDATA_BOOL_ACCESSOR(@"repeat")
}

- (void)setRepeat:(bool)value
{
COREDATA_BOOL_MUTATOR(@"repeat")
}

// Accessor and mutator for the close captioned attribute
- (bool)stereo
{
COREDATA_BOOL_ACCESSOR(@"stereo")
}

- (void)setStereo:(bool)value
{
COREDATA_BOOL_MUTATOR(@"stereo")
}

// Accessor and mutator for the close captioned attribute
- (bool)subtitled
{
COREDATA_BOOL_ACCESSOR(@"subtitled")
}

- (void)setSubtitled:(bool)value
{
COREDATA_BOOL_MUTATOR(@"subtitled")
}

// Accessor and mutator for the close captioned attribute
- (NSDate *)time
{
COREDATA_ACCESSOR(NSDate*, @"time")
}

- (void)setTime:(NSDate*)value
{
COREDATA_MUTATOR(NSDate*, @"time")
}

- (NSDate *)endTime
{
COREDATA_ACCESSOR(NSDate*, @"endTime");
}

- (void) setEndTime:(NSDate*)value
{
COREDATA_MUTATOR(NSDate*, @"endTime");
}

// Accessor and mutator for the dolby attribute
- (NSString *)tvRating
{
COREDATA_ACCESSOR(NSString*, @"tvRating")
}

- (void)setTvRating:(NSString *)value
{
COREDATA_MUTATOR(NSString*, @"tvRating")
}

@end
