//
//  XTVDParser.m
//  recsched
//
//  Created by Andrew Kimpton on 1/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "XTVDParser.h"
#import "recsched_AppDelegate.h"
#import "Z2ITStation.h"
#import "Z2ITSchedule.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITProgram.h"
#import "MainWindowController.h"

@implementation XTVDParser

+ (void) parseXMLFile:(NSString *)filePath reportTo:(MainWindowController*)inMainWindowController;
{
    NSXMLDocument *xmlDoc;
    NSError *err=nil;
    NSURL *furl = [NSURL fileURLWithPath:filePath];
    if (!furl) {
        NSLog(@"Can't create an URL from file %@.", filePath);
        return;
    }
    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
            options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
            error:&err];
    if (xmlDoc == nil) {
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
                    options:NSXMLDocumentTidyXML
                    error:&err];
    }
    if (xmlDoc == nil)  {
        if (err) {
            [self handleError:err];
        }
        return;
    }
 
    if (err) {
        [self handleError:err];
    }
    
    // Now that we have a document we can traverse it to create the CoreData objects
    [self traverseXMLDocument:xmlDoc reportTo:inMainWindowController];
    [xmlDoc release];
}

+ (void) handleError:(NSError*) error
{
	NSLog(@"XTVDParser handleError: %d", [error code]);
}

+ (void) updateStations:(NSXMLNode *)inStationsNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = [inStationsNode children];
  int i, count = [childNodes count];
  
  [inMainWindowController setParsingInfoString:@"Updating Stations"];
  [inMainWindowController setParsingProgressMaxValue:count];
  [inMainWindowController setParsingProgressDoubleValue:0];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *stationIDString = [[childElement attributeForName:@"id"] stringValue];
      int stationID = -1;
      if (stationIDString)
      {
        [inMainWindowController setParsingProgressDoubleValue:i];
        
        stationID = [stationIDString intValue];
      
        // Now for the other items in the station element node
        NSString *callSignString = nil;
        NSString *nameString = nil;
        NSString *affiliateString = nil;
        int fccChannel = 0;
        NSArray *stationChildNodes = [childElement children];
        int j, stationChildCount = [stationChildNodes count];
        for (j=0; j < stationChildCount; j++)
        {
          NSXMLNode *stationChild = [stationChildNodes objectAtIndex:j];
          if ([[stationChild name] compare:@"callSign" options:NSCaseInsensitiveSearch] == NSOrderedSame)
          {
            callSignString = [stationChild stringValue];
          }
          else if ([[stationChild name] compare:@"name" options:NSCaseInsensitiveSearch] == NSOrderedSame)
          {
            nameString = [stationChild stringValue];
          }
          else if ([[stationChild name] compare:@"affiliate" options:NSCaseInsensitiveSearch] == NSOrderedSame)
          {
            affiliateString = [stationChild stringValue];
          }
          else if ([[stationChild name] compare:@"fccChannelNumber" options:NSCaseInsensitiveSearch] == NSOrderedSame)
          {
            fccChannel = [[stationChild stringValue] intValue];;
          }
        }
        
        // Now we have a complete packet of data on the station update the CoreData info
        recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];
        
        // If the station already exists we might need to update it's info
        Z2ITStation *aStation = [Z2ITStation fetchStationWithID:[NSNumber numberWithInt:stationID]];
        if (aStation == nil)
        {
          // Otherwise we just create a new one
          aStation = [NSEntityDescription
              insertNewObjectForEntityForName:@"Station"
              inManagedObjectContext:[recschedAppDelegate managedObjectContext]];
          [aStation setStationID:[NSNumber numberWithInt:stationID]];
        }
        
        [aStation setCallSign:callSignString];
        [aStation setName:nameString];
        if (affiliateString)
          [aStation setAffiliate:affiliateString];
        else
          [aStation setAffiliate:nil];
          
        if (fccChannel > 0)
          [aStation setFccChannelNumber:[NSNumber numberWithInt:fccChannel]];
        else
          [aStation setFccChannelNumber:nil];
        [aStation release];
        aStation = NULL;
      }
    }
  }
}

