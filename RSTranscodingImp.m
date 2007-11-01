//
//  RSTranscodingImp.m
//  recsched
//
//  Created by Andrew Kimpton on 10/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSTranscodingImp.h"
#import "RSTranscoding.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"
#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSTranscodeController.h"

static int FormatSettings[4][10] =
  { { HB_MUX_MP4 | HB_VCODEC_FFMPEG | HB_ACODEC_FAAC,
	  HB_MUX_MP4 | HB_VCODEC_X264   | HB_ACODEC_FAAC,
	  0,
	  0 },
    { HB_MUX_MKV | HB_VCODEC_FFMPEG | HB_ACODEC_FAAC,
	  HB_MUX_MKV | HB_VCODEC_FFMPEG | HB_ACODEC_AC3,
	  HB_MUX_MKV | HB_VCODEC_FFMPEG | HB_ACODEC_LAME,
	  HB_MUX_MKV | HB_VCODEC_FFMPEG | HB_ACODEC_VORBIS,
	  HB_MUX_MKV | HB_VCODEC_X264   | HB_ACODEC_FAAC,
	  HB_MUX_MKV | HB_VCODEC_X264   | HB_ACODEC_AC3,
	  HB_MUX_MKV | HB_VCODEC_X264   | HB_ACODEC_LAME,
	  HB_MUX_MKV | HB_VCODEC_X264   | HB_ACODEC_VORBIS,
	  0,
	  0 },
    { HB_MUX_AVI | HB_VCODEC_FFMPEG | HB_ACODEC_LAME,
	  HB_MUX_AVI | HB_VCODEC_FFMPEG | HB_ACODEC_AC3,
	  HB_MUX_AVI | HB_VCODEC_X264   | HB_ACODEC_LAME,
	  HB_MUX_AVI | HB_VCODEC_X264   | HB_ACODEC_AC3},
    { HB_MUX_OGM | HB_VCODEC_FFMPEG | HB_ACODEC_VORBIS,
	  HB_MUX_OGM | HB_VCODEC_FFMPEG | HB_ACODEC_LAME,
	  0,
	  0 } };

@interface RSTranscodingImp(Private)
- (int) audioSampleRateIndexForString:(NSString*) aString;
- (int) formatIndexForString:(NSString*)aString;
- (int) codecIndexForString:(NSString*)aString;
- (int) videoEncoderIndexForString:(NSString*)aString;
- (int) videoFrameRateIndexForString:(NSString*)aString;
- (int) subtitleIndexForString:(NSString*)aString;
- (int) audioBitRateTagForString:(NSString*)aString;
@end

@implementation RSTranscodingImp

#pragma mark Properties

@synthesize mTranscoding;

#pragma mark Initialization & Setup

