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
#import "Z2ITStation.h"
#import "HDHomeRunTuner.h"

#define RECORDING_DISABLED 0

@implementation RecordingThreadController

- (void) initializeThreadData
{
	// We need to create a new the managedObjectContext for this thread, we can use the mSchedule (which was given to us
	// in a seperate thread context to retrieve the store co-ordinator and then work from there.
	NSPersistentStoreCoordinator *psc = [[mSchedule managedObjectContext] persistentStoreCoordinator];
	if (psc != nil)
	{
		mThreadManagedObjectContext = [[NSManagedObjectContext alloc] init];
		[mThreadManagedObjectContext setPersistentStoreCoordinator: psc];
		
		// We also need to create a thread local schedule object too.
		mThreadSchedule = (Z2ITSchedule*) [mThreadManagedObjectContext objectWithID:[mSchedule objectID]];
	}
}

+ (void) recordingThreadStarted:(id)aRecordingThreadController
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  RecordingThreadController *theController = (RecordingThreadController*)aRecordingThreadController;
  [theController initializeThreadData];
  [theController beginRecording];
  
  NSLog(@"recordingThread - EXIT");
  [pool release];
}

- (id) initWithSchedule:(Z2ITSchedule*)inSchedule
{
  self = [super init];
  if (self != nil) {
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

#if RECORDING_DISABLED
- (void) beginRecording
{
  NSLog(@"beginRecording - timer fired for schedule %@ program title %@", mThreadSchedule, mThreadSchedule.program.title);
  
  Z2ITStation *aStation = [mThreadSchedule station];
  NSSet *hdhrStations = [aStation hdhrStations];
  if ([hdhrStations count] == 0)
  {
	NSLog(@"beginRecording no mapped stations");
	return;
  }
  
  HDHomeRunStation *anHDHRStation = [hdhrStations anyObject];

  NSLog(@"Recording on HDHRStation %@", anHDHRStation);

  mFinishRecording = NO;
  

  uint64_t next_progress = getcurrenttime() + 1000;
  while (!mFinishRecording)
  {
    usleep(64000);

    uint64_t current_time = getcurrenttime();
    if (current_time >= next_progress) {
            next_progress = current_time + 1000;
            printf(".");
            fflush(stdout);
    }

    if ([[mThreadSchedule endTime] compare:[NSDate date]] == NSOrderedAscending)
      mFinishRecording = YES;
  }
}
#else  
- (void) beginRecording
{
  NSLog(@"beginRecording - timer fired for schedule %@ program title %@", mThreadSchedule, mThreadSchedule.program.title);
  
  Z2ITStation *aStation = [mThreadSchedule station];
  NSSet *hdhrStations = [aStation hdhrStations];
  if ([hdhrStations count] == 0)
  {
	NSLog(@"beginRecording no mapped stations");
	return;
  }
  
  HDHomeRunStation *anHDHRStation = [hdhrStations anyObject];

  NSLog(@"Recording on HDHRStation %@", anHDHRStation);
  [anHDHRStation startStreaming];

  mFinishRecording = NO;
  
  FILE *fp = fopen("/Users/awk/Movies/recshed_movie.mpg", "wb");
  if (!fp) {
          NSLog(@"beginRecording - unable to create file");
          return ;
  }

  uint64_t next_progress = getcurrenttime() + 1000;
  while (!mFinishRecording)
  {
    usleep(64000);

    size_t actual_size;
    UInt8* ptr = [anHDHRStation receiveVideoData:&actual_size];
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

    if ([[mThreadSchedule endTime] compare:[NSDate date]] == NSOrderedAscending)
      mFinishRecording = YES;
  }
  [anHDHRStation stopStreaming];
  fclose(fp);
}
#endif

- (void) endRecording
{
}

@end

