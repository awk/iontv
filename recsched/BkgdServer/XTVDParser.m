//  recsched_bkgd - Background server application retrieves schedule data, performs recordings,
//  transcodes recordings in to H.264 format for iTunes, iPod etc.
//
//  Copyright (C) 2007 Andrew Kimpton
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "XTVDParser.h"
#import "recsched_AppDelegate.h"
#import "RSNotifications.h"
#import "tvDataDelivery.h"
#import "Z2ITStation.h"
#import "Z2ITSchedule.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITProgram.h"
#import "RSActivityDisplayProtocol.h"

@implementation XTVDParser

- (void)dealloc {
  [mReportProgressTo release];
  [mManagedObjectContext release];
  [super dealloc];
}

- (void)setReportProgressTo:(id)progressReporter {
  if (mReportProgressTo != progressReporter) {
    if (mReportProgressTo) {
      [mReportProgressTo release];
    }
    if ([progressReporter conformsToProtocol:@protocol(RSActivityDisplay)]) {
      mReportProgressTo = progressReporter;
      [mReportProgressTo retain];
    }
  }
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)inManagedObjectContext {
  if (inManagedObjectContext != mManagedObjectContext) {
    if (mManagedObjectContext) {
      [mManagedObjectContext release];
    }
    mManagedObjectContext = [inManagedObjectContext retain];
  }
}

- (void)parseXMLFile:(NSString *)filePath lineupsOnly:(BOOL)inLineupsOnly {
  NSXMLDocument *xmlDoc;
  NSError *err=nil;
  NSURL *furl = [NSURL fileURLWithPath:filePath];
  if (!furl) {
      NSLog(@"Can't create an URL from file %@.", filePath);
      return;
  }

  mActivityToken = [mReportProgressTo createActivity];

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
  [self traverseXMLDocument:xmlDoc lineupsOnly:inLineupsOnly];
  [xmlDoc release];
  [mReportProgressTo endActivity:mActivityToken];
}

- (void)handleError:(NSError *) error {
  NSLog(@"XTVDParser handleError: %d", [error code]);
}

