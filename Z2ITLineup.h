//
//  Z2ITLineup.h
//  recsched
//
//  Created by Andrew Kimpton on 1/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Z2ITLineupMap;
@class HDHomeRunTuner;

@interface Z2ITLineup : NSManagedObject {

}

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITLineup *) fetchLineupWithID:(NSString*)inLineupID inManagedObjectContext:(NSManagedObjectContext*)inMOC;

// Fetch the lineup map for the given station ID from the relationships in this Lineup
- (Z2ITLineupMap *) fetchLineupMapWithStationID:(NSNumber*)inStationID;

// Return an array of all the stations in this lineup
- (NSArray *)stations;

@property (retain) NSString * device;
@property (retain) NSString * lineupID;
@property (retain) NSString * location;
@property (retain) NSString * name;
@property (retain) NSString * postalCode;
@property (retain) NSString * type;
@property (retain) NSString * userLineupName;
@property (retain) NSSet* lineupMaps;
@property (retain) NSSet* tuners;

@end

// coalesce these into one @interface Z2ITLineup (CoreDataGeneratedAccessors) section
@interface Z2ITLineup (CoreDataGeneratedAccessors)
- (void)addLineupMapsObject:(Z2ITLineupMap *)value;
- (void)removeLineupMapsObject:(Z2ITLineupMap *)value;
- (void)addLineupMaps:(NSSet *)value;
- (void)removeLineupMaps:(NSSet *)value;

- (void)addTunersObject:(HDHomeRunTuner *)value;
- (void)removeTunersObject:(HDHomeRunTuner *)value;
- (void)addTuners:(NSSet *)value;
- (void)removeTuners:(NSSet *)value;

@end
