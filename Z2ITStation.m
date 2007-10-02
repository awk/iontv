//
//  Z2ITStation.m
//  recsched
//
//  Created by Andrew Kimpton on 1/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITStation.h"
#import "recsched_appDelegate.h"
#import "Z2ITSchedule.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"

@implementation Z2ITStation

static NSMutableDictionary *sStationsDictionary = nil;

+ (Z2ITStation *) fetchStationWithID:(NSNumber*)inStationID
{
  Z2ITStation *aStation;
  if (sStationsDictionary)
  {
    aStation = [sStationsDictionary valueForKey:[inStationID stringValue]];
    if (aStation)
      return aStation;
  }
  recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];

  NSManagedObjectContext *moc = [recschedAppDelegate managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stationID == %@", inStationID];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stationID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find station with ID %@", inStationID);
      return nil;
  }
  if ([array count] == 0)
  {
    return nil;
  }
  else
  {
    aStation = [array objectAtIndex:0];
    if (!sStationsDictionary)
      sStationsDictionary = [[NSMutableDictionary alloc] initWithCapacity:300];
    [sStationsDictionary setValue:aStation forKey:[inStationID stringValue]];
    if ([array count] > 1)
      NSLog(@"fetchStationWithID - multiple (%d) station with ID %@", [array count], inStationID);
    return aStation;
  }
}

#pragma mark
#pragma mark Core Data accessors/mutators/validation methods
#pragma mark


// Accessor and mutator for the Station ID attribute
- (NSNumber *)stationID
{
    NSNumber * tmpValue;
    
    [self willAccessValueForKey: @"stationID"];
    tmpValue = [self primitiveValueForKey: @"stationID"];
    [self didAccessValueForKey: @"stationID"];
    
    return tmpValue;
}

- (void)setStationID:(NSNumber *)value
{
    [self willChangeValueForKey: @"stationID"];
    [self setPrimitiveValue: value forKey: @"stationID"];
    [self didChangeValueForKey: @"stationID"];
}

// Accessor and mutator for the call sign attribute
- (NSString *)callSign
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"callSign"];
    tmpValue = [self primitiveValueForKey: @"callSign"];
    [self didAccessValueForKey: @"callSign"];
    
    return tmpValue;
}

- (void)setCallSign:(NSString *)value
{
    [self willChangeValueForKey: @"callSign"];
    [self setPrimitiveValue: value forKey: @"callSign"];
    [self didChangeValueForKey: @"callSign"];
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

- (void)setName:(NSString *)value
{
    [self willChangeValueForKey: @"name"];
    [self setPrimitiveValue: value forKey: @"name"];
    [self didChangeValueForKey: @"name"];
}

// Accessor and mutator for the affiliate attribute
- (NSString *)affiliate
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"affiliate"];
    tmpValue = [self primitiveValueForKey: @"affiliate"];
    [self didAccessValueForKey: @"affiliate"];
    
    return tmpValue;
}

- (void)setAffiliate:(NSString *)value
{
    [self willChangeValueForKey: @"affiliate"];
    [self setPrimitiveValue: value forKey: @"affiliate"];
    [self didChangeValueForKey: @"affiliate"];
}

// Accessor and mutator for the FCC Channel Number attribute
- (NSNumber *)fccChannelNumber{
    NSNumber * tmpValue;
    
    [self willAccessValueForKey: @"fccChannelNumber"];
    tmpValue = [self primitiveValueForKey: @"fccChannelNumber"];
    [self didAccessValueForKey: @"fccChannelNumber"];
    
    return tmpValue;
}

- (void)setFccChannelNumber:(NSNumber *)value
{
    [self willChangeValueForKey: @"fccChannelNumber"];
    [self setPrimitiveValue: value forKey: @"fccChannelNumber"];
    [self didChangeValueForKey: @"fccChannelNumber"];
}

- (NSSet*)schedules
{
  NSSet *schedules = [self mutableSetValueForKey:@"schedules"];
  return schedules;
}

- (void)addSchedule:(Z2ITSchedule*)value
{
  NSMutableSet *schedules = [self mutableSetValueForKey:@"schedules"];
  [value setStation:self];
  [schedules addObject:value];
}

- (NSSet*)lineupMaps
{
  NSSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  return lineupMaps;
}

- (void)addLineupMap:(Z2ITLineupMap*)value
{
  NSMutableSet *lineupMaps = [self mutableSetValueForKey:@"lineupMaps"];
  if (![lineupMaps containsObject:value])
    [lineupMaps addObject:value];
}

- (Z2ITLineupMap*)lineupMapAtIndex:(unsigned) index
{
  NSArray *lineupMapArray = [[self lineupMaps] allObjects];
  return [lineupMapArray objectAtIndex:index];
}

- (Z2ITLineupMap*)lineupMapForLineupID:(NSString*) inLineupID
{
  NSSet *lineupMaps = [self lineupMaps];
  NSEnumerator *lineupEnumerator = [lineupMaps objectEnumerator];
  Z2ITLineupMap *aLineupMap = nil;
  while (aLineupMap = [lineupEnumerator nextObject])
  {
    if ([[[aLineupMap lineup] lineupID] compare:inLineupID] == NSOrderedSame)
      break;
  }
  return aLineupMap;
}
@end
