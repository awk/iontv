//  Copyright (c) 2007, Andrew Kimpton
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
