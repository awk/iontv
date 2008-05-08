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

#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"
#import "RSColorDictionary.h"

@implementation Z2ITProgram

BOOL boolValueForAttribute(NSXMLElement *inXMLElement, NSString *inAttributeName)
{
  BOOL retValue = NO;
  
  NSString *tmpStr  = [[inXMLElement attributeForName:inAttributeName] stringValue];
  if (tmpStr)
  {
    if ([tmpStr compare:@"true"] == NSOrderedSame)
      retValue = YES;
  }
  return retValue;
}

// Fetch the Program with the given ID from the Managed Object Context
+ (Z2ITProgram *) fetchProgramWithID:(NSString*)inProgramID inManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Program" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"programID IN %@", [NSArray arrayWithObject:inProgramID]];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"programID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find program with ID %@", inProgramID);
      return nil;
  }
  if ([array count] == 1)
  {
    Z2ITProgram *aProgram = [array objectAtIndex:0];
    [aProgram retain];
    return aProgram;
  }
  else 
  {
      return nil;
  }
}

+ (NSArray *) fetchProgramsWithIDS:(NSArray*)inProgramIDS inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [fetchRequest setEntity:
          [NSEntityDescription entityForName:@"Program" inManagedObjectContext:inMOC]];
  [fetchRequest setPredicate: [NSPredicate predicateWithFormat: @"(programID IN %@)", inProgramIDS]];
   
  // make sure the results are sorted as well
  [fetchRequest setSortDescriptors: [NSArray arrayWithObject:
          [[[NSSortDescriptor alloc] initWithKey: @"programID"
                  ascending:YES] autorelease]]];
  // Execute the fetch
  NSError *error;
  NSArray *programsMatchingNames = [inMOC executeFetchRequest:fetchRequest error:&error];
  return programsMatchingNames;
}

- (void) addToSchedule:(Z2ITSchedule *)inSchedule
{
  [inSchedule setProgram:self];
  NSMutableSet *schedules = [self mutableSetValueForKey:@"schedules"];
  [schedules addObject:inSchedule];
}

