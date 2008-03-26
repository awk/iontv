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

#import "Z2ITStation.h"
#import "Z2ITSchedule.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"
#import "Z2ITProgram.h"
#import "HDHomeRunTuner.h"

@implementation Z2ITStation

+ (Z2ITStation *) fetchStationWithID:(NSNumber*)inStationID inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  Z2ITStation *aStation;
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];
   
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
    return aStation;
  }
}

+ (Z2ITStation *) fetchStationWithCallSign:(NSString*)callSignString inLineup:(Z2ITLineup*)inLineup inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  Z2ITStation *aStation = nil;
  
  // Create a 'non punctuated' form of the station callsign
  NSCharacterSet *punctuation = [NSCharacterSet characterSetWithCharactersInString:@"- "];
  NSMutableString *plainCallSignString = [NSMutableString stringWithString:callSignString];
  NSRange r = [plainCallSignString rangeOfCharacterFromSet:punctuation];
  while (r.location != NSNotFound)
  {
    [plainCallSignString deleteCharactersInRange:r];
    r = [plainCallSignString rangeOfCharacterFromSet:punctuation];
  }
  
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callSign == %@", plainCallSignString];
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
    return nil;
  }
  else
  {
    return [array objectAtIndex:0];
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
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"station == %@ AND (((time >= %@) AND (time < %@)) OR ((endTime > %@) and (endTime <= %@)))",
	self, [value time], [value endTime], [value time], [value endTime]];
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
				// Complete duplicate schedule times & the programs match - ignore it.
				return NO;
			}
		}

//		NSLog(@"Dropping overlapping schedule for program %@ - %@ on Station %@, %@ to %@ overlaps with program %@ - %@, %@ to %@", 
//			aSchedule.program.title, aSchedule.program.subTitle ? aSchedule.program.subTitle : @"", self.callSign, aSchedule.time, aSchedule.endTime,
//			value.program.title, value.program.subTitle ? value.program.subTitle : @"", value.time, value.endTime);
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
  [request setFetchLimit:1];
  
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
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(station == %@) AND (((time >= %@) AND (time <= %@)) OR ((endTime >= %@) AND (endTime <= %@)) OR ((time <= %@) AND (endTime >= %@)))", 
    self, 
    startDate, endDate, 
    startDate, endDate,
    startDate, endDate];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];

  return array;
}

@end