- (id) initWithTranscoding:(RSTranscoding *)aTranscoding
{
	self = [super init];
	if (self != nil) {
		mTranscoding = [aTranscoding retain];
		
		// Get whatever the server has for a UI Activity now
		mUIActivity = [[[[NSApp delegate] recServer] uiActivity] retain];
		
		// We need to know if an activity UI becomes available.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiActivityNotification:) name:RSNotificationUIActivityAvailable object:nil];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mTranscoding release];
	[mUIActivity release];
	[super dealloc];
}

- (void) setTitle:(hb_title_t*)aTitle
{
	mHandbrakeTitle = aTitle;
}

- (void) setupPictureDimensionsForJob:(hb_job_t*)aJob withPreset:(NSDictionary *)aPreset
{
	if ([[aPreset objectForKey:@"UsesPictureSettings"]  intValue] == 2 || [[aPreset objectForKey:@"UsesMaxPictureSettings"]  intValue] == 1)
	{
		aJob->keep_ratio = [[aPreset objectForKey:@"PictureKeepRatio"]  intValue];
		if (aJob->keep_ratio == 1)
		{
			hb_fix_aspect( aJob, HB_KEEP_WIDTH );
			if( aJob->height > mHandbrakeTitle->height )
			{
				aJob->height = mHandbrakeTitle->height;
				hb_fix_aspect( aJob, HB_KEEP_HEIGHT );
			}
		}
		aJob->pixel_ratio = [[aPreset objectForKey:@"PicturePAR"]  intValue];
	}
	else // Apply picture settings that were in effect at the time the preset was saved
	{
		aJob->width = [[aPreset objectForKey:@"PictureWidth"]  intValue];
		aJob->height = [[aPreset objectForKey:@"PictureHeight"]  intValue];
		aJob->keep_ratio = [[aPreset objectForKey:@"PictureKeepRatio"]  intValue];
		if (aJob->keep_ratio == 1)
		{
			hb_fix_aspect( aJob, HB_KEEP_WIDTH );
			if( aJob->height > mHandbrakeTitle->height )
			{
				aJob->height = mHandbrakeTitle->height;
				hb_fix_aspect( aJob, HB_KEEP_HEIGHT );
			}
		}
		aJob->pixel_ratio = [[aPreset objectForKey:@"PicturePAR"]  intValue];
	}
}

- (void) setupJobWithPreset:(NSDictionary*)aPreset
{
	mHandbrakeJob = mHandbrakeTitle->job;
	
	[self setupPictureDimensionsForJob:mHandbrakeJob withPreset:aPreset];
	
    /* Chapter selection  - transport streams have no chapters, just use 1 & 1 here */
    mHandbrakeJob->chapter_start = 1;
    mHandbrakeJob->chapter_end   = 1;
	
    /* Format and codecs */
	
	// We need to convert the presets text label into an index (that matches the popup menu in Handbrake !)
    int format = [self formatIndexForString:[aPreset valueForKey:@"FileFormat"]];
    int codecs = [self codecIndexForString:[aPreset valueForKey:@"FileCodecs"]];//1; //[fDstCodecsPopUp indexOfSelectedItem];
    mHandbrakeJob->mux    = FormatSettings[format][codecs] & HB_MUX_MASK;
    mHandbrakeJob->vcodec = FormatSettings[format][codecs] & HB_VCODEC_MASK;
    mHandbrakeJob->acodec = FormatSettings[format][codecs] & HB_ACODEC_MASK;
    /* If mpeg-4, then set mpeg-4 specific options like chapters and > 4gb file sizes */
	if (format == 0) 
	{
        /* We set the largeFileSize (64 bit formatting) variable here to allow for > 4gb files based on the format being
		mpeg4 and the checkbox being checked 
		*Note: this will break compatibility with some target devices like iPod, etc.!!!!*/
		if (0) //([[NSUserDefaults standardUserDefaults] boolForKey:@"AllowLargeFiles"] > 0 && [fDstMpgLargeFileCheck state] == NSOnState)
		{
			mHandbrakeJob->largeFileSize = 1;
		}
		else
		{
			mHandbrakeJob->largeFileSize = 0;
		}
	}
	if ((format == 0) || (format == 3))
	{
	  /* We set the chapter marker extraction here based on the format being
		mpeg4 or mkv and the checkbox being checked */
		if ([[aPreset valueForKey:@"ChapterMarkers"] intValue] == 1)
		{
			mHandbrakeJob->chapter_markers = 1;
		}
		else
		{
			mHandbrakeJob->chapter_markers = 0;
		}
	}
	int videoEncoderIndex = [self videoEncoderIndexForString:[aPreset valueForKey:@"VideoEncoder"]];
	int videoQualityType = [[aPreset objectForKey:@"VideoQualityType"] intValue];
	if( ( mHandbrakeJob->vcodec & HB_VCODEC_FFMPEG ) && (videoEncoderIndex > 0 ))
    {
        mHandbrakeJob->vcodec = HB_VCODEC_XVID;
    }

    if( mHandbrakeJob->vcodec & HB_VCODEC_X264 )
    {
		if ( videoEncoderIndex > 0 )
	    {
			/* Just use new Baseline Level 3.0 
			Lets Deprecate Baseline Level 1.3h264_level*/
			mHandbrakeJob->h264_level = 30;
			mHandbrakeJob->mux = HB_MUX_IPOD;
			/* move sanity check for iPod Encoding here */
			mHandbrakeJob->pixel_ratio = 0 ;
			
		}
		
#if 0		// AWK - FIXME
		/* Set this flag to switch from Constant Quantizer(default) to Constant Rate Factor Thanks jbrjake
		Currently only used with Constant Quality setting*/
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultCrf"] > 0 && [vidQuality == 2)
		{
	        mHandbrakeJob->crf = 1;
		}
#endif
		
		/* Below Sends x264 options to the core library if x264 is selected*/
		/* Lets use this as per Nyx, Thanks Nyx!*/
		mHandbrakeJob->x264opts = (char *)calloc(1024, 1); /* Fixme, this just leaks */
		/* Turbo first pass if two pass and Turbo First pass is selected */

		if( [[aPreset objectForKey:@"VideoTwoPass"] intValue] == 1 && [[aPreset objectForKey:@"VideoTurboTwoPass"] intValue] == 1 )
		{
			/* pass the "Turbo" string to be appended to the existing x264 opts string into a variable for the first pass */
			NSString *firstPassOptStringTurbo = @":ref=1:subme=1:me=dia:analyse=none:trellis=0:no-fast-pskip=0:8x8dct=0";
			/* append the "Turbo" string variable to the existing opts string.
			Note: the "Turbo" string must be appended, not prepended to work properly*/
			NSString *firstPassOptStringCombined = [[aPreset valueForKey:@"x264Option"] stringByAppendingString:firstPassOptStringTurbo];
			strcpy(mHandbrakeJob->x264opts, [firstPassOptStringCombined UTF8String]);
		}
		else
		{
			strcpy(mHandbrakeJob->x264opts, [[aPreset valueForKey:@"x264Option"] UTF8String]);
		}
		
        mHandbrakeJob->h264_13 = videoEncoderIndex;
    }

    /* Video settings */
	int defaultVidRateIndex = [self videoFrameRateIndexForString:[aPreset valueForKey:@"VideoFramerate"]];
    if  (defaultVidRateIndex > 0 )
    {
        mHandbrakeJob->vrate      = 27000000;
        mHandbrakeJob->vrate_base = hb_video_rates[defaultVidRateIndex-1].rate;
    }
    else
    {
        mHandbrakeJob->vrate      = mHandbrakeTitle->rate;
        mHandbrakeJob->vrate_base = mHandbrakeTitle->rate_base;
    }

    switch( videoQualityType )
    {
        case 0:
            /* Target size.
               Bitrate should already have been calculated and displayed
               in fVidBitrateField, so let's just use it */
        case 1:
            mHandbrakeJob->vquality = -1.0;
            mHandbrakeJob->vbitrate = [[aPreset valueForKey:@"VideoAvgBitrate"] intValue];
            break;
        case 2:
            mHandbrakeJob->vquality = [[aPreset valueForKey:@"VideoQualitySlider"] floatValue];
            mHandbrakeJob->vbitrate = 0;
            break;
    }

    mHandbrakeJob->grayscale = [[aPreset objectForKey:@"VideoGrayScale"] intValue];

    /* Subtitle settings */
    mHandbrakeJob->subtitle = [self subtitleIndexForString:[aPreset valueForKey:@"Subtitles"]] - 2;

    /* Audio tracks and mixdowns */
    /* check for the condition where track 2 has an audio selected, but track 1 does not */
    /* we will use track 2 as track 1 in this scenario */
	
	// AWK FIXME
	int defaultAudio1Language = 1;		// second (first audio track) item in popup selected
	int defaultAudio2Language = 0;		// first item (no audio) in popup selected
    if (defaultAudio1Language > 0)
    {
        mHandbrakeJob->audios[0] = defaultAudio1Language - 1;
        mHandbrakeJob->audios[1] = defaultAudio2Language - 1; /* will be -1 if "none" is selected */
        mHandbrakeJob->audios[2] = -1;
        mHandbrakeJob->audio_mixdowns[0] = hb_audio_mixdowns[1].amixdown ; //[[fAudTrack1MixPopUp selectedItem] tag];
        mHandbrakeJob->audio_mixdowns[1] = 0; //[[fAudTrack2MixPopUp selectedItem] tag];
    }
    else if (defaultAudio2Language > 0)
    {
        mHandbrakeJob->audios[0] = defaultAudio1Language - 1;
        mHandbrakeJob->audio_mixdowns[0] = 0; //[[fAudTrack2MixPopUp selectedItem] tag];
        mHandbrakeJob->audios[1] = -1;
    }
    else
    {
        mHandbrakeJob->audios[0] = -1;
    }

    /* Audio settings */
    mHandbrakeJob->arate = hb_audio_rates[[self audioSampleRateIndexForString:[aPreset valueForKey:@"AudioSampleRate"]]].rate;
    mHandbrakeJob->abitrate = [self audioBitRateTagForString:[aPreset valueForKey:@"AudioBitRate"]];
    
    mHandbrakeJob->filters = hb_list_init();
   
	/* Detelecine */
    if ([[aPreset objectForKey:@"PictureDetelecine"] intValue] > 0)
    {
        hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    }
   
    /* Deinterlace */
	int defaultDeinterlace = [[aPreset objectForKey:@"PictureDeinterlace"] intValue];
    if (defaultDeinterlace == 1)
    {
        /* Run old deinterlacer by default */
        hb_filter_deinterlace.settings = "-1"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_deinterlace );
    }
    else if (defaultDeinterlace == 2)
    {
        /* Yadif mode 0 (1-pass with spatial deinterlacing.) */
        hb_filter_deinterlace.settings = "0"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_deinterlace );            
    }
    else if (defaultDeinterlace == 3)
    {
        /* Yadif (1-pass w/o spatial deinterlacing) and Mcdeint */
        hb_filter_deinterlace.settings = "2:-1:1"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_deinterlace );            
    }
    else if (defaultDeinterlace == 4)
    {
        /* Yadif (2-pass w/ spatial deinterlacing) and Mcdeint*/
        hb_filter_deinterlace.settings = "1:-1:1"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_deinterlace );            
    }
	
	/* Denoise */
	int defaultDenoise = [[aPreset objectForKey:@"PictureDenoise"] intValue];
	if (defaultDenoise == 1) // Weak in popup
	{
		hb_filter_denoise.settings = "2:1:2:3"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );	
	}
	else if (defaultDenoise == 2) // Medium in popup
	{
		hb_filter_denoise.settings = "3:2:2:3"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );	
	}
	else if (defaultDenoise == 3) // Strong in popup
	{
		hb_filter_denoise.settings = "7:7:5:5"; 
        hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );	
	}
}

