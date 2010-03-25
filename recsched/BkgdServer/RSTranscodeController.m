//  recsched_bkgd - Background server application retrieves schedule data, performs recordings,
//  transcodes recordings in to H.264 format for iTunes, iPod etc.
//
//  Copyright (C) 2007 Andrew Kimpton
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "RSTranscodeController.h"
#import "RSRecording.h"
#import "RSTranscoding.h"
#import "RSTranscodingImp.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "iTunes_ScriptingBridge.h"
#import "PreferenceKeys.h"
#import "RecordingThread.h"
#import "recsched_bkgd_AppDelegate.h"

@implementation RSTranscodeController

NSString *RSNotificationTranscodingFinished = @"RSNotificationTranscodingFinished";

#pragma mark Changes in Recordings and Transcodings

- (void)updateForNewTranscodings:(NSArray *)inArray {
  int index = 0;
  while ((mCurrentTranscoding == nil) && (index < [inArray count])) {
    RSTranscoding *candidateTranscoding = [inArray objectAtIndex:index++];
    if ([candidateTranscoding.status intValue] == RSRecordingNotYetStartedStatus) {
      mCurrentTranscoding = [candidateTranscoding retain];

      // Scan the recording for a title - this is a thread operation we need to wait for it to complete (or have a callback
      // preferably) before we can continue on with creating the real transcode job ?
      if ([[NSFileManager defaultManager] fileExistsAtPath:mCurrentTranscoding.schedule.recording.mediaFile]) {
        NSLog(@"updateForNewTranscodings - have candidate for transcoding = %@", mCurrentTranscoding.schedule.program.title);
        hb_scan(mHandbrakeHandle, [[NSFileManager defaultManager] fileSystemRepresentationWithPath:mCurrentTranscoding.schedule.recording.mediaFile], 0);

        // Set a timer running to watch the progress of the scan
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(scanProgressTimerCallback:) userInfo:nil repeats:YES];
      } else {
        NSLog(@"updateForNewTranscodings - no recorded media for candidate = %@", mCurrentTranscoding.schedule.program.title);
        mCurrentTranscoding.status = [NSNumber numberWithInt:RSRecordingErrorStatus];
        [mCurrentTranscoding release];
        mCurrentTranscoding = nil;
      }
    }
  }

  // Save any updated status
  [[NSApp delegate] saveAction:self];
}

- (void)updateForCompletedRecordings:(NSArray *)inArray {
  for (RSRecording *aRecording in inArray) {
    NSLog(@"updateForCompleted Recordings Recording ID = %@ title = %@ status = %@ %@",
            aRecording.schedule.program.programID,
            aRecording.schedule.program.title,
            aRecording.status, aRecording.schedule.transcoding == nil ? @"No Transcoding" : aRecording.schedule.transcoding.mediaFile);
    if (aRecording.schedule.transcoding == NULL) {
      // Create a new transcoding entity
      RSTranscoding *aTranscoding = [NSEntityDescription insertNewObjectForEntityForName:@"Transcoding" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
      [aTranscoding setSchedule:aRecording.schedule];
      [aTranscoding setStatus:[NSNumber numberWithInt:RSRecordingNotYetStartedStatus]];
    }
  }
  [[[NSApp delegate] managedObjectContext] processPendingChanges];
}

- (NSString *)transcodedProgramsFolder {
  NSURL *folderURL = [NSURL URLWithString:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kTranscodedProgramsLocationKey]];
  return [folderURL path];
}

#pragma mark Transcoding Operations