- (void) initializeWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSArray *nodes;
  NSError *err;
  NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];    // A temporary pool 
  
  nodes = [inXMLElement nodesForXPath:@"./series" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theSeriesString = [[nodes objectAtIndex:0] stringValue];
        [self setSeries:theSeriesString];
  }
  
  nodes = [inXMLElement nodesForXPath:@"./title" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theTitleString = [[nodes objectAtIndex:0] stringValue];
        [self setTitle:theTitleString];
  }

  nodes = [inXMLElement nodesForXPath:@"./subtitle" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theSubtitleString = [[nodes objectAtIndex:0] stringValue];
        [self setSubTitle:theSubtitleString];
  }

  nodes = [inXMLElement nodesForXPath:@"./description" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theDescriptionString = [[nodes objectAtIndex:0] stringValue];
        [self setDescriptionStr:theDescriptionString];
  }

  nodes = [inXMLElement nodesForXPath:@"./mpaaRating" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theMPAARating = [[nodes objectAtIndex:0] stringValue];
        [self setMpaaRating:theMPAARating];
  }

  nodes = [inXMLElement nodesForXPath:@"./starRating" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *tmpStr = [[nodes objectAtIndex:0] stringValue];
        NSNumber *theStarRating;
        if ([tmpStr compare:@"+"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:0.5];
        if ([tmpStr compare:@"*"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:1.0];
        if ([tmpStr compare:@"*+"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:1.5];
        if ([tmpStr compare:@"**"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:2.0];
        if ([tmpStr compare:@"**+"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:2.5];
        if ([tmpStr compare:@"***"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:3.0];
        if ([tmpStr compare:@"***+"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:3.5];
        if ([tmpStr compare:@"****"] == NSOrderedSame)
          theStarRating = [NSNumber numberWithFloat:4.0];
        [self setStarRating:theStarRating];
  }

  nodes = [inXMLElement nodesForXPath:@"./runTime" error:&err];
  if ([nodes count] > 0 )
  {
        NSString *theRunTimeString = [[nodes objectAtIndex:0] stringValue];
        NSNumber *runTimeHours;
        NSString *rtHoursString = [theRunTimeString substringWithRange:NSMakeRange(2,2)];
        runTimeHours = [NSNumber numberWithInt:[rtHoursString intValue]];
        NSNumber *runTimeMins;
        NSString *rtMinsString = [theRunTimeString substringWithRange:NSMakeRange(5, 2)];
        runTimeMins = [NSNumber numberWithInt:[rtMinsString intValue]];
        [self setRunTimeHours:runTimeHours];
        [self setRunTimeMinutes:runTimeMins];
  }

  nodes = [inXMLElement nodesForXPath:@"./year" error:&err];
  if ([nodes count] > 0 )
  {
      [self setYear:[NSNumber numberWithInt:[[[nodes objectAtIndex:0] stringValue] intValue]]];
  }
  
  nodes = [inXMLElement nodesForXPath:@"./showType" error:&err];
  if ([nodes count] > 0 )
  {
    [self setShowType:[[nodes objectAtIndex:0] stringValue]];
  }

  nodes = [inXMLElement nodesForXPath:@"./colorCode" error:&err];
  if ([nodes count] > 0 )
  {
    [self setColorCode:[[nodes objectAtIndex:0] stringValue]];
  }

  nodes = [inXMLElement nodesForXPath:@"./originalAirDate" error:&err];
  if ([nodes count] > 0 )
  {
    NSString *origAirDateStr = [[nodes objectAtIndex:0] stringValue];
    NSDate *origAirDate = [NSDate dateWithNaturalLanguageString:origAirDateStr];
    [self setOriginalAirDate:origAirDate];
  }

  nodes = [inXMLElement nodesForXPath:@"./syndicatedEpisodeNumber" error:&err];
  if ([nodes count] > 0 )
  {
    [self setSyndicatedEpisodeNumber:[[nodes objectAtIndex:0] stringValue]];
  }

  nodes = [inXMLElement nodesForXPath:@"./advisories/advisory" error:&err];
  
  NSArray *advisoryRelationships = [[self entity] relationshipsWithDestinationEntity:[NSEntityDescription entityForName:@"Advisory" inManagedObjectContext:[self managedObjectContext]]];
  int maxNumAdvisories = 0;
  if ([advisoryRelationships count] > 0)
  {
	maxNumAdvisories = [[advisoryRelationships objectAtIndex:0] maxCount];
  }
  [self removeAdvisories:[self advisories]];   // Clear the advisories - we're going to replace them with the contents of the XML
  if ([nodes count] > 0 )
  {
    int i=0;
    for (i=0; (i < [nodes count]) && (i < maxNumAdvisories); i++)
    {
      NSString *advStr = [[nodes objectAtIndex:i] stringValue];
      [self addAdvisory:advStr];
    }
  }
  [subPool release];
  
  // Update the genre if this is a Movie (program ID starts with 'MV')
  if ([self isMovie])
  {
	// Program is a Movie - set the genre to have Movie, Relevance 0
	Z2ITGenre *aGenre = [Z2ITGenre fetchGenreWithClassName:@"Movie" andRelevance:[NSNumber numberWithInt:0] inManagedObjectContext:[self managedObjectContext]];
	if (!aGenre)
	{
		aGenre = [Z2ITGenre createGenreWithClassName:@"Movie" andRelevance:[NSNumber numberWithInt:0] inManagedObjectContext:[self managedObjectContext]];
	}
	[aGenre addProgramsObject:self];
	[self addGenresObject:aGenre];
  }
}

- (void) addProductionCrewWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSArray *nodes;
  NSError *err;
  nodes = [inXMLElement nodesForXPath:@"./member" error:&err];
  
  [self removeCrewMembers:[self crewMembers]];    // Clear the current crew members - we're going to replace them with the contents of the XML
  
  for (NSXMLElement *memberElement in nodes)
  {
      Z2ITCrewMember *aCrewMember = [NSEntityDescription insertNewObjectForEntityForName:@"CrewMember"
                  inManagedObjectContext:[self managedObjectContext]];

      NSArray *memberNodes;
      memberNodes = [memberElement nodesForXPath:@"./role" error:&err];
      if ([memberNodes count] == 1)
      {
		  NSManagedObject* aCrewRole = [Z2ITCrewMember fetchCrewRoleWithName:[[memberNodes objectAtIndex:0] stringValue] inManagedObjectContext:[self managedObjectContext]];
		  if (!aCrewRole)
		  {
			aCrewRole = [NSEntityDescription
				insertNewObjectForEntityForName:@"CrewRole"
				inManagedObjectContext:[self managedObjectContext]];
			[aCrewRole setValue:[[memberNodes objectAtIndex:0] stringValue] forKey:@"name"];
		  }
		[aCrewMember setRole:aCrewRole];
      }
      memberNodes = [memberElement nodesForXPath:@"./givenname" error:&err];
      if ([memberNodes count] == 1)
      {
        [aCrewMember setGivenname:[[memberNodes objectAtIndex:0] stringValue]];
      }
      memberNodes = [memberElement nodesForXPath:@"./surname" error:&err];
      if ([memberNodes count] == 1)
      {
        [aCrewMember setSurname:[[memberNodes objectAtIndex:0] stringValue]];
      }
      
      [self addCrewMembersObject:aCrewMember];
  }
}

- (void) addGenreWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSArray *nodes;
  NSError *err;
  nodes = [inXMLElement nodesForXPath:@"./genre" error:&err];
  NSDictionary *colorDictionary = [RSColorDictionary colorDictionaryNamed:@"Default"];
  
  [self removeGenres:[self genres]];       // Clear the current genres - we're going to replace them with the contents of the XML
  
    // Update the genre if this is a Movie (program ID starts with 'MV')
  if ([self isMovie])
  {
	// Program is a Movie - set the genre to have Movie, Relevance 0
	Z2ITGenre *aGenre = [Z2ITGenre fetchGenreWithClassName:@"Movie" andRelevance:[NSNumber numberWithInt:0] inManagedObjectContext:[self managedObjectContext]];
	if (!aGenre)
	{
		aGenre = [Z2ITGenre createGenreWithClassName:@"Movie" andRelevance:[NSNumber numberWithInt:0] inManagedObjectContext:[self managedObjectContext]];
	}
	if (![aGenre valueForKeyPath:@"genreClass.color"])
	{
		NSColor *aColor = [colorDictionary valueForKey:@"Movie"];
		if (aColor)
			[aGenre setValue:[NSArchiver archivedDataWithRootObject:aColor] forKeyPath:@"genreClass.color"];
	}
	[aGenre addProgramsObject:self];
	[self addGenresObject:aGenre];
  }

  for (NSXMLElement *memberElement in nodes)
  {
	  NSNumber *relevanceNumber = nil;
	  NSString *genreClassString = nil;
	  
      NSArray *memberNodes;
      memberNodes = [memberElement nodesForXPath:@"./class" error:&err];
      if ([memberNodes count] == 1)
      {
		  genreClassString = [[memberNodes objectAtIndex:0] stringValue];
      }
      memberNodes = [memberElement nodesForXPath:@"./relevance" error:&err];
      if ([memberNodes count] == 1)
      {
		relevanceNumber = [NSNumber numberWithInt:[[[memberNodes objectAtIndex:0] stringValue] intValue]];
      }

	  // If this program is a Movie then we've already added a Genre
	  // of 'Movie' with a relevance of zero, so all the other genre relevance values need to be 'bumped' by one.
	  if ([self isMovie])
	  {
		int newRelevance = [relevanceNumber intValue] + 1;
		relevanceNumber = [NSNumber numberWithInt:newRelevance];
	  }
	  
	  if ([relevanceNumber intValue] >= 6)
	  {
		NSLog(@"addGenreWithXMLElement - genre relevance too great (%@)", relevanceNumber);
	  }
	  if (genreClassString && relevanceNumber && ([relevanceNumber intValue] <= 6))
	  {
		// Look for a genre with this relevance number and genreClass
		Z2ITGenre *aGenre = [Z2ITGenre fetchGenreWithClassName:genreClassString andRelevance:relevanceNumber inManagedObjectContext:[self managedObjectContext]];
		if (!aGenre)
		{
			aGenre = [Z2ITGenre createGenreWithClassName:genreClassString andRelevance:relevanceNumber inManagedObjectContext:[self managedObjectContext]];
		}
		if (![aGenre valueForKeyPath:@"genreClass.color"])
		{
			NSColor *aColor = [colorDictionary valueForKey:genreClassString];
			if (aColor)
				[aGenre setValue:[NSArchiver archivedDataWithRootObject:aColor] forKeyPath:@"genreClass.color"];
		}
		// Add it to the program
		[aGenre addProgramsObject:self];
		[self addGenresObject:aGenre];
	  }
  }
}

- (void) addScheduleWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSNumber *stationID = [NSNumber numberWithInt:[[[inXMLElement attributeForName:@"station"] stringValue] intValue]];
  
  NSString *tmpStr;
  tmpStr = [[inXMLElement attributeForName:@"time"] stringValue];
  NSDate *timeDate = [NSDate dateWithNaturalLanguageString:tmpStr];
  
  NSString *theDurationString = [[inXMLElement attributeForName:@"duration"] stringValue];
  int durationHours;
  NSString *durationHoursString = [theDurationString substringWithRange:NSMakeRange(2,2)];
  durationHours = [durationHoursString intValue];
  int durationMins;
  NSString *durationMinsString = [theDurationString substringWithRange:NSMakeRange(5, 2)];
  durationMins = [durationMinsString intValue];

  NSNumber* newProgram = [NSNumber numberWithBool:boolValueForAttribute(inXMLElement, @"new")];
  NSNumber* stereo = [NSNumber numberWithBool:boolValueForAttribute(inXMLElement, @"stereo")];
  NSNumber* subtitled = [NSNumber numberWithBool:boolValueForAttribute(inXMLElement, @"subtitled")];
  NSNumber* hdtv = [NSNumber numberWithBool:boolValueForAttribute(inXMLElement, @"hdtv")];
  NSNumber* closeCaptioned = [NSNumber numberWithBool:boolValueForAttribute(inXMLElement, @"closeCaptioned")];
  
  NSString *tvRatingStr = [[inXMLElement attributeForName:@"tvRating"] stringValue];
  NSString *dolbyStr = [[inXMLElement attributeForName:@"dolby"] stringValue];

  NSArray *nodes;
  NSError *err;
  NSNumber *partNumber = nil;
  NSNumber *totalNumberPartsNumber = nil;
  nodes = [inXMLElement nodesForXPath:@"./part" error:&err];
  if ([nodes count] == 1)
  {
    NSXMLElement *partNumberNode = [nodes objectAtIndex:0];
    partNumber = [NSNumber numberWithInt:[[[partNumberNode attributeForName:@"number"] stringValue] intValue]];
    totalNumberPartsNumber = [NSNumber numberWithInt:[[[partNumberNode attributeForName:@"total"] stringValue] intValue]];
  }

  Z2ITSchedule *aSchedule = [NSEntityDescription insertNewObjectForEntityForName:@"Schedule"
              inManagedObjectContext:[self managedObjectContext]];
  [aSchedule setProgram:self];
  Z2ITStation *aStation = [Z2ITStation fetchStationWithID:stationID inManagedObjectContext:[self managedObjectContext]];
  if (aStation)
  {
    [aSchedule setTime:timeDate];
    [aSchedule setDurationHours:durationHours minutes:durationMins];
    [aSchedule setNew:newProgram];
    [aSchedule setStereo:stereo];
    [aSchedule setSubtitled:subtitled];
    [aSchedule setHdtv:hdtv];
    [aSchedule setCloseCaptioned:closeCaptioned];
    if (tvRatingStr)
      [aSchedule setTvRating:tvRatingStr];
    if (dolbyStr)
      [aSchedule setDolby:dolbyStr];
    if (partNumber)
      [aSchedule setPartNumber:partNumber];
    if (totalNumberPartsNumber)
      [aSchedule setTotalNumberParts:totalNumberPartsNumber];

	// If this schedule already exists in matching form on the station (i.e. we're doing an update rather than just grabbing new data)
	// addSchedule will return false and we should delete the schedule here.
    if (![aStation addScheduleIfNew:aSchedule])
	{
		[[self managedObjectContext] deleteObject:aSchedule];
	}
  }
  else
  {
    NSLog(@"addScheduleWithXMLElement - cannot find station with ID %@", stationID);
  }  
}

- (BOOL) isMovie
{
	NSRange mvRange = [[self programID] rangeOfString:@"MV"];
	if ((mvRange.location == 0) && (mvRange.length == 2))
		return YES;
	else
		return NO;
}

// Fetch the Advisory Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchAdvisoryWithName:(NSString*)inAdvisoryString inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  NSManagedObject *anAdvisory = nil;
  
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Advisory" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inAdvisoryString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find advisory %@", inAdvisoryString);
      return nil;
  }
  
  if ([array count] == 0)
  {
      return nil;
  }
  else
  {
    anAdvisory = [array objectAtIndex:0];
    return anAdvisory;
  }
}

