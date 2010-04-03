//
//  HDHomeRunChannelStationMap.m
//  recsched
//
//  Created by Andrew Kimpton on 5/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ASIHTTPRequest.h"
#import "HDHomeRunChannelStationMap.h"
#import "HDHomeRunTuner.h"
#import "RecSchedProtocol.h"
#import "recsched_bkgd_AppDelegate.h"
#import "Z2ITLineup.h"
#import "Z2ITStation.h"

@interface LineUpResponseParser : NSObject <NSXMLParserDelegate> {
  NSMutableString *currentStringValue;
  
  NSString *modulation;
  NSString *frequency;
  NSString *transportStreamID;
  NSString *programNumber;
  NSString *guideName;
  NSString *guideNumber;
  
  NSManagedObjectContext *managedObjectContext;
  Z2ITLineup *lineup;
  
  BOOL foundLineUpResponse;
  BOOL foundCommand;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) Z2ITLineup *lineup;

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

- (NSData *)createChannelMapExportXMLDataWithDeviceID:(int)deviceID {
  // Start by adding all the channels on this tuner to an array
  NSSet *channelsSet = [self channels];
  //[self mutableSetValueForKey:@"lineup.channelStationMap.channels"];
  
  NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"LineupUIRequest"];
  NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
  [xmlDoc setVersion:@"1.0"];
  [xmlDoc setCharacterEncoding:@"UTF-8"];
  [xmlDoc setStandalone:YES];
  
  // The first part of the document should look like:
  // <Vendor>iontv-app.com</Vendor>
  // <Application>iOnTV v1.0 (Mac OS X)</Application>
  // <Command>IdentifyPrograms2</Command>
  // <UserID>ION:1</UserID>
  // <DeviceID>0x10100b88</DeviceID>
  // <Location>US:01890</Location>
  
  NSXMLElement *anElement = nil;
  
  anElement = [[NSXMLElement alloc] initWithName:@"Vendor"];
  [anElement setStringValue:@"iontv-app.com"];
  [root addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"Application"];
  [anElement setStringValue:@"iOnTV v1.0 (Mac OS X)"];
  [root addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"Command"];
  [anElement setStringValue:@"IdentifyPrograms2"];
  [root addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"UserID"];
  [anElement setStringValue:@"ION:1"];
  [root addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"DeviceID"];
  [anElement setStringValue:[NSString stringWithFormat:@"0x%x", deviceID]];
  [root addChild:anElement];
  [anElement release];
  
  anElement = [[NSXMLElement alloc] initWithName:@"Location"];
  [anElement setStringValue:[NSString stringWithFormat:@"US:%@", self.lineup.postalCode]];
  [root addChild:anElement];
  [anElement release];
  
  // Ask each HDHomeRunChannel in the set to add their info (in dictionary form) to the array
  [channelsSet makeObjectsPerformSelector:@selector(addChannelInfoTo:) withObject:root];
  
  NSData *xmlData;
  xmlData = [xmlDoc XMLDataWithOptions:NSXMLDocumentTidyXML];
  [xmlDoc release];
  
  return xmlData;
}

- (void)importLineupResponse:(NSData*)xmlData {
  NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
  LineUpResponseParser *parserDelegate = [[LineUpResponseParser alloc] init];
  parserDelegate.managedObjectContext = [self managedObjectContext];
  parserDelegate.lineup = self.lineup;
  [parser setDelegate:parserDelegate];
  [parser parse];
  [parserDelegate release];
  [parser release];
}

- (void)updateMapUsingSDLineupServerWithDeviceID:(int)deviceID {
#if BUILDING_BKGD_APP
  NSData *xmlData = [self createChannelMapExportXMLDataWithDeviceID:deviceID];
  NSURL *url = [NSURL URLWithString:@"https://www.silicondust.com/hdhomerun/lineup_dvr.fcgi?Cmd=IdentifyPrograms2"];
  ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
  [request appendPostData:xmlData];
  [request startSynchronous];
  NSError *error = [request error];
  if (!error) {
    NSData *responseData = [request responseData];
    [self importLineupResponse:responseData];
  }
#endif // BUILDING_BKGD_APP
}

@end

@implementation LineUpResponseParser

@synthesize managedObjectContext;
@synthesize lineup;

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
      HDHomeRunStation *theHDHRStation = nil;
      Z2ITStation *theGuideStation = [Z2ITStation fetchStationWithCallSign:guideName inLineup:self.lineup inManagedObjectContext:self.managedObjectContext];

      for (HDHomeRunChannel *aHDHRChannel in self.lineup.channelStationMap.channels) {
        for (HDHomeRunStation *aHDHRStation in aHDHRChannel.stations) {
          if (([aHDHRStation.programNumber intValue] == [programNumber intValue]) &&
              ([aHDHRChannel.frequency intValue] == [frequency intValue]) &&
              ([aHDHRChannel.transportStreamID intValue] == [transportStreamID intValue])) {
            theHDHRStation = aHDHRStation;
            break;
          }
        }
        if (theHDHRStation != nil) {
          break;
        }
      }
      
      if (!theHDHRStation) {
        NSLog(@"Could not find HDHR station program num %@, channel.frequency %@ channel.TSID %@\n", programNumber, frequency, transportStreamID);
      }
      
      if (!theGuideStation) {
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
