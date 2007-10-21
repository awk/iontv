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
#import "RSRecording.h"
#import "PreferenceKeys.h"

#define RECORDING_DISABLED 0

NSString *RSNotificationRecordingFinished = @"RSNotificationRecordingFinished";

@implementation RecordingThreadController

- (void) initializeThreadData
{
	// We need to create a new the managedObjectContext for this thread, we can use the mSchedule (which was given to us
	// in a seperate thread context to retrieve the store co-ordinator and then work from there.
	NSPersistentStoreCoordinator *psc = [[mRecording managedObjectContext] persistentStoreCoordinator];
	if (psc != nil)
	{
		mThreadManagedObjectContext = [[NSManagedObjectContext alloc] init];
		[mThreadManagedObjectContext setPersistentStoreCoordinator: psc];
		
		// We also need to create a thread local schedule object too.
		mThreadRecording = (RSRecording*) [mThreadManagedObjectContext objectWithID:[mRecording objectID]];
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

- (id) initWithRecording:(RSRecording*)inRecording recordingServer:(RecSchedServer*)inServer
{
  self = [super init];
  if (self != nil) {
    mRecording = [inRecording retain];
    mRecSchedServer = [inServer retain];
	
    NSTimer *recordingStartTimer = [[NSTimer alloc] initWithFireDate:mRecording.schedule.time interval:0 target:self selector:@selector(startRecordingTimerFired:) userInfo:self repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:recordingStartTimer forMode:NSDefaultRunLoopMode];
  }
  return self;
}

- (void) dealloc
{
	[mRecording release];
	[mRecSchedServer release];
	[super dealloc];
}

- (void) startRecordingTimerFired:(NSTimer*)inTimer
{
  [NSThread detachNewThreadSelector:@selector(recordingThreadStarted:) toTarget:[RecordingThreadController class] withObject:self];
}

- (NSString *)recordedProgramsFolder {
	NSURL *folderURL = [NSURL URLWithString:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kRecordedProgramsLocationKey]];
    return [folderURL path];
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
  NSLog(@"beginRecording - timer fired for schedule %@ program title %@", mThreadRecording.schedule, mThreadRecording.schedule.program.title);
  
  Z2ITStation *aStation = mThreadRecording.schedule.station;
  NSSet *hdhrStations = [aStation hdhrStations];
  if ([hdhrStations count] == 0)
  {
	NSLog(@"beginRecording no mapped stations");
	return;
  }
  
  HDHomeRunStation *anHDHRStation = [hdhrStations anyObject];

  size_t activityToken = 0;
  if ([mRecSchedServer uiActivity])
  {
	activityToken = [[mRecSchedServer uiActivity] createActivity];
  
	[[mRecSchedServer uiActivity] setActivity:activityToken infoString:[NSString stringWithFormat:@"Recording %@ on %@ - %@", mThreadRecording.schedule.program.title, 
		[anHDHRStation.z2itStation channelStringForLineup:anHDHRStation.channel.tuner.lineup],
		anHDHRStation.z2itStation.callSign]];
  }
  
  NSTimeInterval recordingDuration = [mThreadRecording.schedule.endTime timeIntervalSinceDate:[NSDate date]];
  if (activityToken)
	[[mRecSchedServer uiActivity] setActivity:activityToken progressMaxValue:recordingDuration];
  
  mFinishRecording = NO;
  NSString *destinationPath = [NSString stringWithFormat:@"%@/%@ %@ - %@.ts", [self recordedProgramsFolder], mThreadRecording.schedule.program.programID, mThreadRecording.schedule.program.title, mThreadRecording.schedule.program.subTitle];
  [[NSFileManager defaultManager] createFileAtPath:destinationPath contents:nil attributes:nil];
  NSFileHandle* transportStreamFileHandle = [NSFileHandle fileHandleForWritingAtPath:destinationPath];
  if (!transportStreamFileHandle)
  {
	NSLog(@"beginRecording - unable to create recording at %@", destinationPath);
	[[mRecSchedServer uiActivity] endActivity:activityToken];
	return;
  }

  mThreadRecording.mediaFile  = [destinationPath copy];
  mThreadRecording.status = [NSNumber numberWithInt:RSRecordingInProgressStatus];
  
  [anHDHRStation startStreaming];
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
		if (!activityToken)
		{
			// No token - probably because the UIActivity connection wasn't available last time, try again now
			if ([mRecSchedServer uiActivity])
			{
				activityToken = [[mRecSchedServer uiActivity] createActivity];

				[[mRecSchedServer uiActivity] setActivity:activityToken infoString:[NSString stringWithFormat:@"Recording %@ on %@ - %@", mThreadRecording.schedule.program.title, 
					[anHDHRStation.z2itStation channelStringForLineup:anHDHRStation.channel.tuner.lineup],
					anHDHRStation.z2itStation.callSign]];
			}

			if (activityToken)
				[[mRecSchedServer uiActivity] setActivity:activityToken progressMaxValue:recordingDuration];
		}
		
		if (activityToken)
			[[mRecSchedServer uiActivity] setActivity:activityToken incrementBy:[[NSDate date] timeIntervalSinceDate:lastActivityNotification]];
		lastActivityNotification = [NSDate date];
	}
	
    if ([mThreadRecording.schedule.endTime compare:[NSDate date]] == NSOrderedAscending)
      mFinishRecording = YES;
  }
  [anHDHRStation stopStreaming];
  [transportStreamFileHandle closeFile];
  [[mRecSchedServer uiActivity] endActivity:activityToken];
  
  mThreadRecording.status = [NSNumber numberWithInt:RSRecordingFinishedStatus];
  [mThreadManagedObjectContext processPendingChanges];
  
  // Save the MOC
  [[NSApp delegate] performSelectorOnMainThread:@selector(saveAction:) withObject:self waitUntilDone:YES];

	// Notify everyone that this recording has finished
	[[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationRecordingFinished object:[mThreadRecording objectID]];
}
#endif

- (void) endRecording
{
}

@end

