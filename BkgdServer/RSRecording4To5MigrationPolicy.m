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

#import "RSRecording4To5MigrationPolicy.h"


@implementation RSRecording4To5MigrationPolicy

- (BOOL)createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
  NSArray *relationshipMappings = [mapping relationshipMappings];
  for (NSPropertyMapping *aPropertyMapping in relationshipMappings)
  {
    if ([[aPropertyMapping name] compare:@"tuner"] != NSOrderedSame)
    {
    // The other relationships are pretty straight forward - we can just use the entityMapping from Xcode to handle them
      NSExpression *migrationExpression = [aPropertyMapping valueExpression];
      NSArray *sourceInstancesArray = [manager sourceInstancesForEntityMappingNamed:[mapping name] destinationInstances:[NSArray arrayWithObject:dInstance]];
      NSManagedObject *source = nil;
      if ([sourceInstancesArray count] > 0)
        source = [sourceInstancesArray objectAtIndex:0];
      NSMutableDictionary *context = [[[NSMutableDictionary alloc] init] autorelease];
      [context setValue:manager forKey:@"manager"];
      [context setValue:source forKey:@"source"];
      id expressionResult = [migrationExpression expressionValueWithObject:nil context:context];
      if (!expressionResult)
      {
        if (error)
          *error = nil;
        return NO;
      }
    }
  }
  
  // The new tuner relationship is more tricky - in this case we need to use the recordings schedule to find the first HDHomeRunStation for the schedule
  // then use the migration manager to find the equivalent station in the new MOC and then set up a relationship in the instance 
  NSManagedObject *schedule = [dInstance valueForKey:@"schedule"];
  NSManagedObject *tuner = nil;
  if (schedule)
  {
    NSSet *hdhrStations = [schedule valueForKeyPath:@"station.hdhrStations"];
    NSManagedObject *aHDHRStation = [hdhrStations anyObject];
    tuner = [aHDHRStation valueForKeyPath:@"channel.tuner"];
    [dInstance setValue:tuner forKey:@"tuner"];
  }

  return YES;
}

@end