+ (void) updateLineups:(NSXMLNode *)inLineupsNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = [inLineupsNode children];
  int i, count = [childNodes count];
  [inMainWindowController setParsingInfoString:@"Updating Lineups"];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *lineupIDString = [[childElement attributeForName:@"id"] stringValue];
      if (lineupIDString)
      {
        NSString *lineupNameString = [[childElement attributeForName:@"name"] stringValue];
        NSString *userLineupNameString = [[childElement attributeForName:@"userLineupName"] stringValue];
        NSString *locationString = [[childElement attributeForName:@"location"] stringValue];
        NSString *deviceString = [[childElement attributeForName:@"device"] stringValue];
        NSString *typeString = [[childElement attributeForName:@"type"] stringValue];
        NSString *postalCodeString = [[childElement attributeForName:@"postalCode"] stringValue];

        // Now we have a complete packet of data on the station update the CoreData info
        recsched_AppDelegate *recschedAppDelegate = [[NSApplication sharedApplication] delegate];
        
        // If the lineup already exists we might need to update it's info
        Z2ITLineup *aLineup = [Z2ITLineup fetchLineupWithID:lineupIDString];
        if (aLineup == nil)
        {
          // Otherwise we just create a new one
          aLineup = [NSEntityDescription
              insertNewObjectForEntityForName:@"Lineup"
              inManagedObjectContext:[recschedAppDelegate managedObjectContext]];
          [aLineup retain];
        }

        [aLineup setLineupID:lineupIDString];
        [aLineup setName:lineupNameString];
        [aLineup setType:typeString];
        [aLineup setLocation:locationString];
        
        if (postalCodeString)
          [aLineup setPostalCode:postalCodeString];
        if (deviceString)
          [aLineup setDevice:deviceString];
        if (userLineupNameString)
          [aLineup setUserLineupName:userLineupNameString];
        
        // Now for the map items in the lineup element node
        NSArray *lineupChildNodes = [childElement children];
        int j, lineupChildCount = [lineupChildNodes count];
        [inMainWindowController setParsingProgressMaxValue:lineupChildCount];
        for (j=0; j < lineupChildCount; j++)
        {
          NSNumber *stationIDNumber = nil;
          NSString *channelString = nil;
          NSNumber *channelMinorNumber = nil;
          NSDate *fromDate = nil;
          NSDate *toDate = nil;
          
          NSXMLElement *lineupMap = [lineupChildNodes objectAtIndex:j];
          NSString *tmpStr;
          
          [inMainWindowController setParsingProgressDoubleValue:j];
          tmpStr = [[lineupMap attributeForName:@"station"] stringValue];
          if (tmpStr)
            stationIDNumber = [NSNumber numberWithInt:[tmpStr intValue]];
          else
            NSLog(@"XTVDParser - lineup map %@ has invalid station field", lineupMap);
            
          channelString = [[lineupMap attributeForName:@"channel"] stringValue];
          tmpStr = [[lineupMap attributeForName:@"channelMinor"] stringValue];
          if (tmpStr)
            channelMinorNumber = [NSNumber numberWithInt:[tmpStr intValue]];
          
          tmpStr = [[lineupMap attributeForName:@"from"] stringValue];
          if (tmpStr)
          {
            fromDate = [NSDate dateWithNaturalLanguageString:tmpStr];
          }
          tmpStr = [[lineupMap attributeForName:@"to"] stringValue];
          if (tmpStr)
            toDate = [NSDate dateWithNaturalLanguageString:tmpStr];

          Z2ITStation *mapStation = [Z2ITStation fetchStationWithID:stationIDNumber];
          if (!mapStation)
            NSLog(@"updateLineups - Failed to find station with ID %@", stationIDNumber);
          else
          {
            Z2ITLineupMap *aLineupMap = [aLineup fetchLineupMapWithStationID:stationIDNumber];
            if (!aLineupMap)
            {
              aLineupMap = [NSEntityDescription
                  insertNewObjectForEntityForName:@"LineupMap"
                  inManagedObjectContext:[recschedAppDelegate managedObjectContext]];
              [aLineupMap retain];
            }

            [aLineupMap setStation:mapStation];
            [aLineupMap setChannel:channelString];
            if (channelMinorNumber)
              [aLineupMap setChannelMinor:channelMinorNumber];
            if (fromDate)
              [aLineupMap setFrom:fromDate];
            if (toDate)
              [aLineupMap setTo:toDate];
              
            [aLineup addLineupMap:aLineupMap];

            [aLineupMap release];
            aLineupMap = NULL;
          }
          
        }

        [aLineup release];
        aLineup = NULL;
        
      }
    }
  }
}

// Compare two programs for their program ID
int compareProgramsByIDAttribute(id thisXMLProgramNode, id otherXMLProgramNode, void *context)
{
  NSString *programIDStringThisXMLProgramNode = [[thisXMLProgramNode attributeForName:@"id"] stringValue];
  NSString *programIDStringOtherXMLProgramNode = [[otherXMLProgramNode attributeForName:@"id"] stringValue];
  return [programIDStringThisXMLProgramNode compare:programIDStringOtherXMLProgramNode];
}

