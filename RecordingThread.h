//
//  RecordingThread.h
//  recsched
//
//  Created by Andrew Kimpton on 3/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITProgram;
@class RSRecording;
@class HDHomeRunDevice;
@class RecSchedServer;

extern NSString *RSNotificationRecordingFinished;

@interface RecordingThreadController : NSObject {
  RSRecording *mRecording;
  bool mFinishRecording;
  HDHomeRunDevice *mHDHRDevice;

  NSManagedObjectContext *mThreadManagedObjectContext;
  RSRecording *mThreadRecording;
  RecSchedServer *mRecSchedServer;
}

- (id) initWithRecording:(RSRecording*)inRecording recordingServer:(RecSchedServer*)inServer;
- (void) beginRecording;
@end
