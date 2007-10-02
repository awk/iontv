//
//  Z2ITLineup.m
//  recsched
//
//  Created by Andrew Kimpton on 1/17/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"

@implementation Z2ITLineup

// Fetch the station with the given ID from the Managed Object Context
+ (Z2ITLineup *) fetchLineupWithID:(NSString*)inLineupID inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lineup" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lineupID == %@", inLineupID];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lineupID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find lineup with ID %@", inLineupID);
      return nil;
  }
  if ([array count] == 1)
  {
    Z2ITLineup *aLineup = [array objectAtIndex:0];
    [aLineup retain];
    return aLineup;
  }
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchLineupWithID - multiple (%d) lineups with ID %@", [array count], inLineupID);
      return nil;
  }
}

- (Z2ITLineupMap *) fetchLineupMapWithStationID:(NSNumber*)inStationID
{
  NSMutableSet *lineupMaps = [self mutableSetValueForKeyPath:@"lineupMaps"];
  
  // Iterate over the set to find a lineup map which refers to the matching station ID
  NSEnumerator *mapEnumerator = [lineupMaps objectEnumerator];
  Z2ITLineupMap *aLineupMap, *foundLineupMap = nil;
  
  while ((aLineupMap = [mapEnumerator nextObject]) && (foundLineupMap == nil))
  {
    Z2ITStation *aStation = [aLineupMap valueForKey:@"station"];
    if ([[aStation stationID] compare:inStationID] == NSOrderedSame)
      foundLineupMap = aLineupMap;
  }

  return foundLineupMap;
}

- (NSArray *)stations
{
  NSMutableSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  Z2ITLineupMap *aLineupMap;
  NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:[lineupMaps count]];
  for (aLineupMap in lineupMaps)
  {
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
@dynamic tuners;

@end