+ (void) updatePrograms:(NSXMLNode *)inProgramsNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = nil;
  int i, count = 0;
  [inMainWindowController setParsingInfoString:@"Updating Programs"];

  childNodes  = [[inProgramsNode children] sortedArrayUsingFunction:compareProgramsByIDAttribute context:nil];
  count = [childNodes count];
  [inMainWindowController setParsingProgressMaxValue:count];
  [inMainWindowController setParsingProgressDoubleValue:0];
  
  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"id"] stringValue];
      if (programIDString)
      {
        [programIDArray addObject:programIDString];
      }
    }
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray];
  [programIDArray release];
  programIDArray = nil;
  
  int existingProgramIndex = 0;
  int existingProgramCount = [existingProgramsArray count];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"id"] stringValue];
      if (programIDString)
      {
        [inMainWindowController setParsingProgressDoubleValue:i];
        Z2ITProgram *aProgram  = nil;
        
        if ((existingProgramIndex < existingProgramCount) && ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame))
        {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          existingProgramIndex++;
        }
        
        if (!aProgram)
        {
          aProgram = [NSEntityDescription insertNewObjectForEntityForName:@"Program"
                  inManagedObjectContext:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
        }
        
        [aProgram setProgramID:programIDString];
        [aProgram initializeWithXMLElement:childElement];
      }
    }
  }
}

int compareXMLNodeByProgramAttribute(id thisXMLProgramNode, id otherXMLProgramNode, void *context)
{
  NSString *programIDStringThisXMLCrewNode = [[thisXMLProgramNode attributeForName:@"program"] stringValue];
  NSString *programIDStringOtherXMLCrewNode = [[otherXMLProgramNode attributeForName:@"program"] stringValue];
  return [programIDStringThisXMLCrewNode compare:programIDStringOtherXMLCrewNode];
}

+ (void) updateProductionCrew:(NSXMLNode *)inProductionCrewNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = nil;
  int i, count = 0;
  [inMainWindowController setParsingInfoString:@"Updating Production Crew"];
  
  childNodes  = [[inProductionCrewNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  [inMainWindowController setParsingProgressMaxValue:count];
  [inMainWindowController setParsingProgressDoubleValue:0];
  
  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        [programIDArray addObject:programIDString];
      }
    }
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;
  
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      [inMainWindowController setParsingProgressDoubleValue:i];
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        Z2ITProgram *aProgram  = nil;
        if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)
        {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          existingProgramIndex++;
        }
        else
        {
          NSLog(@"updateProductionCrew - could not find a program with id %@", programIDString);
        }
        if (aProgram)
          [aProgram addProductionCrewWithXMLElement:childElement];
      }
    }
  }
}

+ (void) updateGenres:(NSXMLNode *)inGenresNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = nil;
  int i, count = 0;
  [inMainWindowController setParsingInfoString:@"Updating Genres"];
  
  childNodes = [[inGenresNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  [inMainWindowController setParsingProgressMaxValue:count];
  [inMainWindowController setParsingProgressDoubleValue:0];
  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        [programIDArray addObject:programIDString];
      }
    }
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;

  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      [inMainWindowController setParsingProgressDoubleValue:i];
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        Z2ITProgram *aProgram  = nil;
        if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)
        {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          existingProgramIndex++;
        }
        else
        {
          NSLog(@"updateGenres - could not find a program with id %@", programIDString);
        }
        if (aProgram)
          [aProgram addGenreWithXMLElement:childElement];
      }
    }
  }
}

+ (void) updateSchedules:(NSXMLNode *)inSchedulesNode reportTo:(MainWindowController*)inMainWindowController
{
  NSArray *childNodes = nil;
  int i, count = [childNodes count];
  [inMainWindowController setParsingInfoString:@"Updating Schedules"];

  // Start by clearing all the existing schedules - this collection replaces everything to date
  [Z2ITSchedule clearAllSchedules];
  
  childNodes = [[inSchedulesNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  [inMainWindowController setParsingProgressMaxValue:count];
  [inMainWindowController setParsingProgressDoubleValue:0];
  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        [programIDArray addObject:programIDString];
      }
    }
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;
  
  for (i=0; i < count; i++)
  {
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind)
    {
      NSXMLElement *childElement = (NSXMLElement *)child;
      [inMainWindowController setParsingProgressDoubleValue:i];
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString)
      {
        Z2ITProgram *aProgram  = nil;
      
        // A program might exist more than once in the schedule, so we may have multiple sequential entries for the same program,
        // instead of advancing with each successful test we advance only if we don't have a match
        if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)
        {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
        }
        
        if (!aProgram)
        {
          existingProgramIndex++;
          if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)
          {
            aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          }
        }
        
        if (aProgram)
        {
          [aProgram addScheduleWithXMLElement:childElement];
        }
        else
        {
          NSLog(@"updateSchedules - could not find a program with id %@", programIDString);
        }
      }
    }
  }
}

