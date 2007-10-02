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

@interface Z2ITStation : NSManagedObject {

}

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITStation *) fetchStationWithID:(NSNumber*)inStationID;

// Accessor and mutator for the Station ID attribute
- (NSNumber *)stationID;
- (void)setStationID:(NSNumber *)value;

// Accessor and mutator for the call sign attribute
- (NSString *)callSign;
- (void)setCallSign:(NSString *)value;

// Accessor and mutator for the name attribute
- (NSString *)name;
- (void)setName:(NSString *)value;

// Accessor and mutator for the affiliate attribute
- (NSString *)affiliate;
- (void)setAffiliate:(NSString *)value;

// Accessor and mutator for the FCC Channel Number attribute
- (NSNumber *)fccChannelNumber;
- (void)setFccChannelNumber:(NSNumber *)value;

// Accessor and mutator for the schedules relationship
- (NSSet*)schedules;
- (void)addSchedule:(Z2ITSchedule*)value;

// Accessor and mutator for the lineupMap relationship
- (NSSet*)lineupMaps;
- (void)addLineupMap:(Z2ITLineupMap*)value;
- (Z2ITLineupMap*)lineupMapAtIndex:(unsigned) index;
- (Z2ITLineupMap*)lineupMapForLineupID:(NSString*) inLineupID;
@end