- (NSDictionary *)createIpodLowPreset {
  NSMutableDictionary *preset = [[NSMutableDictionary alloc] init];
  /* Get the New Preset Name from the field in the AddPresetPanel */
  [preset setObject:@"iPod Low-Rez" forKey:@"PresetName"];
  /*Set whether or not this is a user preset or factory 0 is factory, 1 is user*/
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"Type"];
  /*Set whether or not this is default, at creation set to 0*/
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"Default"];
  /*Get the whether or not to apply pic settings in the AddPresetPanel*/
  [preset setObject:[NSNumber numberWithInt:1] forKey:@"UsesPictureSettings"];
  /* Get the New Preset Description from the field in the AddPresetPanel */
  [preset setObject:@"HandBrake's low resolution settings for the iPod. Optimized for great playback on the iPod screen, with smaller file size." forKey:@"PresetDescription"];
  /* File Format */
  [preset setObject:@"MP4 file" forKey:@"FileFormat"];
  /* Chapter Markers*/
  [preset setObject:[NSNumber numberWithInt:1] forKey:@"ChapterMarkers"];
  /* Codecs */
  [preset setObject:@"AVC/H.264 Video / AAC Audio" forKey:@"FileCodecs"];
  /* Video encoder */
  [preset setObject:@"x264 (h.264 iPod)" forKey:@"VideoEncoder"];
  /* x264 Option String */
  [preset setObject:@"keyint=300:keyint-min=30:bframes=0:cabac=0:ref=1:vbv-maxrate=768:vbv-bufsize=2000:analyse=all:me=umh:subme=6:no-fast-pskip=1" forKey:@"x264Option"];
  /* Video quality */
  [preset setObject:[NSNumber numberWithInt:1] forKey:@"VideoQualityType"];
  [preset setObject:@"" forKey:@"VideoTargetSize"];
  [preset setObject:@"700" forKey:@"VideoAvgBitrate"];
  [preset setObject:[NSNumber numberWithFloat:0.5] forKey:@"VideoQualitySlider"];

  /* Video framerate */
  [preset setObject:@"Same as source" forKey:@"VideoFramerate"];
  /* GrayScale */
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"VideoGrayScale"];
  /* 2 Pass Encoding */
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"VideoTwoPass"];

  /*Picture Settings*/
  //hb_job_t * job = fTitle->job;
  /* Basic Picture Settings */
  /* Use Max Picture settings for whatever the dvd is.*/
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"UsesMaxPictureSettings"];
  [preset setObject:[NSNumber numberWithInt:1] forKey:@"PictureAutoCrop"];
  [preset setObject:[NSNumber numberWithInt:320] forKey:@"PictureWidth"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureHeight"];
  [preset setObject:[NSNumber numberWithInt:1] forKey:@"PictureKeepRatio"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureDeinterlace"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PicturePAR"];
  /* Set crop settings here */
  /* The Auto Crop Matrix in the Picture Window autodetects differences in crop settings */
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureTopCrop"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureBottomCrop"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureLeftCrop"];
  [preset setObject:[NSNumber numberWithInt:0] forKey:@"PictureRightCrop"];

  /*Audio*/
  /* Audio Sample Rate*/
  [preset setObject:@"48" forKey:@"AudioSampleRate"];
  /* Audio Bitrate Rate*/
  [preset setObject:@"160" forKey:@"AudioBitRate"];
  /* Subtitles*/
  [preset setObject:@"None" forKey:@"Subtitles"];

  [preset autorelease];
  return preset;

}

- (NSDictionary *)chosenPreset {
  // We use the same presets as Handbrake and just read their plist
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
  NSString *presetsPath = [basePath stringByAppendingPathComponent:@"HandBrake/UserPresets.plist"];

  NSMutableArray *presetsArray = [[NSMutableArray alloc] initWithContentsOfFile:presetsPath];
  if (nil == presetsArray) {
    // No presets found - just return a default iPod preset
    return [self createIpodLowPreset];
  } else {
    // Search the array for a preset with a name matching the set preferences
    NSString *presetName = [[NSUserDefaults standardUserDefaults] objectForKey:@"transcodePreset"];
    NSDictionary *chosenPreset = nil;
    for (NSDictionary *aPreset in presetsArray) {
      NSString *plistPresetName = [aPreset valueForKey:@"PresetName"];
      if ([plistPresetName compare:presetName] == NSOrderedSame) {
        chosenPreset = aPreset;
        break;    // Got a match
      }
    }
    if (chosenPreset == nil) {
      return [self createIpodLowPreset];    // Didn't get a match
    } else {
      return chosenPreset;
    }
  }
}

- (void)beginTranscoding {
  [mCurrentTranscoding.transcodingImp setupJobWithPreset:[self chosenPreset]];
  [mCurrentTranscoding.transcodingImp beginTranscodeWithHandle:mHandbrakeHandle toDestinationPath:mCurrentTranscoding.mediaFile usingPreset:[self chosenPreset]];
}