+ (void) traverseXMLDocument:(NSXMLDocument*) inXMLDocument reportTo:(MainWindowController*)inMainWindowController;
{
  NSError *err;
  NSArray *nodes = [inXMLDocument nodesForXPath:@"//stations" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* theStations = [nodes objectAtIndex:0];
        // Update the stations list
        [self updateStations:theStations reportTo:inMainWindowController];
  }

  nodes = [inXMLDocument nodesForXPath:@"//lineups" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* theLineups = [nodes objectAtIndex:0];
        // Update the stations list
        [self updateLineups:theLineups reportTo:inMainWindowController];
  }

  nodes = [inXMLDocument nodesForXPath:@"//programs" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* thePrograms = [nodes objectAtIndex:0];
        // Update the stations list
        [self updatePrograms:thePrograms reportTo:inMainWindowController];
  }

  nodes = [inXMLDocument nodesForXPath:@"//productionCrew" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* theProductionCrew = [nodes objectAtIndex:0];
        // Update the stations list
        [self updateProductionCrew:theProductionCrew reportTo:inMainWindowController];
  }

  nodes = [inXMLDocument nodesForXPath:@"//genres" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* theGenres = [nodes objectAtIndex:0];
        // Update the genres list
        [self updateGenres:theGenres reportTo:inMainWindowController];
  }

  nodes = [inXMLDocument nodesForXPath:@"//schedules" error:&err];
  if ([nodes count] > 0 )
  {
        NSXMLNode* theSchedules = [nodes objectAtIndex:0];
        // Update the stations list
        [self updateSchedules:theSchedules reportTo:inMainWindowController];
  }
}

@end

@implementation xtvdParseThread

+ (void) performParse:(id)parseInfo
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSDictionary *xtvdParserData = (NSDictionary*)parseInfo;
  
  [XTVDParser parseXMLFile:[xtvdParserData valueForKey:@"xmlFilePath"] reportTo:[xtvdParserData valueForKey:@"reportProgressTo"]];
 
  [[NSFileManager defaultManager] removeFileAtPath:[xtvdParserData valueForKey:@"xmlFilePath"] handler:nil];
  [[xtvdParserData valueForKey:@"reportProgressTo"] performSelectorOnMainThread:@selector(parsingComplete:) withObject:nil waitUntilDone:YES];
  [pool release];
}

@end;

@implementation xtvdCleanupThread

+ (void) cleanupSchedulesIn:(NSManagedObjectContext*)inMOC before:(NSDate*)inDate
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSPredicate *oldSchedulesPredicate = [NSPredicate predicateWithFormat:@"endTime < %@", inDate];
  [request setPredicate:oldSchedulesPredicate];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  NSLog(@"cleanupSchedules - %d schedules before now", [array count]);
  if (array != nil)
  {
    NSEnumerator *scheduleEnumerator = [array objectEnumerator];
    Z2ITSchedule *aSchedule;
    while (aSchedule = [scheduleEnumerator nextObject])
    {
      [inMOC deleteObject:aSchedule];
    }
  }
}

+ (void) cleanupUnscheduledProgramsIn:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Program" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  int i=0;
  if (array != nil)
  {
    NSEnumerator *programEnumerator = [array objectEnumerator];
    Z2ITProgram *aProgram;
    while (aProgram = [programEnumerator nextObject])
    {
      NSSet *schedules = [aProgram schedules];
      if (schedules && ([schedules count] == 0))
      {
        [inMOC deleteObject:aProgram];
        i++;
      }
    }
  }
  NSLog(@"cleanupUnschedulePrograms - %d programs %d were deleted", [array count], i);
}

+ (void) performCleanup:(id)cleanupInfo
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSDictionary *xtvdCleanupInfo = (NSDictionary*)cleanupInfo;

//  NSManagedObjectContext *moc = [xtvdCleanupInfo valueForKey:@"managedObjectContext"];
  NSManagedObjectContext *moc = [[[NSApplication sharedApplication] delegate] managedObjectContext];
  NSDate *currentDate = [xtvdCleanupInfo valueForKey:@"currentDate"];
  
  [self cleanupSchedulesIn:moc before:currentDate];
  
  [self cleanupUnscheduledProgramsIn:moc];
  [[xtvdCleanupInfo valueForKey:@"reportProgressTo"] performSelectorOnMainThread:@selector(cleanupComplete:) withObject:nil waitUntilDone:YES];

  [pool release];
}

@end;

