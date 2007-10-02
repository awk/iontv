//
//  Z2ITLineupMap.m
//  recsched
//
//  Created by Andrew Kimpton on 1/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITLineupMap.h"
#import "Z2ITStation.h"

@implementation Z2ITLineupMap

#pragma mark
#pragma mark Core Data accessors/mutators/validation methods
#pragma mark



// Accessor and mutator for the Station relationship
- (Z2ITStation *)station
{
    Z2ITStation * tmpValue;
    
    [self willAccessValueForKey: @"station"];
    tmpValue = [self primitiveValueForKey: @"station"];
    [self didAccessValueForKey: @"station"];
    
    return tmpValue;
}

- (void)setStation:(Z2ITStation *)value
{
    [self willChangeValueForKey: @"station"];
    [self setPrimitiveValue: value forKey: @"station"];
    [self didChangeValueForKey: @"station"];

    // Update the station with a reference to this lineup map
    [value addLineupMap:self];
}

// Accessor and mutator for the Lineup relationship
- (Z2ITLineup *)lineup
{
    Z2ITLineup * tmpValue;
    
    [self willAccessValueForKey: @"lineup"];
    tmpValue = [self primitiveValueForKey: @"lineup"];
    [self didAccessValueForKey: @"lineup"];
    
    return tmpValue;
}

- (void)setLineup:(Z2ITLineup *)value
{
    [self willChangeValueForKey: @"lineup"];
    [self setPrimitiveValue: value forKey: @"lineup"];
    [self didChangeValueForKey: @"lineup"];
}

// Accessor and mutator for the channel attribute
- (NSString *)channel
{
    NSString * tmpValue;
    
    [self willAccessValueForKey: @"channel"];
    tmpValue = [self primitiveValueForKey: @"channel"];
    [self didAccessValueForKey: @"channel"];
    
    return tmpValue;
}

- (void)setChannel:(NSString *)value
{
    [self willChangeValueForKey: @"channel"];
    [self setPrimitiveValue: value forKey: @"channel"];
    [self didChangeValueForKey: @"channel"];
}

// Accessor and mutator for the from attribute
- (NSDate *)from
{
    NSDate * tmpValue;
    
    [self willAccessValueForKey: @"from"];
    tmpValue = [self primitiveValueForKey: @"from"];
    [self didAccessValueForKey: @"from"];
    
    return tmpValue;
}

- (void)setFrom:(NSDate *)value
{
    [self willChangeValueForKey: @"from"];
    [self setPrimitiveValue: value forKey: @"from"];
    [self didChangeValueForKey: @"from"];
}


// Accessor and mutator for the to attribute
- (NSDate *)to
{
    NSDate * tmpValue;
    
    [self willAccessValueForKey: @"to"];
    tmpValue = [self primitiveValueForKey: @"to"];
    [self didAccessValueForKey: @"to"];
    
    return tmpValue;
}

- (void)setTo:(NSDate *)value
{
    [self willChangeValueForKey: @"to"];
    [self setPrimitiveValue: value forKey: @"to"];
    [self didChangeValueForKey: @"to"];
}


// Accessor and mutator for the channel minor attribute
- (NSNumber *)channelMinor
{
    NSNumber * tmpValue;
    
    [self willAccessValueForKey: @"channelMinor"];
    tmpValue = [self primitiveValueForKey: @"channelMinor"];
    [self didAccessValueForKey: @"channelMinor"];
    
    return tmpValue;
}

- (void)setChannelMinor:(NSNumber *)value
{
    [self willChangeValueForKey: @"channelMinor"];
    [self setPrimitiveValue: value forKey: @"channelMinor"];
    [self didChangeValueForKey: @"channelMinor"];
}


@end