- (void)addAdvisory:(NSString *)value
{
  NSMutableSet *advisories = [self mutableSetValueForKey:@"advisories"];
  NSManagedObject *newAdvisory = [Z2ITProgram fetchAdvisoryWithName:value inManagedObjectContext:[self managedObjectContext]];
  if (!newAdvisory)
  {
    newAdvisory = [NSEntityDescription
        insertNewObjectForEntityForName:@"Advisory"
        inManagedObjectContext:[self managedObjectContext]];
    [newAdvisory setValue:value forKey:@"name"];
  }
  [advisories addObject:newAdvisory];
  [[newAdvisory mutableSetValueForKey:@"programs"] addObject:self];
}

- (Z2ITGenre*) genreWithRelevance:(int)inRelevance
{
  for (Z2ITGenre* aGenre in self.genres)
  {
    if ([aGenre.relevance intValue] == inRelevance)
    {
      return aGenre;
    }
  }
  return nil;
}

@dynamic colorCode;
@dynamic descriptionStr;
@dynamic mpaaRating;
@dynamic originalAirDate;
@dynamic programID;
@dynamic runTimeHours;
@dynamic runTimeMinutes;
@dynamic series;
@dynamic showType;
@dynamic starRating;
@dynamic subTitle;
@dynamic syndicatedEpisodeNumber;
@dynamic title;
@dynamic year;
@dynamic advisories;
@dynamic crewMembers;
@dynamic genres;
@dynamic schedules;

