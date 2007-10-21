//
//  HDHomeRunTuner.h
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "hdhomerun_os.h"
#import "hdhomerun_debug.h"       // Fixes warning from undefined type in device header
#import "hdhomerun_device.h"

@class HDHomeRun;
@class HDHomeRunChannel;
@class HDHomeRunStation;
@class Z2ITLineup;
@class Z2ITStation;

@interface HDHomeRunTuner : NSManagedObject {
  struct hdhomerun_device_t *mHDHomeRunDevice;
  id mCurrentProgressDisplay;
  HDHomeRunChannel *mCurrentHDHomeRunChannel;
}

@property (retain) NSNumber * index;
@property (retain) NSSet* channels;
@property (retain) HDHomeRun * device;
@property (retain) Z2ITLineup * lineup;
@property (retain) NSString * longName;

- (void) scanActionReportingProgressTo:(id)progressDisplay;
- (void) exportChannelMapTo:(NSURL *)inURL;
- (void) importChannelMapFrom:(NSURL *)inURL;

#if 0
- (void) startStreaming;
- (void) setFilterForProgramNumber:(NSNumber*)inProgramNumber;
- (void) tuneToChannel:(HDHomeRunChannel*)inChannel;
- (NSData*) receiveVideoData;

- (void) releaseHDHRDevice;
- (void) createHDHRDevice;
#endif

@end

// coalesce these into one @interface HDHomeRunTuner (CoreDataGeneratedAccessors) section
@interface HDHomeRunTuner (CoreDataGeneratedAccessors)
- (void)addChannelsObject:(HDHomeRunChannel *)value;
- (void)removeChannelsObject:(HDHomeRunChannel *)value;
- (void)addChannels:(NSSet *)value;
- (void)removeChannels:(NSSet *)value;

@end

@interface HDHomeRunChannel : NSManagedObject
{
  
}

+ (HDHomeRunChannel*) createChannelWithType:(NSString*)inChannelType andNumber:(NSNumber*)inChannelNumber inManagedObjectContext:(NSManagedObjectContext*) inMOC;

@property (retain) NSNumber * channelNumber;
@property (retain) NSString * channelType;
@property (retain) NSString * tuningType;
@property (retain) NSSet* stations;
@property (retain) HDHomeRunTuner * tuner;

- (void) importStationsFrom:(NSArray*)inArrayOfStationDictionaries;
- (void) clearAllStations;

@end

// coalesce these into one @interface HDHomeRunChannel (CoreDataGeneratedAccessors) section
@interface HDHomeRunChannel (CoreDataGeneratedAccessors)
- (void)addStationsObject:(HDHomeRunStation *)value;
- (void)removeStationsObject:(HDHomeRunStation *)value;
- (void)addStations:(NSSet *)value;
- (void)removeStations:(NSSet *)value;

@end

@interface HDHomeRunStation : NSManagedObject
{
}

+ (HDHomeRunStation*) createStationWithProgramNumber:(NSNumber*)inProgramNumber forChannel:(HDHomeRunChannel*)inChannel inManagedObjectContext:(NSManagedObjectContext*)inMOC;

// The capitlization on z2itStation is a little 'odd' - betware that the accessors will be
// z2itStation and setZ2itStation
@property (retain) NSString * callSign;
@property (retain) NSNumber * programNumber;
@property (retain) HDHomeRunChannel * channel;
@property (retain) Z2ITStation * z2itStation;

- (void) startStreaming;
- (void) stopStreaming;
- (NSData *) receiveVideoData;

@end

// coalesce these into one @interface HDHomeRunStation (CoreDataGeneratedAccessors) section
@interface HDHomeRunStation (CoreDataGeneratedAccessors)
@end