- (void) beginTranscodeWithHandle:(hb_handle_t*)handbrakeHandle toDestinationPath:(NSString*)destinationPath usingPreset:(NSDictionary*)aPreset
{
	// Hold on to the Handbrake handle
	mHandbrakeHandle = handbrakeHandle;
	
	// Setup final output options including two pass options, subtitles and destination file
    /* Destination file */
    mHandbrakeJob->file = [destinationPath UTF8String];

    if (0)	// No subtitles ( [fSubForcedCheck state] == NSOnState )
        mHandbrakeJob->subtitle_force = 1;
    else
        mHandbrakeJob->subtitle_force = 0;

    /*
    * subtitle of -1 is a scan
    */
    if( mHandbrakeJob->subtitle == -1 )
    {
        char *x264opts_tmp;

        /*
        * When subtitle scan is enabled do a fast pre-scan job
        * which will determine which subtitles to enable, if any.
        */
        mHandbrakeJob->pass = -1;
        x264opts_tmp = mHandbrakeJob->x264opts;
        mHandbrakeJob->subtitle = -1;

        mHandbrakeJob->x264opts = NULL;

        mHandbrakeJob->indepth_scan = 1;  

        mHandbrakeJob->select_subtitle = (hb_subtitle_t**)malloc(sizeof(hb_subtitle_t*));
        *(mHandbrakeJob->select_subtitle) = NULL;

        /*
        * Add the pre-scan job
        */
        mHandbrakeJob->sequence_id++; // for job grouping
        hb_add( mHandbrakeHandle, mHandbrakeJob );

        mHandbrakeJob->x264opts = x264opts_tmp;
    }
    else
        mHandbrakeJob->select_subtitle = NULL;

    /* No subtitle were selected, so reset the subtitle to -1 (which before
    * this point meant we were scanning
    */
    if( mHandbrakeJob->subtitle == -2 )
        mHandbrakeJob->subtitle = -1;

    if ([[aPreset objectForKey:@"VideoTwoPass"] intValue] > 0)
    {
        hb_subtitle_t **subtitle_tmp = mHandbrakeJob->select_subtitle;
        mHandbrakeJob->indepth_scan = 0;

        /*
         * Do not autoselect subtitles on the first pass of a two pass
         */
        mHandbrakeJob->select_subtitle = NULL;
        
        mHandbrakeJob->pass = 1;
        mHandbrakeJob->sequence_id++; // for job grouping
        hb_add( mHandbrakeHandle, mHandbrakeJob );

        mHandbrakeJob->pass = 2;
        mHandbrakeJob->sequence_id++; // for job grouping

        mHandbrakeJob->x264opts = (char *)calloc(1024, 1); /* Fixme, this just leaks */  
        strcpy(mHandbrakeJob->x264opts, [[aPreset valueForKey:@"x264Option"] UTF8String]);

        mHandbrakeJob->select_subtitle = subtitle_tmp;

        hb_add( mHandbrakeHandle, mHandbrakeJob );
    }
    else
    {
        mHandbrakeJob->indepth_scan = 0;
        mHandbrakeJob->pass = 0;
        mHandbrakeJob->sequence_id++; // for job grouping
        hb_add( mHandbrakeHandle, mHandbrakeJob );
    }

	hb_start(mHandbrakeHandle);

	// Create an activity token
	if (mUIActivity)
	{
		mActivityToken = [mUIActivity createActivity];
		[mUIActivity setActivity:mActivityToken progressMaxValue:100.0];
	}
	
	// Start the progress timer
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(transcodingProgressTimer:) userInfo:nil repeats:YES];
}

