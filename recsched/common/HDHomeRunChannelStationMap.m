//
//  HDHomeRunChannelStationMap.m
//  recsched
//
//  Created by Andrew Kimpton on 5/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HDHomeRunChannelStationMap.h"
#import "HDHomeRunTuner.h"
#import "RecSchedProtocol.h"
#import "recsched_bkgd_AppDelegate.h"

@interface LineUpResponseParser : NSObject <NSXMLParserDelegate> {
  NSMutableString *currentStringValue;
  
  NSString *modulation;
  NSString *frequency;
  NSString *transportStreamID;
  NSString *programNumber;
  NSString *guideName;
  NSString *guideNumber;
  
  BOOL foundLineUpResponse;
  BOOL foundCommand;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@end

@implementation HDHomeRunChannelStationMap

@dynamic lastUpdateDate;
@dynamic channels;
@dynamic lineup;

+ (NSArray *)allChannelStationsMapsInManagedObjectContext:(NSManagedObjectContext *)inMOC {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRunChannelStationMap" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}


- (void)deleteAllChannelsInMOC:(NSManagedObjectContext *)inMOC {
  NSArray *channelsArray = [self.channels allObjects];
  for (HDHomeRunChannel *aChannel in channelsArray) {
    // We need to be careful here since the MOC that 'self' is in may not be the same as the MOC
    // we're using - the data will lineup but pointers to objects in relationships will be different.
    // So use objectWithID: to retrieve the relevant channel object from the other MOC.
    HDHomeRunChannel *channelInMOC = (HDHomeRunChannel*) [inMOC objectWithID:[aChannel objectID]];
    [inMOC deleteObject:channelInMOC];
  }
}

- (void)pushMapContentsToServer {
#if 0
  if ([[NSApp delegate] recServer]) {
    // Start by adding all the channels on this tuner to an array
    NSMutableSet *channelsSet = [self mutableSetValueForKey:@"channels"];

    if ([channelsSet count] > 0) {
      // Create an array to hold the dictionaries of channel info
      NSMutableArray *channelsOnTuner = [NSMutableArray arrayWithCapacity:[channelsSet count]];

      // Ask each HDHomeRunChannel in the set to add their info (in dictionary form) to the array
      [channelsSet makeObjectsPerformSelector:@selector(addChannelInfoDictionaryTo:) withObject:channelsOnTuner];

      NSSortDescriptor *channelDescriptor =[[[NSSortDescriptor alloc] initWithKey:@"channelNumber" ascending:YES] autorelease];
      NSArray *sortDescriptors=[NSArray arrayWithObject:channelDescriptor];
      NSArray *sortedArray=[channelsOnTuner sortedArrayUsingDescriptors:sortDescriptors];

      [[[NSApp delegate] recServer] updateChannelStationMap:[self objectID] withChannelsAndStations:sortedArray];
    }
  }
#endif
}

- (void)importLineupResponse:(NSData*)xmlData {
  NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
  LineUpResponseParser *parserDelegate = [[LineUpResponseParser alloc] init];
  [parser setDelegate:parserDelegate];
  [parser parse];
  [parserDelegate release];
  [parser release];
  
  NSError *error = nil;
  if (![[[NSApp delegate] managedObjectContext] save:&error]) {
    NSLog(@"importLineupResponse - saving context reported error %@, info = %@", error, [error userInfo]);
  }
}

@end

@implementation LineUpResponseParser

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
  if ([elementName isEqualToString:@"LineupUIResponse"]) {
    foundLineUpResponse = YES;
  }

  [currentStringValue release];
  currentStringValue = nil;
  // All other elements get handled at the end of the element.
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  if (!currentStringValue) {
    currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
  }
  [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
  if ([elementName isEqualToString:@"Command"]) {
    if ([currentStringValue isEqualToString:@"IdentifyPrograms2"]) {
      foundCommand = YES;
    }
  }
  if (foundLineUpResponse && foundCommand) {
    if ([elementName isEqualToString:@"Modulation"]) {
      modulation = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"Frequency"]) {
      frequency = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"TransportStreamID"]) {
      transportStreamID = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"ProgramNumber"]) {
      programNumber = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"GuideName"]) {
      guideName = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"GuideNumber"]) {
      guideNumber = [[NSString alloc] initWithString:currentStringValue];
    } else if ([elementName isEqualToString:@"Program"]) {
      NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
      NSEntityDescription *HDHRStationEntityDescription = [NSEntityDescription entityForName:@"HDHomeRunStation" inManagedObjectContext:moc];
      NSFetchRequest *request = [[NSFetchRequest alloc] init];
      [request setEntity:HDHRStationEntityDescription];
      
      NSPredicate *hdhrStationPredicate = [NSPredicate predicateWithFormat:
        @"(programNumber== %@) AND (channel.tuningType = %@) AND (channel.frequency == %@) AND (channel.transportStreamID == %@)",
        programNumber, modulation, frequency, transportStreamID];
      [request setPredicate:hdhrStationPredicate];
      
      NSError *error = nil;
      NSArray *hdhrStationArray = [moc executeFetchRequest:request error:&error];
      [request release];
      
      NSEntityDescription *guideStationEntityDescription = [NSEntityDescription entityForName:@"Station" inManagedObjectContext:moc];
      request = [[NSFetchRequest alloc] init];
      [request setEntity:guideStationEntityDescription];
      
      NSPredicate *guideStationPredicate = [NSPredicate predicateWithFormat:
                                              @"(callSign == %@)",
                                              guideName];
      [request setPredicate:guideStationPredicate];
      
      NSArray *guideStationArray = [moc executeFetchRequest:request error:&error];
      [request release];
      HDHomeRunStation *theHDHRStation = nil;
      Z2ITStation *theGuideStation = nil;
      if ([hdhrStationArray count] > 1) {
        NSLog(@"matched multiple HDHR stations = %@\n", hdhrStationArray);
      }
      if ([hdhrStationArray count] > 0) {
        theHDHRStation = [hdhrStationArray objectAtIndex:0];
      }
      if ([guideStationArray count] > 1) {
        NSLog(@"matched multiple Guide stations = %@\n", guideStationArray);
      }
      if ([guideStationArray count] > 0) {
        theGuideStation = [guideStationArray objectAtIndex:0];
      } else {
        NSLog(@"Could not find %@ in the guide data !\n", guideName);
      }
      if (theHDHRStation && theGuideStation) {
        [theHDHRStation setZ2itStation:theGuideStation];
      }
      
      [modulation release];
      modulation = nil;
      [frequency release];
      frequency = nil;
      [transportStreamID release];
      transportStreamID = nil;
      [programNumber release];
      programNumber = nil;
      [guideName release];
      guideName = nil;
      [guideNumber release];
      guideNumber = nil;
    } else {
//      NSLog(@"didEndElement:%@\n", elementName);
    }
  }
  [currentStringValue release];
  currentStringValue = nil;
}


@end