@end

@implementation Z2ITCrewMember

// Fetch the CrewRole Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchCrewRoleWithName:(NSString*)inCrewRoleNameString inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CrewRole" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1]; 
  
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inCrewRoleNameString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find crew role name %@", inCrewRoleNameString);
      return nil;
  }
  if ([array count] == 1)
  {
    NSManagedObject *aCrewRole = [array objectAtIndex:0];
    return aCrewRole;
  }
  else
  {
      return nil;
  }
}


@dynamic givenname;
@dynamic surname;
@dynamic program;
@dynamic role;

@end

@implementation Z2ITGenre

+ (Z2ITGenre *) createGenreWithClassName:(NSString*)inGenreClassNameString andRelevance:(NSNumber*)inRelevance inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
	Z2ITGenre* aGenre;
	
	// See if we can find a genreClass
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GenreClass" inManagedObjectContext:inMOC];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	[request setFetchLimit:1];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inGenreClassNameString];
	[request setPredicate:predicate];

	NSError *error = nil;
	NSArray *array = [inMOC executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Error executing fetch request to find genreClass %@ error = %@", inGenreClassNameString, *error);
		return nil;
	}
	NSManagedObject *aGenreClass = nil;
	
	if ([array count] == 0)
	{
		aGenreClass = [NSEntityDescription insertNewObjectForEntityForName:@"GenreClass" inManagedObjectContext:inMOC];
		[aGenreClass setValue:inGenreClassNameString forKey:@"name"];
	}
	else if ([array count] == 1)
	{
		aGenreClass = [array objectAtIndex:0];
	}

	// Create a genre with the appropriate relevance
	aGenre = [NSEntityDescription insertNewObjectForEntityForName:@"Genre" inManagedObjectContext:inMOC];
	[aGenre setValue:aGenreClass forKey:@"genreClass"];
	[aGenre setRelevance:inRelevance];
	return aGenre;
}

// Fetch the GenreClass Object with the given string from the Managed Object Context
+ (Z2ITGenre *) fetchGenreWithClassName:(NSString*)inGenreClassNameString andRelevance:(NSNumber*)inRelevance inManagedObjectContext:(NSManagedObjectContext *)inMOC
{
  Z2ITGenre *aGenre = nil;
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Genre" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"genreClass.name == %@ AND relevance == %@", inGenreClassNameString, inRelevance];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"genreClass.name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find genre class name %@ with relevance %@", inGenreClassNameString, inRelevance);
      return nil;
  }
  if ([array count] == 0)
  {
    return nil;
  }
  else
  {
    aGenre = [array objectAtIndex:0];
    return aGenre;
  }
}

- (NSNumber *) numberOfPrograms
{
//	NSLog(@"numberOfPrograms %d for Genre %@", [[self mutableSetValueForKey:@"programs"] count], [self valueForKeyPath:@"genreClass.name"]);
	return [NSNumber numberWithInt:[[self mutableSetValueForKey:@"programs"] count]];
}

@dynamic relevance;
@dynamic genreClass;
@dynamic programs;

@end