- (void)updateStations:(NSXMLNode *)inStationsNode {
  NSArray *childNodes = [inStationsNode children];
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Stations"];
    mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:[childNodes count]];
  } else {
    NSLog(@"Updating Stations");
  }
  for (NSXMLNode *child in childNodes) {
    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *stationIDString = [[childElement attributeForName:@"id"] stringValue];
      int stationID = -1;
      if (stationIDString) {
        mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1.0];

        stationID = [stationIDString intValue];

        // Now for the other items in the station element node
        NSString *callSignString = nil;
        NSString *nameString = nil;
        NSString *affiliateString = nil;
        int fccChannel = 0;
        NSArray *stationChildNodes = [childElement children];
        for (NSXMLNode *stationChild in stationChildNodes) {
          if ([[stationChild name] compare:@"callSign" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            callSignString = [stationChild stringValue];
          } else if ([[stationChild name] compare:@"name" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            nameString = [stationChild stringValue];
          } else if ([[stationChild name] compare:@"affiliate" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            affiliateString = [stationChild stringValue];
          } else if ([[stationChild name] compare:@"fccChannelNumber" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            fccChannel = [[stationChild stringValue] intValue];;
          }
        }

        // If the station already exists we might need to update it's info
        Z2ITStation *aStation = [Z2ITStation fetchStationWithID:[NSNumber numberWithInt:stationID] inManagedObjectContext:mManagedObjectContext];
        if (aStation == nil) {
          // Otherwise we just create a new one
          aStation = [NSEntityDescription insertNewObjectForEntityForName:@"Station"
                                                   inManagedObjectContext:mManagedObjectContext];
          [aStation setStationID:[NSNumber numberWithInt:stationID]];
        }

        [aStation setCallSign:callSignString];
        [aStation setName:nameString];
        if (affiliateString) {
          [aStation setAffiliate:affiliateString];
        } else {
          [aStation setAffiliate:nil];
        }
        if (fccChannel > 0) {
          [aStation setFccChannelNumber:[NSNumber numberWithInt:fccChannel]];
        } else {
          [aStation setFccChannelNumber:nil];
        }
        aStation = NULL;
      }
    }
  }
}

- (void)updateLineups:(NSXMLNode *)inLineupsNode {
  NSArray *childNodes = [inLineupsNode children];
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Lineups"];
  } else {
    NSLog(@"Updating Lineups");
  }
  for (NSXMLNode *child in childNodes) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *lineupIDString = [[childElement attributeForName:@"id"] stringValue];
      if (lineupIDString) {
        NSString *lineupNameString = [[childElement attributeForName:@"name"] stringValue];
        NSString *userLineupNameString = [[childElement attributeForName:@"userLineupName"] stringValue];
        NSString *locationString = [[childElement attributeForName:@"location"] stringValue];
        NSString *deviceString = [[childElement attributeForName:@"device"] stringValue];
        NSString *typeString = [[childElement attributeForName:@"type"] stringValue];
        NSString *postalCodeString = [[childElement attributeForName:@"postalCode"] stringValue];

        // If the lineup already exists we might need to update it's info
        Z2ITLineup *aLineup = [Z2ITLineup allocLineupWithID:lineupIDString inManagedObjectContext:mManagedObjectContext];
        if (aLineup == nil) {
          // Otherwise we just create a new one
          aLineup = [NSEntityDescription insertNewObjectForEntityForName:@"Lineup"
                                                  inManagedObjectContext:mManagedObjectContext];
          [aLineup retain];
        }

        [aLineup setLineupID:lineupIDString];
        [aLineup setName:lineupNameString];
        [aLineup setType:typeString];
        [aLineup setLocation:locationString];

        if (postalCodeString) {
          [aLineup setPostalCode:postalCodeString];
        }
        if (deviceString) {
          [aLineup setDevice:deviceString];
        }
        if (userLineupNameString) {
          [aLineup setUserLineupName:userLineupNameString];
        }
        // Now for the map items in the lineup element node
        NSArray *lineupChildNodes = [childElement children];
        mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:[lineupChildNodes count]];
        for (NSXMLElement *lineupMap in lineupChildNodes) {
          NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
          NSNumber *stationIDNumber = nil;
          NSString *channelString = nil;
          NSNumber *channelMinorNumber = nil;
          NSDate *fromDate = nil;
          NSDate *toDate = nil;

          NSString *tmpStr;

          mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1];

          tmpStr = [[lineupMap attributeForName:@"station"] stringValue];
          if (tmpStr) {
            stationIDNumber = [NSNumber numberWithInt:[tmpStr intValue]];
          } else {
            NSLog(@"XTVDParser - lineup map %@ has invalid station field", lineupMap);
          }
          channelString = [[lineupMap attributeForName:@"channel"] stringValue];
          tmpStr = [[lineupMap attributeForName:@"channelMinor"] stringValue];
          if (tmpStr) {
            channelMinorNumber = [NSNumber numberWithInt:[tmpStr intValue]];
          }
          tmpStr = [[lineupMap attributeForName:@"from"] stringValue];
          if (tmpStr) {
            fromDate = [NSDate dateWithNaturalLanguageString:tmpStr];
          }
          tmpStr = [[lineupMap attributeForName:@"to"] stringValue];
          if (tmpStr) {
            toDate = [NSDate dateWithNaturalLanguageString:tmpStr];
          }
          Z2ITStation *mapStation = [Z2ITStation fetchStationWithID:stationIDNumber inManagedObjectContext:mManagedObjectContext];
          if (mapStation) {
            Z2ITLineupMap *aLineupMap = [aLineup fetchLineupMapWithStationID:stationIDNumber];
            BOOL addLineup = NO;
            if (!aLineupMap) {
              aLineupMap = [NSEntityDescription insertNewObjectForEntityForName:@"LineupMap"
                                                         inManagedObjectContext:mManagedObjectContext];
              addLineup = YES;
            }

            [aLineupMap setStation:mapStation];
            [aLineupMap setChannel:channelString];
            if (channelMinorNumber) {
              [aLineupMap setChannelMinor:channelMinorNumber];
            }
            if (fromDate) {
              [aLineupMap setFrom:fromDate];
            }
            if (toDate) {
              [aLineupMap setTo:toDate];
            }
            if (addLineup) {
              [aLineup addLineupMapsObject:aLineupMap];
            }
            aLineupMap = NULL;
          } else {
//            NSLog(@"updateLineups - Failed to find station with ID %@", stationIDNumber);
          }

        [subPool release];
      }

      [aLineup release];
      aLineup = nil;
      }
    }
    [subPool release];
  }
}

// Compare two programs for their program ID
NSInteger compareProgramsByIDAttribute(id thisXMLProgramNode, id otherXMLProgramNode, void *context)
{
  NSString *programIDStringThisXMLProgramNode = [[thisXMLProgramNode attributeForName:@"id"] stringValue];
  NSString *programIDStringOtherXMLProgramNode = [[otherXMLProgramNode attributeForName:@"id"] stringValue];
  return [programIDStringThisXMLProgramNode compare:programIDStringOtherXMLProgramNode];
}

