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
#import "RecSchedServer.h"
#import "RSActivityDisplayProtocol.h"

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

- (id) initWithSchedule:(Z2ITSchedule*)inSchedule recordingServer:(RecSchedServer*)inServer
{
  self = [super init];
  if (self != nil) {
    mSchedule = [inSchedule retain];
    mRecSchedServer = [inServer retain];
	
    NSTimer *recordingStartTimer = [[NSTimer alloc] initWithFireDate:[mSchedule time] interval:0 target:self selector:@selector(startRecordingTimerFired:) userInfo:self repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:recordingStartTimer forMode:NSDefaultRunLoopMode];
  }
  return self;
}

- (void) dealloc
{
	[mSchedule release];
	[mRecSchedServer release];
	[super dealloc];
}

- (void) startRecordingTimerFired:(NSTimer*)inTimer
{
  [NSThread detachNewThreadSelector:@selector(recordingThreadStarted:) toTarget:[RecordingThreadController class] withObject:self];
}

- (NSString *)moviesFolder {
	NSString *homeDirectory = NSHomeDirectory();
    return [homeDirectory stringByAppendingPathComponent:@"Movies"];
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

  size_t activityToken = [[mRecSchedServer uiActivity] createActivity];
  
  [[mRecSchedServer uiActivity] setActivity:activityToken infoString:[NSString stringWithFormat:@"Recording %@ on %@ - %@", mThreadSchedule.program.title, 
		[anHDHRStation.z2itStation channelStringForLineup:anHDHRStation.channel.tuner.lineup],
		anHDHRStation.z2itStation.callSign]];
  
  NSTimeInterval recordingDuration = [mThreadSchedule.endTime timeIntervalSinceDate:[NSDate date]];
  [[mRecSchedServer uiActivity] setActivity:activityToken progressMaxValue:recordingDuration];
  
  [anHDHRStation startStreaming];

  mFinishRecording = NO;
  NSString *destinationPath = [NSString stringWithFormat:@"%@/%@ %@ - %@", [self moviesFolder], mThreadSchedule.program.programID, mThreadSchedule.program.title, mThreadSchedule.program.subTitle];
  [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
  NSFileHandle* transportStreamFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
  if (!transportStreamFileHandle)
  {
	NSLog(@"beginRecording - unable to create recording at %@", destinationPath);
	[[mRecSchedServer uiActivity] endActivity:activityToken];
	return;
  }

  const NSTimeInterval kNotificationInterval = 5.0;
  NSDate *lastActivityNotification = [NSDate date];
  while (!mFinishRecording)
  {
    usleep(64000);

	NSData *videoData = [anHDHRStation receiveVideoData];
	if (videoData)
	{
		[transportStreamFileHandle writeData:videoData];
		[videoData release];
	}


	if ([[NSDate date] timeIntervalSinceDate:lastActivityNotification] > kNotificationInterval)
	{
		[[mRecSchedServer uiActivity] setActivity:activityToken incrementBy:[[NSDate date] timeIntervalSinceDate:lastActivityNotification]];
		lastActivityNotification = [NSDate date];
	}
	
    if ([[mThreadSchedule endTime] compare:[NSDate date]] == NSOrderedAscending)
      mFinishRecording = YES;
  }
  [anHDHRStation stopStreaming];
  [transportStreamFileHandle closeFile];
  [[mRecSchedServer uiActivity] endActivity:activityToken];
}
#endif

- (void) endRecording
{
}

@end

