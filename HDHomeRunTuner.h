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

- (NSNumber *) index;
- (void) setIndex:(NSNumber*)value;
- (HDHomeRun*) device;
- (void) setDevice:(HDHomeRun *)value;

- (Z2ITLineup*)lineup;
- (void) setLineup:(Z2ITLineup*)value;

- (void) addChannel:(HDHomeRunChannel*)inChannel;

- (NSString*) longName;

- (void) scanActionReportingProgressTo:(id)progressDisplay;
- (void) startStreaming;
- (void) setFilterForProgramNumber:(NSNumber*)inProgramNumber;
- (void) tuneToChannel:(HDHomeRunChannel*)inChannel;
- (void) exportChannelMapTo:(NSURL *)inURL;
- (void) importChannelMapFrom:(NSURL *)inURL;
- (UInt8*) receiveVideoData:(size_t*)outBytesReceived;

- (void) releaseHDHRDevice;
- (void) createHDHRDevice;

@end

@interface HDHomeRunChannel : NSManagedObject
{
  
}

+ (HDHomeRunChannel*) createChannelWithType:(NSString*)inChannelType andNumber:(NSNumber*)inChannelNumber inManagedObjectContext:(NSManagedObjectContext*) inMOC;

- (NSString*) channelType;
- (void) setChannelType:(NSString*)value;

- (NSNumber*) channelNumber;
- (void) setChannelNumber:(NSNumber*)value;

- (NSString*) tuningType;
- (void) setTuningType:(NSString*)value;

- (HDHomeRunTuner*)tuner;
- (void)setTuner:(HDHomeRunTuner*)value;

- (NSMutableSet *)stations;

- (void) addStation:(HDHomeRunStation*)inStation;
- (void) importStationsFrom:(NSArray*)inArrayOfStationDictionaries;

@end

@interface HDHomeRunStation : NSManagedObject
{
}

+ (HDHomeRunStation*) createStationWithProgramNumber:(NSNumber*)inProgramNumber forChannel:(HDHomeRunChannel*)inChannel inManagedObjectContext:(NSManagedObjectContext*)inMOC;

- (NSNumber*) programNumber;
- (void) setProgramNumber:(NSNumber*)value;

- (NSString*) callSign;
- (void) setCallSign:(NSString*)value;

- (HDHomeRunChannel*) channel;
- (void) setChannel:(HDHomeRunChannel*) value;

- (Z2ITStation*) Z2ITStation;
- (void) setZ2ITStation:(Z2ITStation*) value;

- (void) startStreaming;
- (void) stopStreaming;

- (UInt8*) receiveVideoData:(size_t*)outBytesReceived;

@end
