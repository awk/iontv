// libRecSchedCommon - Common code shared between UI application and background server
// Copyright (C) 2007 Andrew Kimpton
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import <Cocoa/Cocoa.h>
#import "hdhomerun.h"

@class HDHomeRun;
@class HDHomeRunChannel;
@class HDHomeRunChannelStationMap;
@class HDHomeRunStation;
@class Z2ITLineup;
@class Z2ITStation;

@interface HDHomeRunTuner : NSManagedObject {
  struct hdhomerun_device_t *mHDHomeRunDevice;
  NSOperationQueue *mOperationQueue;
}

+ (NSArray *)allTunersInManagedObjectContext:(NSManagedObjectContext *)inMOC;

@property (retain) NSNumber * index;
@property (retain) HDHomeRun * device;
@property (retain) NSString * longName;
@property (retain) NSSet* recordings;
@property (retain) Z2ITLineup * lineup;
@property (retain, nonatomic, readonly, getter=operationQueue) NSOperationQueue *mOperationQueue;

- (void)scanActionReportingProgressTo:(id)progressDisplay;
- (void)exportChannelMapTo:(NSURL *)inURL;
//- (void) importChannelMapFrom:(NSURL *)inURL;
//- (void) copyChannelsAndStationsFrom:(HDHomeRunTuner*)sourceTuner;

@end

// coalesce these into one @interface HDHomeRunTuner (CoreDataGeneratedAccessors) section
@interface HDHomeRunTuner (CoreDataGeneratedAccessors)

@end

@interface HDHomeRunChannel : NSManagedObject {

}

+ (HDHomeRunChannel *)createChannelWithType:(NSString *)inChannelType andNumber:(NSNumber *)inChannelNumber inManagedObjectContext:(NSManagedObjectContext *) inMOC;

@property (retain) NSNumber * channelNumber;
@property (retain) NSString * channelType;
@property (retain) NSString * tuningType;
@property (retain) NSSet * stations;
@property (retain) HDHomeRunChannelStationMap * channelStationMap;
@property (retain) NSNumber * transportStreamID;
@property (retain) NSNumber * frequency;

- (void)importStationsFrom:(NSArray *)inArrayOfStationDictionaries;
- (void)clearAllStations;

@end

// coalesce these into one @interface HDHomeRunChannel (CoreDataGeneratedAccessors) section
@interface HDHomeRunChannel (CoreDataGeneratedAccessors)
- (void)addStationsObject:(HDHomeRunStation *)value;
- (void)removeStationsObject:(HDHomeRunStation *)value;
- (void)addStations:(NSSet *)value;
- (void)removeStations:(NSSet *)value;

@end

@interface HDHomeRunStation : NSManagedObject {
  HDHomeRunTuner *mCurrentStreamingTuner;
}

+ (HDHomeRunStation *)createStationWithProgramNumber:(NSNumber *)inProgramNumber forChannel:(HDHomeRunChannel *)inChannel inManagedObjectContext:(NSManagedObjectContext *)inMOC;

// The capitlization on z2itStation is a little 'odd' - betware that the accessors will be
// z2itStation and setZ2itStation
@property (retain) NSString * callSign;
@property (retain) NSNumber * programNumber;
@property (retain) HDHomeRunChannel * channel;
@property (retain) Z2ITStation * z2itStation;

- (void)startStreaming;
- (void)startStreamingToPort:(int)portNumber;
- (void)stopStreaming;
- (NSData *)copyVideoData;

@end

// coalesce these into one @interface HDHomeRunStation (CoreDataGeneratedAccessors) section
@interface HDHomeRunStation (CoreDataGeneratedAccessors)
@end