- (void) finishedTranscode
{
	[mUIActivity endActivity:mActivityToken];
	[mTranscoding finishedTranscode];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationTranscodingFinished object:self];
}

#pragma mark Timers Callbacks etc

- (void) transcodingProgressTimer:(NSTimer*)aTimer
{
    hb_state_t s;
    hb_get_state( mHandbrakeHandle, &s );
	
	if ([mUIActivity shouldCancelActivity:mActivityToken])
	{
		// Calling stop will cause an asynchronous stop reflected
		// in the state value
		hb_stop(mHandbrakeHandle);
	}
	
	switch( s.state )
    {
        case HB_STATE_IDLE:
		break;

        case HB_STATE_WORKING:
        {
            NSMutableString * string;

			/* Update text field */
                        if (mTranscoding.schedule.program.subTitle != nil)
                          string = [NSMutableString stringWithFormat: @"Encoding: %@ - %@", mTranscoding.schedule.program.title, mTranscoding.schedule.program.subTitle];
                        else
                          string = [NSMutableString stringWithFormat: @"Encoding: %@", mTranscoding.schedule.program.title];
                        
			if( s.param.working.seconds > -1 )
            {
                [string appendFormat:
                    @" (%.2f fps, avg %.2f fps, ETA %02dh%02dm%02ds)",
                    s.param.working.rate_cur, s.param.working.rate_avg, s.param.working.hours, s.param.working.minutes, s.param.working.seconds];
            }
			[mUIActivity setActivity:mActivityToken infoString:string];
			
            /* Update progress bar */
			[mUIActivity setActivity:mActivityToken incrementBy:100.0 * s.param.working.progress - mLastProgressValue];
			mLastProgressValue = 100.0 * s.param.working.progress;
			break;
        }
			
        case HB_STATE_MUXING:
        {
            /* Update text field */
            if (mTranscoding.schedule.program.subTitle != nil)
              [mUIActivity setActivity:mActivityToken infoString:[NSString stringWithFormat:@"Muxing: %@ - %@", mTranscoding.schedule.program.title, mTranscoding.schedule.program.subTitle]];
            else
              [mUIActivity setActivity:mActivityToken infoString:[NSString stringWithFormat:@"Muxing: %@", mTranscoding.schedule.program.title]];
            
            /* Update slider */
			[mUIActivity setActivity:mActivityToken progressIndeterminate:YES];
            break;
        }
			
	case HB_STATE_PAUSED:
		break;
		
	case HB_STATE_WORKDONE:
		{
			// HB_STATE_WORKDONE happpens as a result of hblib finishing all its jobs
			// or someone calling hb_stop. In the latter case, hb_stop does not clear
			// out the remaining passes/jobs in the queue. We'll do that here.
						
			// Delete all remaining scans of this job, ie, delete whole encodes.
			hb_job_t * job;
			while( ( job = hb_job( mHandbrakeHandle, 0 ) ) && (job->sequence_id != 0) )
				hb_rem( mHandbrakeHandle, job );

			[aTimer invalidate];
			[self finishedTranscode];
		}
		break;
	}
}

