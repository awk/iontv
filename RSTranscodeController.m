//
//  RSTranscodeController.m
//  recsched
//
//  Created by Andrew Kimpton on 10/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSTranscodeController.h"
#import "RSRecording.h"
#import "RSTranscoding.h"
#import "RSTranscodingImp.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

@implementation RSTranscodeController

#pragma mark Changes in Recordings and Transcodings

- (void) updateForNewTranscodings:(NSArray*)inArray
{
	int index = 0;
	while ((mCurrentTranscoding == nil) && (index < [inArray count]))
	{
		RSTranscoding *candidateTranscoding = [inArray objectAtIndex:index++];
		if ([candidateTranscoding.status intValue] == RSRecordingNotYetStartedStatus)
		{
			mCurrentTranscoding = [inArray objectAtIndex:0];
		
			// Scan the recording for a title - this is a thread operation we need to wait for it to complete (or have a callback
			// preferably) before we can continue on with creating the real transcode job ?
			hb_scan(mHandbrakeHandle, [mCurrentTranscoding.schedule.recording.mediaFile UTF8String], 0);
			
			// Set a timer running to watch the progress of the scan
			[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(scanProgressTimerCallback:) userInfo:nil repeats:YES];
		}
	}
}

- (void) updateForCompletedRecordings:(NSArray*)inArray
{
	for (RSRecording *aRecording in inArray)
	{
		NSLog(@"Recording ID = %@ title = %@ \n  transcoding =\n %@", aRecording.schedule.program.programID, aRecording.schedule.program.title, aRecording.schedule.transcoding);
		if (aRecording.schedule.transcoding == NULL)
		{
			// Create a new transcoding entity
			RSTranscoding *aTranscoding = [NSEntityDescription insertNewObjectForEntityForName:@"Transcoding" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
			[aTranscoding setSchedule:aRecording.schedule];
			[aTranscoding setStatus:[NSNumber numberWithInt:RSRecordingNotYetStartedStatus]];
		}
	}
}

- (NSString *)moviesFolder {
	NSString *homeDirectory = NSHomeDirectory();
    return [homeDirectory stringByAppendingPathComponent:@"Movies"];
}

#pragma mark Transcoding Operations

- (void) beginTranscoding
{
	[mCurrentTranscoding.transcodingImp setupJob];
	[mCurrentTranscoding.transcodingImp beginTranscodeWithHandle:mHandbrakeHandle toDestinationPath:mCurrentTranscoding.mediaFile];
	
}

- (void) titleScanFinished
{
	if (mCurrentTranscoding == nil)
		return;		// Odd told a scan had finished - but not current transcoding ?
		
	hb_list_t *titleList = hb_get_titles( mHandbrakeHandle);
	if (hb_list_count(titleList) > 0)
	{
		// Have a valid title create a transcoding job
		NSString *transcodingPath = [NSString stringWithFormat:@"%@/%@ %@ - %@.mp4", [self moviesFolder], mCurrentTranscoding.schedule.program.programID, mCurrentTranscoding.schedule.program.title, mCurrentTranscoding.schedule.program.subTitle];
		[mCurrentTranscoding setMediaFile:transcodingPath];
		hb_title_t * title = (hb_title_t *) hb_list_item( titleList, 0 );
		
		// Construct a transcoding implementation with the title details, and add it to the Transcoding entity
		RSTranscodingImp *aTranscodingImp = [[[RSTranscodingImp alloc] initWithTranscoding:mCurrentTranscoding] autorelease];
		
		[aTranscodingImp setTitle:title];
		mCurrentTranscoding.transcodingImp = aTranscodingImp;
		mCurrentTranscoding.status = [NSNumber numberWithInt:RSRecordingInProgressStatus];
		
		[self beginTranscoding];
	}
	else
	{
		// No valid title found - ignore this transcoding entry.
		mCurrentTranscoding.status = [NSNumber numberWithInt:RSRecordingErrorStatus];
		mCurrentTranscoding = nil;
		// See if there's another candidate ?
		[self updateForNewTranscodings:[mTranscodingsArrayController arrangedObjects]];
	}
}


#pragma mark init and dealloc

- (id) init
{
	self = [super init];
	if (self != nil) {
		// Initialize our connection to the Handbrake libraries
		int debugLevel = /*[[NSUserDefaults standardUserDefaults] boolForKey:@"ShowVerboseOutput"]*/ 1 ? HB_DEBUG_ALL : HB_DEBUG_NONE;
		mHandbrakeHandle = hb_init(debugLevel, 0 /*[[NSUserDefaults standardUserDefaults] boolForKey:@"CheckForUpdates"]*/);

		if (!mHandbrakeHandle)
			return nil;
		
		mTranscodingsArrayController = [[NSArrayController alloc] initWithContent:nil];
		[mTranscodingsArrayController setManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		[mTranscodingsArrayController setEntityName:@"Transcoding"];
		[mTranscodingsArrayController setAutomaticallyPreparesContent:YES];
		[mTranscodingsArrayController fetchWithRequest:[mTranscodingsArrayController defaultFetchRequest] merge:YES error:nil];
		[mTranscodingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

		mRecordingsArrayController = [[NSArrayController alloc] initWithContent:nil];
		[mRecordingsArrayController setManagedObjectContext:[[NSApp delegate] managedObjectContext]];
		[mRecordingsArrayController setEntityName:@"Recording"];
		[mRecordingsArrayController setFetchPredicate:[NSPredicate predicateWithFormat:@"status == %@", [NSNumber numberWithInt:RSRecordingFinishedStatus]]];
		[mRecordingsArrayController setAutomaticallyPreparesContent:YES];
		[mRecordingsArrayController fetchWithRequest:[mRecordingsArrayController defaultFetchRequest] merge:YES error:nil];
		[mRecordingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

		// Set up any initial transcodings
		[self updateForCompletedRecordings:[mRecordingsArrayController arrangedObjects]];

//		[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateRecordings:) userInfo:nil repeats:NO];
	}
	return self;
}

- (void) awakeFromNib
{
//	[mRecordingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

//	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateRecordings:) userInfo:nil repeats:NO];
}

- (void) updateRecordings:(NSTimer*)aTimer
{
	NSLog(@"Time To update the recordings");
	
	  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	  [request setEntity:entityDescription];
	   
	  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.program.programID == %@", @"EP000809390063"];
	  [request setPredicate:predicate];
	  
	  NSError *error = nil;
	  NSArray *array = [[[NSApp delegate] managedObjectContext] executeFetchRequest:request error:&error];
	  
	RSRecording *aRecording = [array objectAtIndex:0];
	if (aRecording)
	{
		aRecording.status = [NSNumber numberWithInt:RSRecordingFinishedStatus];
	}
	[[[NSApp delegate] managedObjectContext] processPendingChanges];
}

- (void) dealloc
{
	hb_close(&mHandbrakeHandle);
	[mRecordingsArrayController release];
	[super dealloc];
}


#pragma mark Timers, Callbacks etc.

- (void) scanProgressTimerCallback:(NSTimer*)aTimer
{
    hb_state_t s;
    hb_get_state( mHandbrakeHandle, &s );
	
    switch( s.state )
    {
        case HB_STATE_IDLE:
		break;

        case HB_STATE_SCANNING:
		{
            break;
		}
	
        case HB_STATE_SCANDONE:
        {
			[aTimer invalidate];
			[self titleScanFinished];
			break;
        }
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
	if ((object == mTranscodingsArrayController) && ([keyPath isEqual:@"arrangedObjects"]))
	{
		// The list of transcodings has changed - make sure that each is queued.
		[self updateForNewTranscodings:[mTranscodingsArrayController arrangedObjects]];
	}
	if ((object == mRecordingsArrayController) && ([keyPath isEqual:@"arrangedObjects"]))
	{
		// The list of completed recordings has changed - build new transcoding entries
		[self updateForCompletedRecordings:[mRecordingsArrayController arrangedObjects]];
	}
}

@end
