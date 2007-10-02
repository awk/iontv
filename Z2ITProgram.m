//
//  Z2ITProgram.m
//  recsched
//
//  Created by Andrew Kimpton on 1/19/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"
#import "CoreData_Macros.h"

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
+ (Z2ITProgram *) fetchProgramWithID:(NSString*)inProgramID
{
  recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];

  NSManagedObjectContext *moc = [recschedAppDelegate managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Program" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"programID == %@", inProgramID];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"programID" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];
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
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchProgramWithID - multiple (%d) lineups with ID %@", [array count], inProgramID);
      return nil;
  }
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
  [self clearAdvisories];   // Clear the advisories - we're going to replace them with the contents of the XML
  if ([nodes count] > 0 )
  {
    int i=0;
    for (i=0; i < [nodes count]; i++)
    {
      NSString *advStr = [[nodes objectAtIndex:i] stringValue];
      [self addAdvisory:advStr];
    }
  }
}

- (void) addProductionCrewWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSArray *nodes;
  NSError *err;
  nodes = [inXMLElement nodesForXPath:@"./member" error:&err];
  int i=0;
  int crewMemberCount = [nodes count];
  
  [self clearCrewMembers];    // Clear the current crew members - we're going to replace them with the contents of the XML
  
  for (i=0; i < crewMemberCount; i++)
  {
      NSXMLElement *memberElement = [nodes objectAtIndex:i];
      Z2ITCrewMember *aCrewMember = [NSEntityDescription insertNewObjectForEntityForName:@"CrewMember"
                  inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];

      NSArray *memberNodes;
      memberNodes = [memberElement nodesForXPath:@"./role" error:&err];
      if ([memberNodes count] == 1)
      {
        [aCrewMember setRoleName:[[memberNodes objectAtIndex:0] stringValue]];
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
      
      [self addCrewMember:aCrewMember];
  }
}

- (void) addGenreWithXMLElement:(NSXMLElement *)inXMLElement
{
  NSArray *nodes;
  NSError *err;
  nodes = [inXMLElement nodesForXPath:@"./genre" error:&err];
  int i=0;
  int genreCount = [nodes count];
  
  [self clearGenres];       // Clear the current genres - we're going to replace them with the contents of the XML
  for (i=0; i < genreCount; i++)
  {
      NSXMLElement *memberElement = [nodes objectAtIndex:i];
      Z2ITGenre *aGenre = [NSEntityDescription insertNewObjectForEntityForName:@"Genre"
                  inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];

      NSArray *memberNodes;
      memberNodes = [memberElement nodesForXPath:@"./class" error:&err];
      if ([memberNodes count] == 1)
      {
        [aGenre setGenreClassName:[[memberNodes objectAtIndex:0] stringValue]];
      }
      memberNodes = [memberElement nodesForXPath:@"./relevance" error:&err];
      if ([memberNodes count] == 1)
      {
        [aGenre setRelevance:[NSNumber numberWithInt:[[[memberNodes objectAtIndex:0] stringValue] intValue]]];
      }
      [self addGenre:aGenre];
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

  BOOL repeat = boolValueForAttribute(inXMLElement, @"repeat");
  BOOL stereo = boolValueForAttribute(inXMLElement, @"stereo");
  BOOL subtitled = boolValueForAttribute(inXMLElement, @"subtitled");
  BOOL hdtv = boolValueForAttribute(inXMLElement, @"hdtv");
  BOOL closeCaptioned = boolValueForAttribute(inXMLElement, @"closeCaptioned");
  
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
              inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
  [aSchedule setProgram:self];
  Z2ITStation *aStation = [Z2ITStation fetchStationWithID:stationID];
  if (aStation)
  {
    [aStation addSchedule:aSchedule];
    [aSchedule setTime:timeDate];
    [aSchedule setDurationHours:durationHours minutes:durationMins];
    [aSchedule setRepeat:repeat];
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
  }
  else
  {
    NSLog(@"addScheduleWithXMLElement - cannot find station with ID %@", stationID);
  }  
}

#pragma mark
#pragma mark Core Data accessors/mutators/validation methods
#pragma mark


// Accessor and mutator for the Lineup ID attribute
- (NSString *)programID
{
COREDATA_ACCESSOR(NSString*, @"programID")
}

- (void)setProgramID:(NSString *)value
{
COREDATA_MUTATOR(NSString*, @"programID")
}

// Accessor and mutator for the color code attribute
- (NSString *)colorCode
{
COREDATA_ACCESSOR(NSString*, @"colorCode")
}

- (void)setColorCode:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"colorCode")
}

// Accessor and mutator for the description string attribute
- (NSString *)descriptionStr
{
COREDATA_ACCESSOR(NSString*,@"descriptionStr")
}

- (void)setDescriptionStr:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"descriptionStr")
}

