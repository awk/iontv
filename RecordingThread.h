//
//  RecordingThread.h
//  recsched
//
//  Created by Andrew Kimpton on 3/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITProgram;
@class Z2ITSchedule;
@class HDHomeRunDevice;

@interface RecordingThreadController : NSObject {
  Z2ITSchedule *mSchedule;
  bool mFinishRecording;
  HDHomeRunDevice *mHDHRDevice;

  NSManagedObjectContext *mThreadManagedObjectContext;
  Z2ITSchedule *mThreadSchedule;
}

- (id) initWithSchedule:(Z2ITSchedule*)inSchedule;
- (void) beginRecording;
@end
