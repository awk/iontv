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

#import <CoreData/CoreData.h>

@class Z2ITProgram;
@class Z2ITStation;
@class RSRecording;
@class RSTranscoding;

@interface Z2ITSchedule : NSManagedObject {

}

+ (void)clearAllSchedulesInManagedObjectContext:(NSManagedObjectContext *)inMOC;
+ (Z2ITSchedule *)fetchScheduleWithLatestStartDateInMOC:(NSManagedObjectContext *)inMOC;
- (void)setDurationHours:(int)inHours minutes:(int)inMinutes;
- (BOOL)overlapsWith:(Z2ITSchedule *)anotherSchedule;

@property (retain) NSNumber * closeCaptioned;
@property (retain) NSString * dolby;
@property (retain) NSDate * endTime;
@property (retain) NSNumber * hdtv;
@property (retain, getter=newProgram, setter=setNewProgram:) NSNumber * new;
@property (retain) NSNumber * partNumber;
@property (retain) NSString * recordedMediaPath;
@property (retain) NSNumber * recordingStatus;
@property (retain) NSNumber * stereo;
@property (retain) NSNumber * subtitled;
@property (retain) NSDate * time;
@property (retain) NSNumber * totalNumberParts;
@property (retain) NSString * tvRating;
@property (retain) Z2ITProgram * program;
@property (retain) Z2ITStation * station;
@property (retain) RSRecording * recording;
@property (retain) RSTranscoding * transcoding;

- (NSString *)programDetailsStr;
- (NSString *)tvRatingImageName;

@end

// coalesce these into one @interface Z2ITSchedule (CoreDataGeneratedAccessors) section
@interface Z2ITSchedule (CoreDataGeneratedAccessors)
@end
