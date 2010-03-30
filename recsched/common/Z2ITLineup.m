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

#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"

@implementation Z2ITLineup

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITLineup *)allocLineupWithID:(NSString *)inLineupID inManagedObjectContext:(NSManagedObjectContext *)inMOC {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lineup" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];

  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lineupID == %@", inLineupID];
  [request setPredicate:predicate];

  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lineupID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil) {
      NSLog(@"Error executing fetch request to find lineup with ID %@", inLineupID);
      return nil;
  }
  if ([array count] == 1) {
    Z2ITLineup *aLineup = [array objectAtIndex:0];
    [aLineup retain];
    return aLineup;
  } else {
      return nil;
  }
}

- (Z2ITLineupMap *)fetchLineupMapWithStationID:(NSNumber *)inStationID {
  NSMutableSet *lineupMaps = [self mutableSetValueForKeyPath:@"lineupMaps"];

  // Iterate over the set to find a lineup map which refers to the matching station ID
  NSEnumerator *mapEnumerator = [lineupMaps objectEnumerator];
  Z2ITLineupMap *aLineupMap, *foundLineupMap = nil;

  while ((aLineupMap = [mapEnumerator nextObject]) && (foundLineupMap == nil)) {
    Z2ITStation *aStation = [aLineupMap valueForKey:@"station"];
    if ([[aStation stationID] compare:inStationID] == NSOrderedSame) {
      foundLineupMap = aLineupMap;
    }
  }

  return foundLineupMap;
}

- (NSArray *)stations {
  NSMutableSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  Z2ITLineupMap *aLineupMap;
  NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:[lineupMaps count]];
  for (aLineupMap in lineupMaps) {
    [stationsArray addObject:[aLineupMap station]];
  }
  return stationsArray;
}

@dynamic device;
@dynamic lineupID;
@dynamic location;
@dynamic name;
@dynamic postalCode;
@dynamic type;
@dynamic userLineupName;
@dynamic lineupMaps;
@dynamic channelStationMap;
@dynamic tuners;

@end
