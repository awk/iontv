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

@class Z2ITSchedule;
@class Z2ITLineupMap;
@class Z2ITProgram;
@class Z2ITLineup;
@class HDHomeRunStation;

@interface Z2ITStation : NSManagedObject {

}

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITStation *) fetchStationWithID:(NSNumber*)inStationID inManagedObjectContext:(NSManagedObjectContext *)inMOC;
+ (Z2ITStation *) fetchStationWithCallSign:(NSString*)callSignString inLineup:(Z2ITLineup*)inLineup inManagedObjectContext:(NSManagedObjectContext*)inMOC;

// Fetch the program object for the program on air at the specified time
- (Z2ITProgram*)programAtTime:(CFAbsoluteTime) inAirTime;
- (Z2ITSchedule*)scheduleAtTime:(CFAbsoluteTime) inAirTime;
- (NSArray *)schedulesBetweenStartTime:(CFAbsoluteTime) inStartTime andEndTime:(CFAbsoluteTime) inEndTime;

// Is there a valid tuner for this station and lineup ?
- (BOOL) hasValidTunerForLineup:(Z2ITLineup*)aLineup;

- (BOOL)addScheduleIfNew:(Z2ITSchedule*)value;

- (Z2ITLineupMap*)lineupMapForLineupID:(NSString*) inLineupID;
- (NSString *)channelStringForLineup:(Z2ITLineup*) inLineup;

@property (retain) NSString * affiliate;
@property (retain) NSString * callSign;
@property (retain) NSNumber * fccChannelNumber;
@property (retain) NSString * name;
@property (retain) NSNumber * stationID;
@property (retain) NSSet* hdhrStations;
@property (retain) NSSet* lineupMaps;
@property (retain) NSSet* schedules;
@property (retain) NSSet* seasonPasses;

@end

// coalesce these into one @interface Z2ITStation (CoreDataGeneratedAccessors) section
@interface Z2ITStation (CoreDataGeneratedAccessors)
- (void)addHdhrStationsObject:(HDHomeRunStation *)value;
- (void)removeHdhrStationsObject:(HDHomeRunStation *)value;
- (void)addHdhrStations:(NSSet *)value;
- (void)removeHdhrStations:(NSSet *)value;

- (void)addLineupMapsObject:(Z2ITLineupMap *)value;
- (void)removeLineupMapsObject:(Z2ITLineupMap *)value;
- (void)addLineupMaps:(NSSet *)value;
- (void)removeLineupMaps:(NSSet *)value;

- (void)addSchedulesObject:(Z2ITSchedule *)value;
- (void)removeSchedulesObject:(Z2ITSchedule *)value;
- (void)addSchedules:(NSSet *)value;
- (void)removeSchedules:(NSSet *)value;

@end