// Accessor and mutator for the MPAA Rating attribute
- (NSString *)mpaaRating
{
COREDATA_ACCESSOR(NSString*,@"mpaaRating")
}

- (void)setMpaaRating:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"mpaaRating")
}

// Accessor and mutator for the original air date attribute
- (NSDate *)originalAirDate
{
COREDATA_ACCESSOR(NSDate*,@"originalAirDate")
}

- (void)setOriginalAirDate:(NSDate *)value
{
COREDATA_MUTATOR(NSDate*,@"originalAirDate")
}

// Accessor and mutator for the type attribute
- (NSNumber *)runTimeHours
{
COREDATA_ACCESSOR(NSNumber*,@"runTimeHours")
}

- (void)setRunTimeHours:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*,@"runTimeHours")
}

// Accessor and mutator for the user lineup name attribute
- (NSNumber *)runTimeMinutes
{
COREDATA_ACCESSOR(NSNumber*,@"runTimeMinutes")
}

- (void)setRunTimeMinutes:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*,@"runTimeMinutes")
}

// Accessor and mutator for the series attribute
- (NSString *)series
{
COREDATA_ACCESSOR(NSString*,@"series")
}

- (void)setSeries:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"series")
}

// Accessor and mutator for the show type attribute
- (NSString *)showType
{
COREDATA_ACCESSOR(NSString*,@"showType")
}

- (void)setShowType:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"showType")
}

// Accessor and mutator for the star rating attribute
- (NSNumber *)starRating
{
COREDATA_ACCESSOR(NSNumber*,@"starRating")
}

- (void)setStarRating:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*,@"starRating")
}

// Accessor and mutator for the sub-title attribute
- (NSString *)subTitle
{
COREDATA_ACCESSOR(NSString*,@"subTitle")
}

- (void)setSubTitle:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"subTitle")
}

// Accessor and mutator for the syndicated episode number attribute
- (NSString *)syndicatedEpisodeNumber
{
COREDATA_ACCESSOR(NSString*,@"syndicatedEpisodeNumber")
}

- (void)setSyndicatedEpisodeNumber:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"syndicatedEpisodeNumber")
}

// Accessor and mutator for the title attribute
- (NSString *)title
{
COREDATA_ACCESSOR(NSString*,@"title")
}

- (void)setTitle:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"title")
}

// Accessor and mutator for the year attribute
- (NSNumber *)year
{
COREDATA_ACCESSOR(NSNumber*,@"year")
}

- (void)setYear:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*,@"year")
}

// Accessor and mutator for the advisory attributes
- (NSSet *)advisories
{
  NSMutableSet *advisories = [self mutableSetValueForKey:@"advisories"];
  return [NSSet setWithSet:advisories];
}

- (void)clearAdvisories
{
  NSMutableSet *advisories = [self mutableSetValueForKey:@"advisories"];
  [advisories removeAllObjects];
}

// Fetch the Advisory Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchAdvisoryWithName:(NSString*)inAdvisoryString
{
  recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];

  NSManagedObjectContext *moc = [recschedAppDelegate managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Advisory" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inAdvisoryString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find advisory %@", inAdvisoryString);
      return nil;
  }
  if ([array count] == 1)
  {
    NSManagedObject *anAdvisory = [array objectAtIndex:0];
    [anAdvisory retain];
    return anAdvisory;
  }
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchAdvisoryWithName - multiple (%d) advisories with name %@", [array count], inAdvisoryString);
      NSManagedObject *anAdvisory = [array objectAtIndex:0];
      [anAdvisory retain];
      return anAdvisory;
  }
}

- (void)addAdvisory:(NSString *)value
{
  NSMutableSet *advisories = [self mutableSetValueForKey:@"advisories"];
  NSManagedObject *newAdvisory = [Z2ITProgram fetchAdvisoryWithName:value];
  if (!newAdvisory)
  {
    newAdvisory = [NSEntityDescription
        insertNewObjectForEntityForName:@"Advisory"
        inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
    [newAdvisory retain];
    [newAdvisory setValue:value forKey:@"name"];
  }
  [advisories addObject:newAdvisory];
  [newAdvisory release];
}

// Accessor and mutator for the genres relationships
- (NSSet *)genres
{
  NSMutableSet *genresSet = [self mutableSetValueForKey:@"genres"];
  return genresSet;
}

- (void)clearGenres
{
  NSMutableSet *genresSet = [self mutableSetValueForKey:@"genres"];
  [genresSet removeAllObjects];
}

- (void)addGenre:(Z2ITGenre *)value
{
  NSMutableSet *genresSet = [self mutableSetValueForKey:@"genres"];
  [genresSet addObject:value];
}

- (NSSet *)crewMembers
{
  NSMutableSet *crewMembersSet = [self mutableSetValueForKey:@"crewMembers"];
  return crewMembersSet;
}

- (void)clearCrewMembers
{
  NSMutableSet *crewMembersSet = [self mutableSetValueForKey:@"crewMembers"];
  [crewMembersSet removeAllObjects];
}

- (void)addCrewMember:(Z2ITCrewMember *)value
{
  NSMutableSet *crewMembersSet = [self mutableSetValueForKey:@"crewMembers"];
  [crewMembersSet addObject:value];
}

@end

@implementation Z2ITCrewMember

// Fetch the CrewRole Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchCrewRoleWithName:(NSString*)inCrewRoleNameString
{
  recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];

  NSManagedObjectContext *moc = [recschedAppDelegate managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"CrewRole" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inCrewRoleNameString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find crew role name %@", inCrewRoleNameString);
      return nil;
  }
  if ([array count] == 1)
  {
    NSManagedObject *aCrewRole = [array objectAtIndex:0];
    [aCrewRole retain];
    return aCrewRole;
  }
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchCrewRoleWithName - multiple (%d) crew roles with name %@", [array count], inCrewRoleNameString);
      NSManagedObject *aCrewRole = [array objectAtIndex:0];
      [aCrewRole retain];
      return aCrewRole;
  }
}

