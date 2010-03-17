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

@implementation HDHomeRunChannelStationMap

@dynamic lastUpdateDate;
@dynamic channels;
@dynamic lineup;

+ (NSArray *) allChannelStationsMapsInManagedObjectContext:(NSManagedObjectContext*)inMOC
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"HDHomeRunChannelStationMap" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  return array;
}


- (void) deleteAllChannelsInMOC:(NSManagedObjectContext *)inMOC
{
  NSArray *channelsArray = [self.channels allObjects];
  for (HDHomeRunChannel *aChannel in channelsArray)
  {
	// We need to be careful here since the MOC that 'self' is in may not be the same as the MOC
	// we're using - the data will lineup but pointers to objects in relationships will be different.
	// So use objectWithID: to retrieve the relevant channel object from the other MOC.
	HDHomeRunChannel *channelInMOC = (HDHomeRunChannel*) [inMOC objectWithID:[aChannel objectID]];
    [inMOC deleteObject:channelInMOC];
  }
}

- (void) pushMapContentsToServer
{ 
  if ([[NSApp delegate] recServer]) 
  { 
    // Start by adding all the channels on this tuner to an array 
    NSMutableSet *channelsSet = [self mutableSetValueForKey:@"channels"]; 

    if ([channelsSet count] > 0)
    {
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
}

@end

#if 0
/*
 *
 * You do not need any of these.  
 * These are templates for writing custom functions that override the default CoreData functionality.
 * You should delete all the methods that you do not customize.
 * Optimized versions will be provided dynamically by the framework.
 *
 *
*/


// coalesce these into one @interface HDHomeRunChannelStationMap (CoreDataGeneratedPrimitiveAccessors) section
@interface HDHomeRunChannelStationMap (CoreDataGeneratedPrimitiveAccessors)

- (NSDate *)primitiveLastUpdateDate;
- (void)setPrimitiveLastUpdateDate:(NSDate *)value;

- (Z2ITLineup)primitiveLineup;
- (void)setPrimitiveLineup:(Z2ITLineup)value;

- (NSMutableSet*)primitiveChannels;
- (void)setPrimitiveChannels:(NSMutableSet*)value;

@end

- (NSDate *)lastUpdateDate 
{
    NSDate * tmpValue;
    
    [self willAccessValueForKey:@"lastUpdateDate"];
    tmpValue = [self primitiveLastUpdateDate];
    [self didAccessValueForKey:@"lastUpdateDate"];
    
    return tmpValue;
}

- (void)setLastUpdateDate:(NSDate *)value 
{
    [self willChangeValueForKey:@"lastUpdateDate"];
    [self setPrimitiveLastUpdateDate:value];
    [self didChangeValueForKey:@"lastUpdateDate"];
}

- (BOOL)validateLastUpdateDate:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}


- (void)addChannelsObject:(HDHomeRunChannel *)value 
{    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveChannels] addObject:value];
    [self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)removeChannelsObject:(HDHomeRunChannel *)value 
{
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    
    [self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveChannels] removeObject:value];
    [self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    
    [changedObjects release];
}

- (void)addChannels:(NSSet *)value 
{    
    [self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveChannels] unionSet:value];
    [self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeChannels:(NSSet *)value 
{
    [self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveChannels] minusSet:value];
    [self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


- (Z2ITLineup *)lineup 
{
    id tmpObject;
    
    [self willAccessValueForKey:@"lineup"];
    tmpObject = [self primitiveLineup];
    [self didAccessValueForKey:@"lineup"];
    
    return tmpObject;
}

- (void)setLineup:(Z2ITLineup *)value 
{
    [self willChangeValueForKey:@"lineup"];
    [self setPrimitiveLineup:value];
    [self didChangeValueForKey:@"lineup"];
}


- (BOOL)validateLineup:(id *)valueRef error:(NSError **)outError 
{
    // Insert custom validation logic here.
    return YES;
}

#endif