- (void)titleScanFinished {
  if (mCurrentTranscoding == nil) {
    return;   // Odd told a scan had finished - but not current transcoding ?
  }
  hb_list_t *titleList = hb_get_titles( mHandbrakeHandle);
  if (hb_list_count(titleList) > 0) {
    // Have a valid title create a transcoding job
    NSString *transcodingPath;
    if (mCurrentTranscoding.schedule.program.subTitle != nil) {
      transcodingPath = [NSString stringWithFormat:@"%@/%@ %@ - %@.mp4", [self transcodedProgramsFolder], mCurrentTranscoding.schedule.program.programID, mCurrentTranscoding.schedule.program.title, mCurrentTranscoding.schedule.program.subTitle];
    } else {
      transcodingPath = [NSString stringWithFormat:@"%@/%@ %@.mp4", [self transcodedProgramsFolder], mCurrentTranscoding.schedule.program.programID, mCurrentTranscoding.schedule.program.title];
    }

    NSString *legalTranscodingPath;
    legalTranscodingPath = [transcodingPath stringByReplacingOccurrencesOfString:@":" withString:@"-"];

    [mCurrentTranscoding setMediaFile:legalTranscodingPath];
    hb_title_t * title = (hb_title_t *) hb_list_item( titleList, 0 );

    // Construct a transcoding implementation with the title details, and add it to the Transcoding entity
    RSTranscodingImp *aTranscodingImp = [[[RSTranscodingImp alloc] initWithTranscoding:mCurrentTranscoding] autorelease];

    [aTranscodingImp setTitle:title];
    mCurrentTranscoding.transcodingImp = aTranscodingImp;
    mCurrentTranscoding.status = [NSNumber numberWithInt:RSRecordingInProgressStatus];

    NSLog(@"titleScanFinished - beginning transcoding with output file %@", legalTranscodingPath);
    [self beginTranscoding];
  } else {
    NSLog(@"titleScanFinished - title scan found no valid titles in %@", mCurrentTranscoding.schedule.recording.mediaFile);
    // No valid title found - mark the associated recording as 'bad'
    mCurrentTranscoding.schedule.recording.status = [NSNumber numberWithInt:RSRecordingErrorStatus];

    // and ignore this transcoding entry.
    mCurrentTranscoding.status = [NSNumber numberWithInt:RSRecordingErrorStatus];
    [mCurrentTranscoding release];
    mCurrentTranscoding = nil;

    // See if there's another candidate ?
    [self updateForNewTranscodings:[mTranscodingsArrayController arrangedObjects]];
  }

  [[NSApp delegate] saveAction:nil];
}

- (void)addToiTunes:(RSTranscoding *) aTranscoding {
  iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
  [iTunes setDelegate:self];

  NSArray *filesArray = [NSArray arrayWithObject:[NSURL fileURLWithPath:aTranscoding.mediaFile]];
  iTunesTrack *theTrack = [iTunes add:filesArray to:nil];
  if (![aTranscoding.schedule.program isMovie]) {
    // Additions to the iTunes library are movies by default
    theTrack.videoKind = iTunesEVdKTVShow;
  }
  theTrack.show = aTranscoding.schedule.program.title;
  theTrack.albumArtist = aTranscoding.schedule.program.title;
  theTrack.artist = aTranscoding.schedule.program.title;
  // In theory the Episode ID/syndicatedEpisodeNumber is usually a 3 digit number of the form 104, 307 etc. This can be parsed as
  // Season 1 Episode 4, Season 3 Episode 7. In practice however the ScheduleDirect data doesn't seem to uniformly follow
  // this scheme - so we'll take the syndicated episode number and if it's between 1 and 99999 use it to generate  the season
  // and epsidoe number - if not we'll just skip that part
  theTrack.episodeID = aTranscoding.schedule.program.syndicatedEpisodeNumber;
  int episodeID = [theTrack.episodeID intValue];
  if ((episodeID >= 100) && (episodeID < 99999)) {
    theTrack.seasonNumber = episodeID / 100;
    theTrack.episodeNumber = episodeID % 100;
    theTrack.album = [NSString stringWithFormat:@"%@, Season %d", theTrack.artist, theTrack.seasonNumber];
  }
  NSCalendarDate *originalAirDate = [aTranscoding.schedule.program.originalAirDate dateWithCalendarFormat:nil timeZone:nil];
  theTrack.year = [originalAirDate yearOfCommonEra];
  if (aTranscoding.schedule.program.subTitle != nil) {
    theTrack.name = aTranscoding.schedule.program.subTitle;
  }
  theTrack.objectDescription = aTranscoding.schedule.program.descriptionStr;
}

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error {
  NSLog(@"ScriptingBridge eventDidFail error = %@", error);
 return nil;
}

- (void)transcodingFinishedNotification:(NSNotification *)aNotification {
  // Transcoding has finished - push the completed file to iTunes
  RSTranscodingImp *aTranscodingImp = [aNotification object];

  NSError *error;
  if ([[[NSUserDefaults standardUserDefaults] valueForKey:kDeleteRecordingsAfterTranscodeKey] boolValue] == YES) {
    [[NSFileManager defaultManager] removeItemAtPath:aTranscodingImp.transcoding.schedule.recording.mediaFile error:&error];
  }
  if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kAddTranscodingsToiTunesKey] boolValue] == YES) {
    [self addToiTunes:aTranscodingImp.transcoding];
  }
  if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kDeleteTranscodingsAfterAddKey] boolValue] == YES) {
    [[NSFileManager defaultManager] removeItemAtPath:[aTranscodingImp.transcoding mediaFile] error:&error];
  }
  [mCurrentTranscoding release];
  mCurrentTranscoding = nil;
  // Check to see if there's another candidate to transcode
  [self updateForNewTranscodings:[mTranscodingsArrayController arrangedObjects]];
}