- (void) uiActivityNotification:(NSNotification*)aNotification
{
	// Just got a connection to the UI Activity display
	mUIActivity = [[[[NSApp delegate] recServer] uiActivity] retain];
	
	// Since the connection just became available we'll create an activity now
	mActivityToken = [mUIActivity createActivity];
	[mUIActivity setActivity:mActivityToken progressMaxValue:100.0];
	[mUIActivity setActivity:mActivityToken progressDoubleValue:mLastProgressValue];
	
	// For a timer call now - it'll update the status on the activity display etc.
	[self transcodingProgressTimer:nil];
}

#pragma mark Handbrake Preset Strings to Int values

// This collection of routines is responsible for translating between a string value in a preset and
// the index value of the associated item in the Handbrake UI. Handbrake uses this approach to link
// popup menu item choices in the UI to discrete values from tables etc.

- (int) audioSampleRateIndexForString:(NSString*) aString
{
	if ([aString compare:@"22.05"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"24"] == NSOrderedSame)
		return 1;
	else if ([aString compare:@"32"] == NSOrderedSame)
		return 2;
	else if ([aString compare:@"44.1"] == NSOrderedSame)
		return 3;
	else if ([aString compare:@"48"] == NSOrderedSame)
		return 4;
	else
		return -1;		// Force a crash ! This is bad !
}

