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

- (void) addLineupMap:(Z2ITLineupMap *)aLineupMap
{
  NSMutableSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  [aLineupMap setLineup:self];
  [lineupMaps addObject:aLineupMap];
}

- (NSArray *)stations
{
  NSMutableSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  NSEnumerator *lineupMapEnumerator = [lineupMaps objectEnumerator];
  Z2ITLineupMap *aLineupMap;
  NSMutableArray *stationsArray = [NSMutableArray arrayWithCapacity:[lineupMaps count]];
  while (aLineupMap = [lineupMapEnumerator nextObject])
  {
    [stationsArray addObject:[aLineupMap station]];
  }
  return stationsArray;
}

#pragma mark
#pragma mark Core Data accessors/mutators/validation methods
#pragma mark



// Accessor and mutator for the Lineup ID attribute
- (NSString *)lineupID
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"lineupID"];
    tmpValue = [self primitiveValueForKey: @"lineupID"];
    [self didAccessValueForKey: @"lineupID"];
    
    return tmpValue;
}

- (void)setLineupID:(NSString *)value
{
    [self willChangeValueForKey: @"lineupID"];
    [self setPrimitiveValue: value forKey: @"lineupID"];
    [self didChangeValueForKey: @"lineupID"];
}

// Accessor and mutator for the device attribute
- (NSString *)device
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"device"];
    tmpValue = [self primitiveValueForKey: @"device"];
    [self didAccessValueForKey: @"device"];
    
    return tmpValue;
}

- (void)setDevice:(NSString *)value;
{
    [self willChangeValueForKey: @"device"];
    [self setPrimitiveValue: value forKey: @"device"];
    [self didChangeValueForKey: @"device"];
}

// Accessor and mutator for the location attribute
- (NSString *)location
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"location"];
    tmpValue = [self primitiveValueForKey: @"location"];
    [self didAccessValueForKey: @"location"];
    
    return tmpValue;
}

- (void)setLocation:(NSString *)value;
{
    [self willChangeValueForKey: @"location"];
    [self setPrimitiveValue: value forKey: @"location"];
    [self didChangeValueForKey: @"location"];
}

// Accessor and mutator for the name attribute
- (NSString *)name
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"name"];
    tmpValue = [self primitiveValueForKey: @"name"];
    [self didAccessValueForKey: @"name"];
    
    return tmpValue;
}

- (void)setName:(NSString *)value;
{
    [self willChangeValueForKey: @"name"];
    [self setPrimitiveValue: value forKey: @"name"];
    [self didChangeValueForKey: @"name"];
}

// Accessor and mutator for the postal code attribute
- (NSString *)postalCode
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"postalCode"];
    tmpValue = [self primitiveValueForKey: @"postalCode"];
    [self didAccessValueForKey: @"postalCode"];
    
    return tmpValue;
}

- (void)setPostalCode:(NSString *)value
{
    [self willChangeValueForKey: @"postalCode"];
    [self setPrimitiveValue: value forKey: @"postalCode"];
    [self didChangeValueForKey: @"postalCode"];
}

// Accessor and mutator for the type attribute
- (NSString *)type
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"type"];
    tmpValue = [self primitiveValueForKey: @"type"];
    [self didAccessValueForKey: @"type"];
    
    return tmpValue;
}

- (void)setType:(NSString *)value
{
    [self willChangeValueForKey: @"type"];
    [self setPrimitiveValue: value forKey: @"type"];
    [self didChangeValueForKey: @"type"];
}

// Accessor and mutator for the user lineup name attribute
- (NSString *)userLineupName
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"userLineupName"];
    tmpValue = [self primitiveValueForKey: @"userLineupName"];
    [self didAccessValueForKey: @"userLineupName"];
    
    return tmpValue;
}

- (void)setUserLineupName:(NSString *)value
{
    [self willChangeValueForKey: @"userLineupName"];
    [self setPrimitiveValue: value forKey: @"userLineupName"];
    [self didChangeValueForKey: @"userLineupName"];
}

@end
