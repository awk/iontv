//
//  Z2ITLineupMap.h
//  recsched
//
//  Created by Andrew Kimpton on 1/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Z2ITStation;
@class Z2ITLineup;

@interface Z2ITLineupMap : NSManagedObject {

}

// Accessor and mutator for the Station ID relationship
- (Z2ITStation *)station;
- (void)setStation:(Z2ITStation *)value;

// Accessor and mutator for the Lineup relationship
- (Z2ITLineup *)lineup;
- (void)setLineup:(Z2ITLineup *)value;

// Accessor and mutator for the channel attribute
- (NSString *)channel;
- (void)setChannel:(NSString *)value;

// Accessor and mutator for the from attribute
- (NSDate *)from;
- (void)setFrom:(NSDate *)value;

// Accessor and mutator for the to attribute
- (NSDate *)to;
- (void)setTo:(NSDate *)value;

// Accessor and mutator for the channe minor attribute
- (NSNumber *)channelMinor;
- (void)setChannelMinor:(NSNumber *)value;
@end