#pragma mark
#pragma mark Core Data accessors/mutators/validation methods
#pragma mark


// Accessor and mutator for the Role attribute
- (NSString *)roleName
{
  return [self valueForKeyPath:@"role.name"];
}

- (void)setRoleName:(NSString *)value
{
  NSManagedObject* aCrewRole = [Z2ITCrewMember fetchCrewRoleWithName:value];
  if (!aCrewRole)
  {
    aCrewRole = [NSEntityDescription
        insertNewObjectForEntityForName:@"CrewRole"
        inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
    [aCrewRole retain];
    [aCrewRole setValue:value forKey:@"name"];
  }

  [self willChangeValueForKey: @"role"]; 
  [self setPrimitiveValue:aCrewRole forKey: @"role"]; 
  [self didChangeValueForKey: @"role"]; 
  [aCrewRole release];
}

// Accessor and mutator for the surname attribute
- (NSString *)surname
{
COREDATA_ACCESSOR(NSString*, @"surname")
}

- (void)setSurname:(NSString *)value
{
COREDATA_MUTATOR(NSString*, @"surname")
}

// Accessor and mutator for the givenname attribute
- (NSString *)givenname
{
COREDATA_ACCESSOR(NSString*, @"givenname")
}

- (void)setGivenname:(NSString *)value
{
COREDATA_MUTATOR(NSString*,@"givenname")
}

@end

@implementation Z2ITGenre

// Fetch the GenreClass Object with the given string from the Managed Object Context
+ (NSManagedObject *) fetchGenreClassWithName:(NSString*)inGenreClassNameString
{
  recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];

  NSManagedObjectContext *moc = [recschedAppDelegate managedObjectContext];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"GenreClass" inManagedObjectContext:moc];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", inGenreClassNameString];
  [request setPredicate:predicate];
   
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
   
  NSError *error = nil;
  NSArray *array = [moc executeFetchRequest:request error:&error];
  if (array == nil)
  {
      NSLog(@"Error executing fetch request to find genre class name %@", inGenreClassNameString);
      return nil;
  }
  if ([array count] == 1)
  {
    NSManagedObject *aGenreClass = [array objectAtIndex:0];
    [aGenreClass retain];
    return aGenreClass;
  }
  else if ([array count] == 0)
  {
      return nil;
  }
  else
  {
      NSLog(@"fetchGenreClassWithName - multiple (%d) genre classes with name %@", [array count], inGenreClassNameString);
      NSManagedObject *aGenreClass = [array objectAtIndex:0];
      [aGenreClass retain];
      return aGenreClass;
  }
}

// Accessor and mutator for the Role attribute
- (NSString *)genreClassName
{
  return [self valueForKeyPath:@"genreClass.name"];
}

- (void)setGenreClassName:(NSString *)value
{
  NSManagedObject* aGenreClass = [Z2ITGenre fetchGenreClassWithName:value];
  if (!aGenreClass)
  {
    aGenreClass = [NSEntityDescription
        insertNewObjectForEntityForName:@"GenreClass"
        inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
    [aGenreClass retain];
    [aGenreClass setValue:value forKey:@"name"];
  }

  [self willChangeValueForKey: @"genreClass"]; 
  [self setPrimitiveValue:aGenreClass forKey: @"genreClass"]; 
  [self didChangeValueForKey: @"genreClass"]; 
  [aGenreClass release];
}

// Accessor and mutator for the surname attribute
- (NSNumber *)relevance
{
  COREDATA_ACCESSOR(NSNumber*, @"relevance")
}

- (void)setRelevance:(NSNumber *)value
{
COREDATA_MUTATOR(NSNumber*,@"relevance")
}

@end