- (int) formatIndexForString:(NSString*)aString
{
	if ([aString compare:@"MP4 file"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"MKV file"] == NSOrderedSame)
		return 1;
	else if ([aString compare:@"AVI file"] == NSOrderedSame)
		return 2;
	else if ([aString compare:@"OGM file"] == NSOrderedSame)
		return 3;
	else
		return -1;
}

- (int) codecIndexForString:(NSString*)aString
{
	if ([aString compare:@"MPEG-4 Video / AAC Audio"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"AVC/H.264 Video / AAC Audio"] == NSOrderedSame)
		return 1;
	else
		return -1;
}

- (int) videoEncoderIndexForString:(NSString*)aString
{
	if ([aString compare:@"x264 (h.264 Main)"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"x264 (h.264 iPod)"] == NSOrderedSame)
		return 1;
	else
		return -1;
}

- (int) videoFrameRateIndexForString:(NSString*)aString
{
	if ([aString compare:@"Same as source"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"5"] == NSOrderedSame)
		return 1;
	else if ([aString compare:@"10"] == NSOrderedSame)
		return 2;
	else if ([aString compare:@"12"] == NSOrderedSame)
		return 3;
	else if ([aString compare:@"15"] == NSOrderedSame)
		return 4;
	else if ([aString compare:@"23.976 (NTSC Film)"] == NSOrderedSame)
		return 5;
	else if ([aString compare:@"24"] == NSOrderedSame)
		return 6;
	else if ([aString compare:@"25 (PAL Film/Video)"] == NSOrderedSame)
		return 7;
	else if ([aString compare:@"29.97 (NTSC Video)"] == NSOrderedSame)
		return 8;
	else
		return -1;
}

- (int) subtitleIndexForString:(NSString*)aString
{
	if ([aString compare:@"None"] == NSOrderedSame)
		return 0;
	else if ([aString compare:@"Autoselect"] == NSOrderedSame)
		return 1;
	else
		return -1;
}

- (int) audioBitRateTagForString:(NSString*)aString
{
	// Although handbrake uses a tag to encode the audio bitrate (ie 128 for 128Kbps) we can
	// just do a straight conversion on the string value - it should be fine.
	return [aString intValue];
}

@end