- (void)updatePrograms:(NSXMLNode *)inProgramsNode {
  NSArray *childNodes = nil;
  int i, count = 0;
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Programs"];
  } else {
    NSLog(@"Updating Programs");
  }
  childNodes  = [[inProgramsNode children] sortedArrayUsingFunction:compareProgramsByIDAttribute context:nil];
  count = [childNodes count];
  mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:count];

  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"id"] stringValue];
      if (programIDString) {
        [programIDArray addObject:programIDString];
      }
    }
    [subPool release];
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray inManagedObjectContext:mManagedObjectContext];
  [programIDArray release];
  programIDArray = nil;

  int existingProgramIndex = 0;
  int existingProgramCount = [existingProgramsArray count];
  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"id"] stringValue];
      if (programIDString) {
        mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1.0];

        Z2ITProgram *aProgram  = nil;

        if ((existingProgramIndex < existingProgramCount) && ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)) {
//          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          // We should check and update the program details here - they may have changed.
          existingProgramIndex++;
        } else {
          aProgram = [NSEntityDescription insertNewObjectForEntityForName:@"Program"
                                                   inManagedObjectContext:mManagedObjectContext];

          [aProgram setProgramID:programIDString];
          [aProgram initializeWithXMLElement:childElement];
        }
      }
    }
  [subPool release];
  }
}

NSInteger compareXMLNodeByProgramAttribute(id thisXMLProgramNode, id otherXMLProgramNode, void *context)
{
  NSString *programIDStringThisXMLCrewNode = [[thisXMLProgramNode attributeForName:@"program"] stringValue];
  NSString *programIDStringOtherXMLCrewNode = [[otherXMLProgramNode attributeForName:@"program"] stringValue];
  return [programIDStringThisXMLCrewNode compare:programIDStringOtherXMLCrewNode];
}

- (void) updateProductionCrew:(NSXMLNode *)inProductionCrewNode {
  NSArray *childNodes = nil;
  int i, count = 0;
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Production Crew"];
  } else {
    NSLog(@"Updating Production Crew");
  }
  childNodes  = [[inProductionCrewNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:count];

  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        [programIDArray addObject:programIDString];
      }
    }
    [subPool release];
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray inManagedObjectContext:mManagedObjectContext];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;

  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1.0];

      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        Z2ITProgram *aProgram  = nil;
        if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame) {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          existingProgramIndex++;
        } else {
          NSLog(@"updateProductionCrew - could not find a program with id %@", programIDString);
        }
        if (aProgram) {
          [aProgram addProductionCrewWithXMLElement:childElement];
        }
      }
    }
    [subPool release];
  }
}

- (void)updateGenres:(NSXMLNode *)inGenresNode {
  NSArray *childNodes = nil;
  int i, count = 0;
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Genres"];
  } else {
    NSLog(@"Updating Genres");
  }
  childNodes = [[inGenresNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:count];

  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        [programIDArray addObject:programIDString];
      }
    }
    [subPool release];
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray inManagedObjectContext:mManagedObjectContext];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;

  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1.0];

      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        Z2ITProgram *aProgram  = nil;
        if ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame) {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          existingProgramIndex++;
        } else {
          NSLog(@"updateGenres - could not find a program with id %@", programIDString);
        }
        if (aProgram) {
          [aProgram addGenreWithXMLElement:childElement];
        }
      }
    }
    [subPool release];
  }
}