#pragma mark init and dealloc

- (id)init {
  self = [super init];
  if (self != nil) {
    // Initialize our connection to the Handbrake libraries
    int debugLevel = /*[[NSUserDefaults standardUserDefaults] boolForKey:@"ShowVerboseOutput"]*/ 1 ? HB_DEBUG_ALL : HB_DEBUG_NONE;
    mHandbrakeHandle = hb_init(debugLevel, 0 /*[[NSUserDefaults standardUserDefaults] boolForKey:@"CheckForUpdates"]*/);

    if (!mHandbrakeHandle) {
      return nil;
    }
    mTranscodingsArrayController = [[NSArrayController alloc] initWithContent:nil];
    [mTranscodingsArrayController setManagedObjectContext:[[NSApp delegate] managedObjectContext]];
    [mTranscodingsArrayController setEntityName:@"Transcoding"];
    [mTranscodingsArrayController setAutomaticallyPreparesContent:YES];
    [mTranscodingsArrayController fetchWithRequest:[mTranscodingsArrayController defaultFetchRequest] merge:NO error:nil];
    [mTranscodingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

    mRecordingsArrayController = [[NSArrayController alloc] initWithContent:nil];
    [mRecordingsArrayController setManagedObjectContext:[[NSApp delegate] managedObjectContext]];
    [mRecordingsArrayController setEntityName:@"Recording"];
    [mRecordingsArrayController setFetchPredicate:[NSPredicate predicateWithFormat:@"status == %@", [NSNumber numberWithInt:RSRecordingFinishedStatus]]];
    [mRecordingsArrayController setAutomaticallyPreparesContent:YES];
    [mRecordingsArrayController fetchWithRequest:[mRecordingsArrayController defaultFetchRequest] merge:NO error:nil];
    [mRecordingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

    // Set up any initial transcodings
    for (RSRecording *aRecording in [mRecordingsArrayController arrangedObjects]) {
      NSLog(@"Recording ID = %@ title = %@ status = %@ %@", aRecording.schedule.program.programID, aRecording.schedule.program.title, aRecording.status, aRecording.schedule.transcoding == nil ? @"No Transcoding" : @"Has Transcoding");
      if (aRecording.schedule.transcoding == NULL) {
        // Create a new transcoding entity
        RSTranscoding *aTranscoding = [NSEntityDescription insertNewObjectForEntityForName:@"Transcoding" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
        [aTranscoding setSchedule:aRecording.schedule];
        [aTranscoding setStatus:[NSNumber numberWithInt:RSRecordingNotYetStartedStatus]];
      } else if ([aRecording.schedule.transcoding.status intValue] == RSRecordingInProgressStatus) {
        // This is a prior transcoding that failed to complete when we exited the server last time,
        // restart it now
        aRecording.schedule.transcoding.status = [NSNumber numberWithInt:RSRecordingNotYetStartedStatus];
        [mTranscodingsArrayController fetchWithRequest:[mTranscodingsArrayController defaultFetchRequest] merge:NO error:nil];
      }
    }
    [[[NSApp delegate] managedObjectContext] processPendingChanges];

    // Register for notifications when transcoding completes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transcodingFinishedNotification:) name:RSNotificationTranscodingFinished object:nil];
  }
  return self;
}

- (void)dealloc {
  hb_close(&mHandbrakeHandle);
  [mRecordingsArrayController release];
  [super dealloc];
}


#pragma mark Timers, Callbacks etc.

- (void)scanProgressTimerCallback:(NSTimer *)aTimer {
  hb_state_t s;
  hb_get_state( mHandbrakeHandle, &s );

  switch( s.state ) {
      case HB_STATE_IDLE:
        break;

      case HB_STATE_SCANNING:
        break;

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
                       context:(void *)context {
  if ((object == mTranscodingsArrayController) && ([keyPath isEqual:@"arrangedObjects"])) {
    // The list of transcodings has changed - make sure that each is queued.
    [self updateForNewTranscodings:[mTranscodingsArrayController arrangedObjects]];
  }
  if ((object == mRecordingsArrayController) && ([keyPath isEqual:@"arrangedObjects"])) {
    // The list of completed recordings has changed - build new transcoding entries
    [self updateForCompletedRecordings:[mRecordingsArrayController arrangedObjects]];
  }
}

@end
