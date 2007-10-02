//
//  Z2ITStation.h
//  recsched
//
//  Created by Andrew Kimpton on 1/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

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

@property (retain) NSString * affiliate;
@property (retain) NSString * callSign;
@property (retain) NSNumber * fccChannelNumber;
@property (retain) NSString * name;
@property (retain) NSNumber * stationID;
@property (retain) NSSet* hdhrStations;
@property (retain) NSSet* lineupMaps;
@property (retain) NSSet* schedules;

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
