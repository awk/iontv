//
//  Z2ITLineup.h
//  recsched
//
//  Created by Andrew Kimpton on 1/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Z2ITLineupMap;

@interface Z2ITLineup : NSManagedObject {

}

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITLineup *) fetchLineupWithID:(NSString*)inLineupID;

// Fetch the lineup map for the given station ID from the relationships in this Lineup
- (Z2ITLineupMap *) fetchLineupMapWithStationID:(NSNumber*)inStationID;

// Add the lineup map to this lineups relationships
- (void) addLineupMap:(Z2ITLineupMap *)aLineupMap;

// Return an array of all the stations in this lineup
- (NSArray *)stations;

// Accessor and mutator for the Lineup ID attribute
- (NSString *)lineupID;
- (void)setLineupID:(NSString *)value;

// Accessor and mutator for the device attribute
- (NSString *)device;
- (void)setDevice:(NSString *)value;

// Accessor and mutator for the location attribute
- (NSString *)location;
- (void)setLocation:(NSString *)value;

// Accessor and mutator for the name attribute
- (NSString *)name;
- (void)setName:(NSString *)value;

// Accessor and mutator for the postal code attribute
- (NSString *)postalCode;
- (void)setPostalCode:(NSString *)value;

// Accessor and mutator for the type attribute
- (NSString *)type;
- (void)setType:(NSString *)value;

// Accessor and mutator for the user lineup name attribute
- (NSString *)userLineupName;
- (void)setUserLineupName:(NSString *)value;
@end
