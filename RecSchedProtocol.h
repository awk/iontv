/*
 *  RecSchedProtocol.h
 *  recsched
 *
 *  Created by Andrew Kimpton on 3/6/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

extern NSString *kRecServerConnectionName;

@protocol RecSchedServerProto

- (void) activityDisplayAvailable;
- (void) activityDisplayUnavailable;
- (void) storeUpdateAvailable;
- (void) storeUpdateUnavailable;

- (BOOL) addRecordingOfSchedule:(NSManagedObjectID*)scheduleObjectID;

- (void) reloadPreferences:(id)sender;

- (oneway void) quitServer:(id)sender;

// Schedule Retrieval
- (oneway void) performDownload:(NSDictionary*)callData;

// HDHomeRun Device Management
- (BOOL) addHDHomeRunWithID:(NSNumber*)deviceID;
- (void) setHDHomeRunDeviceWithID:(NSNumber*)deviceID nameTo:(NSString*)name tuner0LineupIDTo:(NSString*)tuner0LineupID tuner1LineupIDTo:(NSString*) tuner1LineupID;
- (oneway void) setHDHomeRunChannelsAndStations:(NSArray*)channelsArray onDeviceID:(int)deviceID forTunerIndex:(int)tunerIndex; 
@end