- (void) updateSchedules:(NSXMLNode *)inSchedulesNode {
  NSArray *childNodes = nil;
  int i, count;
  if (mReportProgressTo) {
    mActivityToken = [mReportProgressTo setActivity:mActivityToken infoString:@"Updating Schedules"];
  } else {
    NSLog(@"Updating Schedules");
  }
  childNodes = [[inSchedulesNode children] sortedArrayUsingFunction:compareXMLNodeByProgramAttribute context:nil];
  count = [childNodes count];
  mActivityToken = [mReportProgressTo setActivity:mActivityToken progressMaxValue:count];
  NSMutableArray *programIDArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        [programIDArray addObject:programIDString];
      }
    }
    [subPool release];
  }
  [programIDArray sortUsingSelector:@selector(compare:)];
  NSArray *existingProgramsArray;
  existingProgramsArray = [Z2ITProgram fetchProgramsWithIDS:programIDArray inManagedObjectContext:mManagedObjectContext];
  [programIDArray release];
  programIDArray = nil;
  int existingProgramIndex = 0;

  for (i=0; i < count; i++) {
    NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSXMLNode *child = [childNodes objectAtIndex:i];

    NSXMLNodeKind nodeKind = [child kind];
    if (nodeKind == NSXMLElementKind) {
      NSXMLElement *childElement = (NSXMLElement *)child;
      mActivityToken = [mReportProgressTo setActivity:mActivityToken incrementBy:1.0];

      NSString *programIDString = [[childElement attributeForName:@"program"] stringValue];
      if (programIDString) {
        Z2ITProgram *aProgram  = nil;

        // A program might exist more than once in the schedule, so we may have multiple sequential entries for the same program,
        // instead of advancing with each successful test we advance only if we don't have a match
        if ((existingProgramIndex < [existingProgramsArray count]) &&
            ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)) {
          aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
        }

        if (!aProgram) {
          existingProgramIndex++;
          if ((existingProgramIndex < [existingProgramsArray count]) &&
              ([programIDString compare:[[existingProgramsArray objectAtIndex:existingProgramIndex] programID]] == NSOrderedSame)) {
            aProgram = [existingProgramsArray objectAtIndex:existingProgramIndex];
          }
        }

        if (aProgram) {
          [aProgram addScheduleWithXMLElement:childElement];
        } else {
          NSLog(@"updateSchedules - could not find a program with id %@", programIDString);
        }
      }
    }
    [subPool release];
  }
}

- (void)traverseXMLDocument:(NSXMLDocument *) inXMLDocument lineupsOnly:(BOOL)inLineupsOnly {
  NSError *err;
  NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
  NSArray *nodes = [inXMLDocument nodesForXPath:@"//stations" error:&err];
  if ([nodes count] > 0 ) {
    NSXMLNode* theStations = [nodes objectAtIndex:0];
    // Update the stations list
    [self updateStations:theStations];
  }
  nodes = [inXMLDocument nodesForXPath:@"//lineups" error:&err];
  if ([nodes count] > 0 ) {
    NSXMLNode* theLineups = [nodes objectAtIndex:0];
    // Update the stations list
    [self updateLineups:theLineups];
  }
  [subPool release];

  subPool = [[NSAutoreleasePool alloc] init];
  nodes = [inXMLDocument nodesForXPath:@"//programs" error:&err];
  if (([nodes count] > 0 ) && !inLineupsOnly) {
    NSXMLNode* thePrograms = [nodes objectAtIndex:0];
    // Update the stations list
    [self updatePrograms:thePrograms];
  }
  [subPool release];

#if 0
  subPool = [[NSAutoreleasePool alloc] init];
  nodes = [inXMLDocument nodesForXPath:@"//productionCrew" error:&err];
  if (([nodes count] > 0 ) && !inLineupsOnly)
  {
        NSXMLNode* theProductionCrew = [nodes objectAtIndex:0];
        // Update the stations list
        [self updateProductionCrew:theProductionCrew];
  }
  [subPool release];
#endif

  subPool = [[NSAutoreleasePool alloc] init];
  nodes = [inXMLDocument nodesForXPath:@"//genres" error:&err];
  if (([nodes count] > 0 ) && !inLineupsOnly) {
    NSXMLNode* theGenres = [nodes objectAtIndex:0];
    // Update the genres list
    [self updateGenres:theGenres];
  }
  [subPool release];

  subPool = [[NSAutoreleasePool alloc] init];
  nodes = [inXMLDocument nodesForXPath:@"//schedules" error:&err];
  if (([nodes count] > 0 ) && !inLineupsOnly) {
    NSXMLNode* theSchedules = [nodes objectAtIndex:0];
    // Update the stations list
    [self updateSchedules:theSchedules];
  }
  [subPool release];
}

@end

@implementation xtvdCleanupOperation

- (id) initWithCleanupDate:(NSDate *)cleanupDate
          progressReporter:(NSObject<RSActivityDisplay> *)progressReporter {
  if (self = [super init]) {
    mCleanupDate = [cleanupDate retain];
    mProgressReporter = [progressReporter retain];
  }
  return self;
}

- (void) dealloc {
  [mProgressReporter release];
  [mCleanupDate release];
  [super dealloc];
}

- (void)cleanupSchedulesIn:(NSManagedObjectContext *)inMOC before:(NSDate *)inDate {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSPredicate *oldSchedulesPredicate = [NSPredicate predicateWithFormat:@"(endTime < %@) AND (recording == nil) AND (transcoding == nil)", inDate];
  [request setPredicate:oldSchedulesPredicate];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  NSLog(@"cleanupSchedules - %d schedules before now", [array count]);
  if (array != nil) {
    Z2ITSchedule *aSchedule;
    for (aSchedule in array) {
      [inMOC deleteObject:aSchedule];
    }
  }
  [inMOC processPendingChanges];
}

