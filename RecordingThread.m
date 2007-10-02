//
//  RecordingThread.m
//  recsched
//
//  Created by Andrew Kimpton on 3/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecordingThread.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
//#import "HDHomeRunMO.h"

@implementation RecordingThreadController

+ (void) recordingThreadStarted:(id)aRecordingThreadController
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  RecordingThreadController *theController = (RecordingThreadController*)aRecordingThreadController;
  [theController beginRecording];
  
  NSLog(@"recordingThread - EXIT");
  [pool release];
}

- (id) initWithProgram:(Z2ITProgram *)inProgram andSchedule:(Z2ITSchedule*)inSchedule
{
  self = [super init];
  if (self != nil) {
    mProgram = [inProgram retain];
    mSchedule = [inSchedule retain];
    
    NSTimer *recordingStartTimer = [[NSTimer alloc] initWithFireDate:[mSchedule time] interval:0 target:self selector:@selector(startRecordingTimerFired:) userInfo:self repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:recordingStartTimer forMode:NSDefaultRunLoopMode];
  }
  return self;
}

- (void) startRecordingTimerFired:(NSTimer*)inTimer
{
  [NSThread detachNewThreadSelector:@selector(recordingThreadStarted:) toTarget:[RecordingThreadController class] withObject:self];
}

- (void) beginRecording
{
  NSLog(@"beginRecording - timer fired for schedule %@ program %@", mSchedule, mProgram);
  
  // Create a HDHomeRunDevice to use
//  mHDHRDevice = [[HDHomeRunDevice alloc] initWithDeviceID:0x10100B88 forTuner:0];
//  if (mHDHRDevice == nil)
//  {
//    NSLog(@"beginRecording - failed to allocate and HDHomeRunDevice");
//    return;
//  }
  
  // We need to set up the HDHomeRun to save the program to a file - we must
  //   a) Set the correct QAM channel (71 contains WGBH)
  //   b) Set the correct program (30104 is WGBH-SD)
  //   c) Start saving a network stream to a file
  
//  [mHDHRDevice setChannelModType:@"qam256" channelNumber:71];
//  [mHDHRDevice setProgramNumber:30104];
//  [mHDHRDevice startStreaming];
  
  mFinishRecording = NO;
  
  FILE *fp = fopen("/Users/awk/Movies/recshed_movie.mpg", "wb");
  if (!fp) {
          NSLog(@"beginRecording - unable to create file");
          return ;
  }

#if 0
  uint64_t next_progress = getcurrenttime() + 1000;
  while (!mFinishRecording)
  {
    usleep(64000);

    size_t actual_size;
    UInt8* ptr = [mHDHRDevice receiveVideoData:&actual_size];
    if (!ptr) {
            continue;
    }

    fwrite(ptr, 1, actual_size, fp);

    uint64_t current_time = getcurrenttime();
    if (current_time >= next_progress) {
            next_progress = current_time + 1000;
            printf(".");
            fflush(stdout);
    }

    if ([[mSchedule endTime] compare:[NSDate date]] == NSOrderedAscending)
      mFinishRecording = YES;
  }
  #endif
}

- (void) endRecording
{
}

@end

