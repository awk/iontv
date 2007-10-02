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

@property (retain) NSString * channel;
@property (retain) NSNumber * channelMinor;
@property (retain) NSDate * from;
@property (retain) NSDate * to;
@property (retain) Z2ITLineup * lineup;
@property (retain) Z2ITStation * station;

@end

// coalesce these into one @interface Z2ITLineupMap (CoreDataGeneratedAccessors) section
@interface Z2ITLineupMap (CoreDataGeneratedAccessors)
@end
