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
#import "HDHomeRunTuner.h"

@implementation Z2ITStation

+ (Z2ITStation *) fetchStationWithID:(NSNumber*)inStationID inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  Z2ITStation *aStation;
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stationID == %@", inStationID];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stationID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
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
    if ([array count] > 1)
      NSLog(@"fetchStationWithID - multiple (%d) station with ID %@", [array count], inStationID);
    return aStation;
  }
}

+ (Z2ITStation *) fetchStationWithCallSign:(NSString*)callSignString inLineup:(Z2ITLineup*)inLineup inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  Z2ITStation *aStation = nil;
  
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callSign LIKE %@", callSignString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stationID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find station with callsign %@", callSignString);
      return nil;
  }
  if ([array count] == 0)
  {
    NSLog(@"No Stations with callSign %@ found", callSignString);
    return nil;
  }
  else
  {
    aStation = [array objectAtIndex:0];
  }
  return aStation;
}

- (BOOL) hasValidTunerForLineup:(Z2ITLineup*)aLineup
{
	BOOL validTuner = NO;
	
	if ([[self hdhrStations] count] > 0)
	{
		NSEnumerator *anEnumerator = [[self hdhrStations] objectEnumerator];
		HDHomeRunStation *aStation;
		while (((aStation = [anEnumerator nextObject]) != nil) && (validTuner == NO))
		{
			if ([[[aStation channel] tuner] lineup] == aLineup)
			{
				validTuner = YES;
			}
		}
	}
	return validTuner;
}

- (BOOL)addScheduleIfNew:(Z2ITSchedule*)value
{
  // The station might already have something scheduled in the same time or this is a replacement for
  // an existing program on the station. We need to search through the schedules and remove any schedule
  // that conflicts with this one.
  NSManagedObjectContext *moc = [self managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"station == %@ AND (((%@ >= time) AND (%@ < endTime)) OR ((%@ > time) AND (%@ <= endTime)))",
	self, [value time], [value time], [value endTime], [value endTime]];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array;
  @try {
	array = [moc executeFetchRequest:request error:&error];
  }
  @catch (NSException * e) {
	  NSLog(@"addSchedule exception occurred finding overlapping schedules %@", e);
  }
  @finally {
	  if (array == nil)
	  {
		NSLog(@"addSchedule - error executing request %@", request);
	  }
  }

  if ([array count] > 0)
  {
	// There are duplicate schedules on this channel - drop them
	for (Z2ITSchedule *aSchedule in array)
	{
		if ([aSchedule program] == [value program])
		{
			// Program's for both the new and existing schedule are the same - this might be a complete duplicate
			if (([[aSchedule time] compare:[value time]] == NSOrderedSame) && ([[aSchedule endTime] compare:[value endTime]] == NSOrderedSame))
			{
				// Duplicate schedule - we might want to update the other schedule details (in case they've changed)
				// but for now we'll just ignore the new one
				return NO;
			}
		}

		NSLog(@"Dropping overlapping schedule %@ overlaps with %@ on station %@", aSchedule, value, self);
		[moc deleteObject:aSchedule];
	}
  }

  NSMutableSet *schedules = [self mutableSetValueForKey:@"schedules"];
  [value setStation:self];
  [schedules addObject:value];
  return YES;
}

- (Z2ITLineupMap*)lineupMapForLineupID:(NSString*) inLineupID
{
  NSSet *lineupMaps = [self lineupMaps];
  Z2ITLineupMap *aLineupMap = nil;
  for (aLineupMap in lineupMaps)
  {
    if ([[[aLineupMap lineup] lineupID] compare:inLineupID] == NSOrderedSame)
      break;
  }
  return aLineupMap;
}

- (NSString *)channelStringForLineup:(Z2ITLineup*) inLineup
{
	NSString *channelString = nil;
	for (Z2ITLineupMap* aLineupMap in [self lineupMaps])
	{
		if ([aLineupMap.lineup.lineupID compare:inLineup.lineupID] == NSOrderedSame)
		{
			if ([aLineupMap.channelMinor intValue] > 0)
				channelString = [NSString stringWithFormat:@"%@.%@", aLineupMap.channel, aLineupMap.channelMinor];
			else
				channelString = aLineupMap.channel;
			break;
		}
	}
	return channelString;
}


@dynamic affiliate;
@dynamic callSign;
@dynamic fccChannelNumber;
@dynamic name;
@dynamic stationID;
@dynamic hdhrStations;
@dynamic lineupMaps;
@dynamic schedules;

- (Z2ITSchedule*)scheduleAtTime:(CFAbsoluteTime) inAirTime
{
  NSDate *airDate = [NSDate dateWithTimeIntervalSinceReferenceDate:inAirTime];

  NSManagedObjectContext *moc = [self managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(station == %@) AND (%@ >= time) AND (%@ < endTime)", self, airDate, airDate];
  [request setPredicate:predicate];
   
//  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
//  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];

  Z2ITSchedule *aSchedule =nil;
  if ([array count] > 0)
    aSchedule = [array objectAtIndex:0];
  if ([array count] > 1)
    NSLog(@"scheduleAtTime - %d schedules at time %@ for station %@", [array count], airDate, [self callSign]);
  return aSchedule;
}

- (Z2ITProgram*)programAtTime:(CFAbsoluteTime) inAirTime
{
  Z2ITSchedule *aSchedule = [self scheduleAtTime:inAirTime];

  return [aSchedule program];
}

- (NSArray *)schedulesBetweenStartTime:(CFAbsoluteTime) inStartTime andEndTime:(CFAbsoluteTime) inEndTime
{
  NSDate *startDate = [NSDate dateWithTimeIntervalSinceReferenceDate:inStartTime];
  NSDate *endDate = [NSDate dateWithTimeIntervalSinceReferenceDate:inEndTime];

  NSManagedObjectContext *moc = [self managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  // Find all programs (schedules) on this station which are on the air between the two times, 
  // this includes programs starting before the given inStartTime but end after the given inStartTime,
  // as well as all programs with start times between the two input values
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((station == %@) AND (time >= %@) AND (time <= %@)) OR ((station == %@) AND (time < %@) AND (endTime > %@))", self, startDate, endDate, self, startDate, startDate];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];

  return array;
}

@end
