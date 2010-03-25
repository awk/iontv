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

#import "recsched6To7Migration.h"
#import "HDHomeRunTuner.h"

@implementation HDHRChannelStationMapMigrationPolicy

- (BOOL)endInstanceCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
  // For each lineup in the destination create a new HDHomeRunChannelStationMap if the lineup had a mapped tuner in the source
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lineup" inManagedObjectContext:[manager sourceContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSArray *array = [[manager sourceContext] executeFetchRequest:request error:error];
  for (Z2ITLineup *aLineup in array) {
    [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunChannelStationMap" inManagedObjectContext:[manager destinationContext]];
  }

  return [super endInstanceCreationForEntityMapping:mapping manager:manager error:error];
}

- (BOOL)endRelationshipCreationForEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
  // For each lineup in the source association one of the new HDHomeRunChannelStationMap with it
  // if the lineup had one or more mapped tuners in the source.
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Lineup" inManagedObjectContext:[manager sourceContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];

  NSArray *array = [[manager sourceContext] executeFetchRequest:request error:error];
  for (Z2ITLineup *sourceLineup in array) {
    NSManagedObject *aChannelStationMap = nil;
    // Find the destination lineup that matches this one
    NSArray *destinationLineupsArray = [manager destinationInstancesForEntityMappingNamed:@"LineupToLineup" sourceInstances:[NSArray arrayWithObject:sourceLineup]];
    if ([destinationLineupsArray count] == 1) {
      NSManagedObject *destinationLineup = [destinationLineupsArray objectAtIndex:0];

      // Find an 'uninitialized' channel station map.
      NSEntityDescription *mapEntityDescription = [NSEntityDescription entityForName:@"HDHomeRunChannelStationMap" inManagedObjectContext:[manager destinationContext]];
      NSFetchRequest *mapRequest = [[[NSFetchRequest alloc] init] autorelease];
      [mapRequest setEntity:mapEntityDescription];
      NSPredicate *uninitializedPredicate = [NSPredicate predicateWithFormat:@"lineup == nil"];
      [mapRequest setPredicate:uninitializedPredicate];
      NSArray *uninitializedChannelStationMaps = [[manager destinationContext] executeFetchRequest:mapRequest error:error];
      if ([uninitializedChannelStationMaps count] > 0) {
        aChannelStationMap = [uninitializedChannelStationMaps objectAtIndex:0];
        [destinationLineup setValue:aChannelStationMap forKey:@"channelStationMap"];
      }
    } else {
      NSLog(@"Unexpected number (%d) of matching lineups in the destination !", [destinationLineupsArray count]);
    }

    if ([[sourceLineup valueForKey:@"tuners"] count] > 0) {
      if (aChannelStationMap) {
        // Now we need to get the list of channels - to do this we can take the source lineups tuners list and use one of the tuners
        NSManagedObject *sourceTuner = [[sourceLineup valueForKey:@"tuners"] anyObject];

        // Then take it's list of channels and get the matching list of channels in the destination context
        NSArray *destinationChannelsArray = [manager destinationInstancesForEntityMappingNamed:@"HDHomeRunChannelToHDHomeRunChannel" sourceInstances:[sourceTuner valueForKey:@"channels"]];
        [aChannelStationMap setValue:[NSSet setWithArray:destinationChannelsArray] forKey:@"channels"];
      } else {
        NSLog(@"Unable to find an uninitialized channel station map !");
      }
    }
  }

  return [super endRelationshipCreationForEntityMapping:mapping manager:manager error:error];
}

@end
