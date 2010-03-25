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

@class Z2ITLineupMap;
@class HDHomeRunChannelStationMap;

@interface Z2ITLineup : NSManagedObject {

}

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITLineup *)fetchLineupWithID:(NSString *)inLineupID inManagedObjectContext:(NSManagedObjectContext *)inMOC;

// Fetch the lineup map for the given station ID from the relationships in this Lineup
- (Z2ITLineupMap *)fetchLineupMapWithStationID:(NSNumber *)inStationID;

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
@property (retain) HDHomeRunChannelStationMap * channelStationMap;
@property (retain) NSSet* tuners;

@end

// coalesce these into one @interface Z2ITLineup (CoreDataGeneratedAccessors) section
@interface Z2ITLineup (CoreDataGeneratedAccessors)
- (void)addLineupMapsObject:(Z2ITLineupMap *)value;
- (void)removeLineupMapsObject:(Z2ITLineupMap *)value;
- (void)addLineupMaps:(NSSet *)value;
- (void)removeLineupMaps:(NSSet *)value;

@end