- (void)cleanupUnscheduledProgramsIn:(NSManagedObjectContext *)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Program" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  int i=0;
  if (array != nil) {
    Z2ITProgram *aProgram;
    for (aProgram in array) {
      NSSet *schedules = [aProgram schedules];
      if ((schedules && ([schedules count] == 0)) || (schedules == nil)) {
        [inMOC deleteObject:aProgram];
        i++;
      }
    }
  }
  [inMOC processPendingChanges];
  NSLog(@"cleanupUnschedulePrograms - %d programs %d were deleted", [array count], i);
}

- (void)main {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSPersistentStoreCoordinator *psc = [[NSApp delegate] persistentStoreCoordinator];
  if (psc != nil) {
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: psc];
    
    [self cleanupSchedulesIn:managedObjectContext before:mCleanupDate];
    
    [self cleanupUnscheduledProgramsIn:managedObjectContext];
    
    NSError *error = nil;
    // when the lineup retrieval and MOC saves, we want to update the same object in the UI's MOC.
    // So listen for the did save notification from the retrieval/parsing thread MOC
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    
    NSLog(@"performCleanup - saving");
    if (![managedObjectContext save:&error]) {
      NSLog(@"performCleanup - save returned an error %@", error);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    
    [managedObjectContext release];
  }
  [pool release];
}

#pragma mark - Notifications

/**
 Notification sent out when the threads own managedObjectContext has been.  This method
 ensures updates from the thread (which has its own managed object
 context) are merged into the application managed object content, so the
 user always sees the most current information.
 */

- (void)threadContextDidSave:(NSNotification *)notification {
  RSCommonAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
  if ([appDelegate respondsToSelector:@selector(updateForSavedContext:)]) {
    [appDelegate performSelectorOnMainThread:@selector(updateForSavedContext:) withObject:notification waitUntilDone:YES];
  }
}

@end

@implementation xtvdParseOperation

- (id) initWithFilePath:(NSString *)filePath
       progressReporter:(NSObject<RSActivityDisplay> *)progressReporter
            lineupsOnly:(BOOL)lineupsOnly {
  if (self = [super init]) {
    _progressReporter = [progressReporter retain];
    _lineupsOnly = lineupsOnly;
    _xmlFilePath = [filePath retain];
  }
  return self;
}

- (void) dealloc {
  [_progressReporter release];
  [_xmlFilePath release];
  [super dealloc];
}

- (void)main {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSError *error = nil;
  
  NSPersistentStoreCoordinator *psc = [[NSApp delegate] persistentStoreCoordinator];
  if (psc == nil) {
    goto exit;
  }
  
  XTVDParser *anXTVDParser = [[XTVDParser alloc] init];
  NSManagedObjectContext *parseMOC = [[NSManagedObjectContext alloc] init];
  [parseMOC setPersistentStoreCoordinator:psc];  
  if (parseMOC == nil) {
    goto exit;
  }
  
  [anXTVDParser setManagedObjectContext:parseMOC];
  
  [anXTVDParser setReportProgressTo:_progressReporter];
  
  // when the lineup retrieval and MOC saves, we want to update the same object in the UI's MOC.
  // So listen for the did save notification from the retrieval/parsing thread MOC
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(threadContextDidSave:)
                                               name:NSManagedObjectContextDidSaveNotification object:parseMOC];
  
  [anXTVDParser parseXMLFile:_xmlFilePath lineupsOnly:_lineupsOnly];
  [anXTVDParser release];
  
  [parseMOC processPendingChanges];
  
  NSLog(@"performParse - saving");
  if (![parseMOC save:&error]) {
    NSLog(@"performParse - save returned an error %@", error);
  }
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:parseMOC];
  
  [[NSFileManager defaultManager] removeItemAtPath:_xmlFilePath error:&error];
  
exit:
  [parseMOC release];
  [pool drain];
}

/**
 Notification sent out when the threads own managedObjectContext has been.  This method
 ensures updates from the thread (which has its own managed object
 context) are merged into the application managed object content, so the
 user always sees the most current information.
 */

- (void)threadContextDidSave:(NSNotification *)notification {
  RSCommonAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
  if ([appDelegate respondsToSelector:@selector(updateForSavedContext:)]) {
    [appDelegate performSelectorOnMainThread:@selector(updateForSavedContext:) withObject:notification waitUntilDone:YES];
  }
}

@end
