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

#import "RSTranscodingImp.h"
#import "RSTranscoding.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"
#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSTranscodeController.h"

@interface RSTranscodingImp(Private)
- (int)acodecForString:(NSString *)codec;
- (NSString *) audioCodecStringForPreset:(NSDictionary *)aPreset;
- (NSString *) audioSampleRateForPreset:(NSDictionary *)aPreset;
- (NSString *) audioBitrateForPreset:(NSDictionary *)aPreset;
- (NSString *) drcForPreset:(NSDictionary *)aPreset;
- (NSString *) audioMixdownForPreset:(NSDictionary *)aPreset;

@end

static int is_sample_rate_valid(int rate);

const int kDefaultAudioBitRate = 160;

@implementation RSTranscodingImp

#pragma mark Properties

@synthesize mTranscoding;

#pragma mark Initialization & Setup

- (id)initWithTranscoding:(RSTranscoding *)aTranscoding {
  self = [super init];
  if (self != nil) {
    mTranscoding = [aTranscoding retain];

    // Get whatever the server has for a UI Activity now
    mUIActivity = [[[[NSApp delegate] recServer] uiActivity] retain];

    // We need to know if an activity UI becomes available.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiActivityNotification:) name:RSNotificationUIActivityAvailable object:nil];
    
    mDefaultAcodec = HB_ACODEC_FAAC;
    mAudios = hb_list_init();
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [mTranscoding release];
  [mUIActivity release];
  [super dealloc];
}

- (void)setTitle:(hb_title_t *)aTitle {
  mHandbrakeTitle = aTitle;
}

- (void)setupPictureDimensionsWithPreset:(NSDictionary *)aPreset {
  if ([[aPreset objectForKey:@"UsesPictureSettings"]  intValue] == 2 ||
      [[aPreset objectForKey:@"UsesMaxPictureSettings"]  intValue] == 1) {
    /* Use Max Picture settings for whatever the dvd is.*/
    mHandbrakeJob->width = mHandbrakeTitle->width;
    mHandbrakeJob->height = mHandbrakeTitle->height;
    mHandbrakeJob->keep_ratio = [[aPreset objectForKey:@"PictureKeepRatio"]  intValue];
    if (mHandbrakeJob->keep_ratio == 1) {
      hb_fix_aspect(mHandbrakeJob, HB_KEEP_WIDTH);
      if (mHandbrakeJob->height > mHandbrakeTitle->height) {
        mHandbrakeJob->height = mHandbrakeTitle->height;
        hb_fix_aspect(mHandbrakeJob, HB_KEEP_HEIGHT);
      }
    }
    mHandbrakeJob->anamorphic.mode = [[aPreset objectForKey:@"PicturePAR"]  intValue];
  } else {
    /* If not 0 or 2 we assume objectForKey:@"UsesPictureSettings is 1 which is "Use picture sizing from when the preset was set" */
    /* we check to make sure the presets width/height does not exceed the sources width/height */
    if (mHandbrakeTitle->width < [[aPreset objectForKey:@"PictureWidth"]  intValue]
        || mHandbrakeTitle->height < [[aPreset objectForKey:@"PictureHeight"]  intValue]) {
      /* if so, then we use the sources height and width to avoid scaling up */
      mHandbrakeJob->width = mHandbrakeTitle->width;
      mHandbrakeJob->height = mHandbrakeTitle->height;
    } else {
      // source width/height is >= the preset height/width
      /* we can go ahead and use the presets values for height and width */
      mHandbrakeJob->width = [[aPreset objectForKey:@"PictureWidth"]  intValue];
      mHandbrakeJob->height = [[aPreset objectForKey:@"PictureHeight"]  intValue];
    }
    mHandbrakeJob->keep_ratio = [[aPreset objectForKey:@"PictureKeepRatio"]  intValue];
    if (mHandbrakeJob->keep_ratio == 1) {
      hb_fix_aspect(mHandbrakeJob, HB_KEEP_WIDTH );
      if (mHandbrakeJob->height > mHandbrakeTitle->height) {
        mHandbrakeJob->height = mHandbrakeTitle->height;
        hb_fix_aspect(mHandbrakeJob, HB_KEEP_HEIGHT);
      }
    }
    mHandbrakeJob->anamorphic.mode = [[aPreset objectForKey:@"PicturePAR"]  intValue];
  }
}

- (void)setupVideoCodecsWithPreset:(NSDictionary *)aPreset {
  // AWK - Fix Me, read the values from the preset
  float vquality = 20.0;
  int vcodec = HB_VCODEC_X264;
  int vbitrate = 0;
  int vrate = 0;
  int cfr = 0;
  
  vquality = [[aPreset objectForKey:@"VideoQualitySlider"] floatValue];
  vbitrate = [[aPreset objectForKey:@"VideoAvgBitrate"] intValue];
  
  if (vquality >= 0.0 && ((vquality <= 1.0) || (vcodec == HB_VCODEC_X264) || (vcodec == HB_VCODEC_FFMPEG))) {
    mHandbrakeJob->vquality = vquality;
    mHandbrakeJob->vbitrate = 0;
  } else if (vbitrate) {
    mHandbrakeJob->vquality = -1.0;
    mHandbrakeJob->vbitrate = vbitrate;
  }
  
  if (vcodec) {
    mHandbrakeJob->vcodec = vcodec;
  }
  
  if (vrate) {
    mHandbrakeJob->cfr = cfr;
    mHandbrakeJob->vrate = 27000000;
    mHandbrakeJob->vrate_base = vrate;
  } else if (cfr) {
    // cfr or pfr flag with no rate specified implies
    // use the title rate.
    mHandbrakeJob->cfr = cfr;
    mHandbrakeJob->vrate = mHandbrakeTitle->rate;
    mHandbrakeJob->vrate_base = mHandbrakeTitle->rate_base;
  }
}

- (void)findAudioTracks:(NSString*) trackSelection {
  char *atracks = strdup([trackSelection UTF8String]);
  
  if (atracks) {
    char * token = strtok(atracks, ",");
    if (token == NULL) {
      token = optarg;
    }
    int track_start, track_end;
    while( token != NULL ) {
      hb_audio_config_t * audio = NULL;
      audio = calloc(1, sizeof(*audio));
      hb_audio_config_init(audio);
      if (strlen(token) >= 3) {
        if (sscanf(token, "%d-%d", &track_start, &track_end) == 2) {
          int i;
          for (i = track_start - 1; i < track_end; i++) {
            if (i != track_start - 1) {
              audio = calloc(1, sizeof(*audio));
              hb_audio_config_init(audio);
            }
            audio->in.track = i;
            audio->out.track = mNumAudioTracks++;
            hb_list_add(mAudios, audio);
          }
        } else if (!strcasecmp(token, "none")) {
          audio->in.track = audio->out.track = -1;
          audio->out.codec = 0;
          hb_list_add(mAudios, audio);
          break;
        } else {
          fprintf(stderr, "ERROR: Unable to parse audio input \"%s\", skipping.",
                  token);
          free(audio);
        }
      } else {
        audio->in.track = atoi(token) - 1;
        audio->out.track = mNumAudioTracks++;
        hb_list_add(mAudios, audio);
      }
      token = strtok(NULL, ",");
    }
  }
  
  free(atracks);
}

- (void)setupAudioTracks {
  hb_audio_config_t *audio = NULL;
  
  if (hb_list_count(mAudios) == 0 &&
      hb_list_count(mHandbrakeJob->title->list_audio) > 0) {        
    /* Create a new audio track with default settings */
    audio = calloc(1, sizeof(*audio));
    hb_audio_config_init(audio);
    /* Add it to our audios */
    hb_list_add(mAudios, audio);
  }
  
  int tmp_num_audio_tracks = mNumAudioTracks = hb_list_count(mAudios);
  int i;
  for (i = 0; i < tmp_num_audio_tracks; i++) {
    audio = hb_list_item(mAudios, 0);
    if ((audio == NULL) || (audio->in.track == -1) ||
        (audio->out.track == -1) || (audio->out.codec == 0)) {
      mNumAudioTracks--;
    } else {
      if (hb_audio_add( mHandbrakeJob, audio) == 0) {
        fprintf(stderr, "ERROR: Invalid audio input track '%u', exiting.\n", 
                audio->in.track + 1 );
        mNumAudioTracks--;
        return;  
      }
    }
    hb_list_rem(mAudios, audio);
    if (audio != NULL) {
      if (audio->out.name) {
        free( audio->out.name);
      }
    }
    free( audio );
  }
}

- (void)setupAudioWithCodecs:(NSString *)codecString {
  int i = 0;
  char *acodecs = strdup([codecString UTF8String]);
  int acodec;
  
  if (acodecs) {
    char * token = strtok(acodecs, ",");
    if (token == NULL) {
      token = acodecs;
    }
    while (token != NULL) {
      if ((acodec = [self acodecForString:[NSString stringWithUTF8String:token]]) == -1) {
        fprintf(stderr, "Invalid codec %s, using default for container.\n", token);
        acodec = mDefaultAcodec;
      }
      if (i < mNumAudioTracks) {
        hb_audio_config_t * audio = NULL;
        audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
        audio->out.codec = acodec;
      } else {
        hb_audio_config_t * last_audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i - 1);
        hb_audio_config_t audio;
        
        if (last_audio) {
          fprintf(stderr, "More audio codecs than audio tracks, copying track %i and using encoder %s\n",
                  i, token);
          hb_audio_config_init(&audio);
          audio.in.track = last_audio->in.track;
          audio.out.track = mNumAudioTracks++;
          audio.out.codec = acodec;
          hb_audio_add(mHandbrakeJob, &audio);
        } else {
          fprintf(stderr, "Audio codecs and no valid audio tracks, skipping codec %s\n", token);
        }
      }
      token = strtok(NULL, ",");
      i++;
    }
  }
  if (i < mNumAudioTracks) {
    /* We have fewer inputs than audio tracks, use the default codec for
     * this container for the remaining tracks. Unless we only have one input
     * then use that codec instead.
     */
    if (i != 1) {
      acodec = mDefaultAcodec;
    }
    for ( ; i < mNumAudioTracks; i++) {
      hb_audio_config_t * audio = NULL;
      audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      audio->out.codec = acodec;
    }
  }
  free(acodecs);
}

- (void)setupAudioSampleRate:(NSString *) audioRatesString {
  char *arates = strdup([audioRatesString UTF8String]);
  int i = 0;
  int arate;
  hb_audio_config_t *audio = NULL;
    
  if (arates) {
    char * token = strtok(arates, ",");
    if (token == NULL) {
      token = arates;
    }
    while (token != NULL) {
      arate = atoi(token);
      audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      int j;
      
      for (j=0;j < hb_audio_rates_count;j++) {
        if (!strcmp(token, hb_audio_rates[j].string)) {
          arate = hb_audio_rates[j].rate;
          break;
        }
      }
      
      if (audio != NULL) {
        if (!is_sample_rate_valid(arate)) {
          fprintf(stderr, "Invalid sample rate %d, using input rate %d\n", arate, audio->in.samplerate);
          arate = audio->in.samplerate;
        }
        
        audio->out.samplerate = arate;
        if ((++i) >= mNumAudioTracks) {
          break;  /* We have more inputs than audio tracks, oops */
        }
      } else {
        fprintf(stderr, "Ignoring sample rate %d, no audio tracks\n", arate);
      }
      token = strtok(NULL, ",");
    }
  }
  if (i < mNumAudioTracks) {
    /* We have fewer inputs than audio tracks, use default sample rate.
     * Unless we only have one input, then use that for all tracks.
     */
    if (i != 1) {
      audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      arate = audio->in.samplerate;
    }
    for ( ;i < mNumAudioTracks;i++) {
      audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      audio->out.samplerate = arate;
    }
  }
  free(arates);
}

- (void)setupAudioBitrate:(NSString *) audioBitratesString {
  char *abitrates = strdup([audioBitratesString UTF8String]);
  int i = 0;
  int abitrate;
  
  if (abitrates) {
    char * token = strtok(abitrates, ",");
    if (token == NULL) {
      token = abitrates;
    }
    while (token != NULL) {
      abitrate = atoi(token);
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      
      if (audio != NULL) {
        audio->out.bitrate = abitrate;
        if ((++i) >= mNumAudioTracks) {
          break;  /* We have more inputs than audio tracks, oops */
        }
      } else {
        fprintf(stderr, "Ignoring bitrate %d, no audio tracks\n", abitrate);
      }
      token = strtok(NULL, ",");
    }
  }
  if (i < mNumAudioTracks) {
    /* We have fewer inputs than audio tracks, use the default bitrate
     * for the remaining tracks. Unless we only have one input, then use
     * that for all tracks.
     */
    if (i != 1) {
      abitrate = kDefaultAudioBitRate;
    }
    for (; i < mNumAudioTracks; i++) {
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      audio->out.bitrate = abitrate;
    }
  }
  free(abitrates);
}

- (void)setupAudioDRC:(NSString *)DRCString {
  int i = 0;
  char *dynamic_range_compression = strdup([DRCString UTF8String]);
  float d_r_c;
  
  if (dynamic_range_compression) {
    char * token = strtok(dynamic_range_compression, ",");
    if (token == NULL) {
      token = dynamic_range_compression;
    }
    while (token != NULL) {
      d_r_c = atof(token);
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      if (audio != NULL) {
        audio->out.dynamic_range_compression = d_r_c;
        if ((++i) >= mNumAudioTracks) {
          break;  /* We have more inputs than audio tracks, oops */
        }
      } else {
        fprintf(stderr, "Ignoring drc, no audio tracks\n");
      }
      token = strtok(NULL, ",");
    }
  }
  if (i < mNumAudioTracks) {
    /* We have fewer inputs than audio tracks, use no DRC for the remaining
     * tracks. Unless we only have one input, then use the same DRC for all
     * tracks.
     */
    if (i != 1) {
      d_r_c = 0;
    }
    for (; i < mNumAudioTracks; i++) {
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      audio->out.dynamic_range_compression = d_r_c;
    }
  }
  free(dynamic_range_compression);
}

- (void)setupAudioMixdown:(NSString *)mixdownString {
  int i = 0;
  char *mixdowns = strdup([mixdownString UTF8String]);
  int mixdown;
  
  if (mixdowns) {
    char * token = strtok(mixdowns, ",");
    if (token == NULL) {
      token = mixdowns;
    }
    while (token != NULL) {
      mixdown = hb_mixdown_get_mixdown_from_short_name(token);
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      if (audio != NULL) {
        audio->out.mixdown = mixdown;
        if ((++i) >= mNumAudioTracks) {
          break;  /* We have more inputs than audio tracks, oops */
        }
      } else {
        fprintf(stderr, "Ignoring mixdown, no audio tracks\n");
      }
      token = strtok(NULL, ",");
    }
  }
  if (i < mNumAudioTracks) {
    /* We have fewer inputs than audio tracks, use DPLII for the rest. Unless
     * we only have one input, then use that.
     */
    if (i != 1) {
      mixdown = HB_AMIXDOWN_DOLBYPLII;
    }
    for (; i < mNumAudioTracks; i++) {
      hb_audio_config_t *audio = hb_list_audio_config_item(mHandbrakeJob->list_audio, i);
      audio->out.mixdown = mixdown;
    }
  }
  free(mixdowns);
}

- (void) setupFiltersWithPreset:(NSDictionary *)aPreset {
  mHandbrakeJob->filters = hb_list_init();
  
  if ([[aPreset objectForKey:@"UsesPictureFilters"]  intValue] > 0) {
    if ([[aPreset objectForKey:@"PictureDetelecine"] intValue] == 1) {
      hb_filter_detelecine.settings = (char *) [[aPreset objectForKey:@"PictureDetelecineCustom"] UTF8String];
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    } else if ([[aPreset objectForKey:@"PictureDetelecine"] intValue] == 2) {
      hb_filter_detelecine.settings = NULL;
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    }

    if ([[aPreset objectForKey:@"PictureDecomb"] intValue] == 1) {
      hb_filter_decomb.settings = (char *) [[aPreset objectForKey:@"PictureDecombCustom"] UTF8String];
      hb_list_add( mHandbrakeJob->filters, &hb_filter_decomb );
    } else if ([[aPreset objectForKey:@"PictureDecomb"] intValue] == 2) {
      hb_filter_decomb.settings = NULL;
      hb_list_add( mHandbrakeJob->filters, &hb_filter_decomb );
    }
    
    if ([[aPreset objectForKey:@"PictureDeinterlace"] intValue] == 1) {
      hb_filter_detelecine.settings = (char *) [[aPreset objectForKey:@"PictureDeinterlaceCustom"] UTF8String];
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    } else if ([[aPreset objectForKey:@"PictureDeinterlace"] intValue] == 2) {
      hb_filter_detelecine.settings = "-1";
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    } else if ([[aPreset objectForKey:@"PictureDeinterlace"] intValue] == 3) {
      hb_filter_detelecine.settings = "2";
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    } else if ([[aPreset objectForKey:@"PictureDeinterlace"] intValue] == 4) {
      hb_filter_detelecine.settings = "0";
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    }

    /*
     * Even if Deinterlace hasn't been specified we default to using the 'slow'
     * method. We know we're recording TV programs - they're going to be interlaced!
     */
    if (NULL == hb_filter_detelecine.settings) {
      hb_filter_detelecine.settings = "2";
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    }
 
    if ([[aPreset objectForKey:@"PictureDeblock"] intValue] == 1) {
      /* if its a one, then its the old on/off deblock, set on to 5*/
      asprintf(&hb_filter_deblock.settings, "%d", 5);
      hb_list_add( mHandbrakeJob->filters, &hb_filter_deblock );
    } else {
      /* use the settings intValue */
      asprintf(&hb_filter_deblock.settings, "%d", [[aPreset objectForKey:@"PictureDeblock"] intValue]);
      hb_list_add( mHandbrakeJob->filters, &hb_filter_deblock );
    }
    
    if ([[aPreset objectForKey:@"PictureDenoise"] intValue] == 1) {
      hb_filter_denoise.settings = (char *) [[aPreset objectForKey:@"PictureDenoiseCustom"] UTF8String];
      hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );
    } else if ([[aPreset objectForKey:@"PictureDenoise"] intValue] == 2) {
      hb_filter_denoise.settings = "2:1:2:3"; 
      hb_list_add( mHandbrakeJob->filters, &hb_filter_detelecine );
    } else if ([[aPreset objectForKey:@"PictureDenoise"] intValue] == 3) {
      hb_filter_denoise.settings = "3:2:2:3"; 
      hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );
    } else if ([[aPreset objectForKey:@"PictureDenoise"] intValue] == 4) {
      hb_filter_denoise.settings = "7:7:5:5"; 
      hb_list_add( mHandbrakeJob->filters, &hb_filter_denoise );
    }
  }
}

- (void)setupJobWithPreset:(NSDictionary *)aPreset {
  mHandbrakeJob = mHandbrakeTitle->job;

  [self setupPictureDimensionsWithPreset:aPreset];

  /* Chapter selection  - transport streams have no chapters, just use 1 & 1 here */
  mHandbrakeJob->chapter_start = 1;
  mHandbrakeJob->chapter_end   = 1;
  
  mHandbrakeJob->deinterlace = 0;
  mHandbrakeJob->grayscale = 0;
  
  [self setupFiltersWithPreset:aPreset];
  [self setupVideoCodecsWithPreset:aPreset];

  /* Audio Settings */
  [self findAudioTracks:@"1,1"];
  [self setupAudioTracks];
  [self setupAudioWithCodecs:[self audioCodecStringForPreset:aPreset]];
  [self setupAudioSampleRate:[self audioSampleRateForPreset:aPreset]];
  [self setupAudioBitrate:[self audioBitrateForPreset:aPreset]];
  [self setupAudioDRC:[self drcForPreset:aPreset]];
  [self setupAudioMixdown:[self audioMixdownForPreset:aPreset]];
  
  if ([[aPreset objectForKey:@"Mp4LargeFile"] intValue] == 1) {
    mHandbrakeJob->largeFileSize = 1;
  } else {
    mHandbrakeJob->largeFileSize = 0;
  }
  
  if ([[aPreset objectForKey:@"Mp4HttpOptimize"] intValue] == 1) {
    mHandbrakeJob->mp4_optimize = 1;
  } else {
    mHandbrakeJob->mp4_optimize = 0;
  }

  if ([[aPreset objectForKey:@"Mp4iPodCompatible"] intValue] == 1) {
    mHandbrakeJob->ipod_atom = 1;
  } else {
    mHandbrakeJob->ipod_atom = 0;
  }
  
  if ([aPreset objectForKey:@"x264Option"]) {
      mHandbrakeJob->x264opts = strdup([[aPreset objectForKey:@"x264Option"] UTF8String]);
  } else {
    /* avoids a bus error crash when options aren't specified */
    mHandbrakeJob->x264opts =  NULL;
  }
}

- (void)setupTwoPassEncoding {
  char *x264opts2 = NULL;
  /*
   * If subtitle_scan is enabled then only turn it on
   * for the first pass and then off again for the
   * second.
   */
  mHandbrakeJob->pass = 1;
  
  mHandbrakeJob->indepth_scan = 0;
  
  if (mHandbrakeJob->x264opts) {
    x264opts2 = strdup(mHandbrakeJob->x264opts);
  }
  
  /*
   * If turbo options have been selected then append them
   * to the x264opts now (size includes one ':' and the '\0')
   */
   // AWK Fix Me - Read Turbo Opts from the preset ?
  if (0 /*turbo_opts_enabled*/) {
    static char * turbo_opts = "ref=1:subme=2:me=dia:analyse=none:trellis=0:no-fast-pskip=0:8x8dct=0:weightb=0";

    int size = (mHandbrakeJob->x264opts ? strlen(mHandbrakeJob->x264opts) : 0) + strlen(turbo_opts) + 2;
    char *tmp_x264opts;
    
    tmp_x264opts = malloc(size * sizeof(char));
    if (mHandbrakeJob->x264opts) {
      snprintf(tmp_x264opts, size, "%s:%s", mHandbrakeJob->x264opts, turbo_opts );
      free(mHandbrakeJob->x264opts);
    } else {
      /*
       * No x264opts to modify, but apply the turbo options
       * anyway as they may be modifying defaults
       */
      snprintf(tmp_x264opts, size, "%s", turbo_opts);
    }
    fprintf(stderr, "Modified x264 options for pass 1 to append turbo options: %s\n",
            tmp_x264opts);
    
    mHandbrakeJob->x264opts = tmp_x264opts;
  }
  hb_add( mHandbrakeHandle, mHandbrakeJob );
  
  mHandbrakeJob->pass = 2;
  /*
   * On the second pass we turn off subtitle scan so that we
   * can actually encode using any subtitles that were auto
   * selected in the first pass (using the whacky select-subtitle
   * attribute of the job).
   */
  mHandbrakeJob->indepth_scan = 0;
  
  mHandbrakeJob->x264opts = x264opts2;
  
  hb_add(mHandbrakeHandle, mHandbrakeJob);
}

- (void)beginTranscodeWithHandle:(hb_handle_t *)handbrakeHandle toDestinationPath:(NSString *)destinationPath usingPreset:(NSDictionary *)aPreset {
  // Hold on to the Handbrake handle
  mHandbrakeHandle = handbrakeHandle;

  // Setup final output options including two pass options, subtitles and destination file
  /* Destination file */
  mHandbrakeJob->file = [destinationPath UTF8String];

  if ([[aPreset objectForKey:@"VideoTwoPass"] intValue] > 0) {
    [self setupTwoPassEncoding];
  } else {
    mHandbrakeJob->indepth_scan = 0;
    mHandbrakeJob->pass = 0;
    hb_add( mHandbrakeHandle, mHandbrakeJob );
  }

  hb_start(mHandbrakeHandle);

  // Create an activity token
  if (mUIActivity) {
    mActivityToken = [mUIActivity createActivity];
    mActivityToken = [mUIActivity setActivity:mActivityToken progressMaxValue:100.0];
  }

  // Start the progress timer
  [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(transcodingProgressTimer:) userInfo:nil repeats:YES];
}

- (void)finishedTranscode {
  [mUIActivity endActivity:mActivityToken];
  [mTranscoding finishedTranscode];
  [[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationTranscodingFinished object:self];
}

#pragma mark Timers Callbacks etc

- (void)transcodingProgressTimer:(NSTimer *)aTimer {
  hb_state_t s;
  hb_get_state( mHandbrakeHandle, &s );

  BOOL shouldCancel = NO;
  mActivityToken = [mUIActivity shouldCancelActivity:mActivityToken cancel:&shouldCancel];
  if (shouldCancel) {
    // Calling stop will cause an asynchronous stop reflected
    // in the state value
    hb_stop(mHandbrakeHandle);
  }

  switch( s.state ) {
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

      if( s.param.working.seconds > -1 ) {
        [string appendFormat:
        @" (%.2f fps, avg %.2f fps, ETA %02dh%02dm%02ds)",
        s.param.working.rate_cur, s.param.working.rate_avg, s.param.working.hours, s.param.working.minutes, s.param.working.seconds];
      }
      mActivityToken = [mUIActivity setActivity:mActivityToken infoString:string];

      /* Update progress bar */
      mActivityToken = [mUIActivity setActivity:mActivityToken incrementBy:100.0 * s.param.working.progress - mLastProgressValue];
      mLastProgressValue = 100.0 * s.param.working.progress;
      break;
    }

    case HB_STATE_MUXING:
    {
      /* Update text field */
      if (mTranscoding.schedule.program.subTitle != nil) {
        mActivityToken = [mUIActivity setActivity:mActivityToken infoString:[NSString stringWithFormat:@"Muxing: %@ - %@", mTranscoding.schedule.program.title, mTranscoding.schedule.program.subTitle]];
      } else {
        mActivityToken = [mUIActivity setActivity:mActivityToken infoString:[NSString stringWithFormat:@"Muxing: %@", mTranscoding.schedule.program.title]];
      }

      /* Update slider */
      mActivityToken = [mUIActivity setActivity:mActivityToken progressIndeterminate:YES];
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
      while( ( job = hb_job( mHandbrakeHandle, 0 ) ) && (job->sequence_id != 0) ) {
        hb_rem( mHandbrakeHandle, job );
      }

      [aTimer invalidate];
      [self finishedTranscode];
    }
    break;
  }
}

- (void)uiActivityNotification:(NSNotification *)aNotification {
  // Just got a connection to the UI Activity display
  mUIActivity = [[[[NSApp delegate] recServer] uiActivity] retain];

  // Since the connection just became available we'll create an activity now
  mActivityToken = [mUIActivity createActivity];
  mActivityToken = [mUIActivity setActivity:mActivityToken progressMaxValue:100.0];
  mActivityToken = [mUIActivity setActivity:mActivityToken progressDoubleValue:mLastProgressValue];

  // For a timer call now - it'll update the status on the activity display etc.
  [self transcodingProgressTimer:nil];
}

#pragma mark Handbrake Preset Strings to Int values

// This collection of routines is responsible for translating between a string value in a preset and
// the index value of the associated item in the Handbrake UI. Handbrake uses this approach to link
// popup menu item choices in the UI to discrete values from tables etc.

- (int)audioSampleRateIndexForString:(NSString *)aString {
  if ([aString compare:@"22.05"] == NSOrderedSame) {
    return 0;
  } else if ([aString compare:@"24"] == NSOrderedSame) {
    return 1;
  } else if ([aString compare:@"32"] == NSOrderedSame) {
    return 2;
  } else if ([aString compare:@"44.1"] == NSOrderedSame) {
    return 3;
  } else if ([aString compare:@"48"] == NSOrderedSame) {
    return 4;
  } else {
    return -1;    // Force a crash ! This is bad !
  }
}

 - (int)acodecForString:(NSString *)codec {
  if ([codec isEqualToString:@"ac3"]) {
    return HB_ACODEC_AC3;
  } else if ([codec isEqualToString:@"dts"] || [codec isEqualToString:@"dca"]) {
    return HB_ACODEC_DCA;
  } else if ([codec isEqualToString:@"lame"]) {
    return HB_ACODEC_LAME;
  } else if ([codec isEqualToString:@"faac"]) {
    return HB_ACODEC_FAAC;
  } else if ([codec isEqualToString:@"vorbis"]) {
    return HB_ACODEC_VORBIS;
  } else if ([codec isEqualToString:@"ca_aac"]) {
    return HB_ACODEC_CA_AAC;
  } else {
    return -1;
  }
}
              
static int is_sample_rate_valid(int rate)
{
  int i;
  for( i = 0; i < hb_audio_rates_count; i++ )
  {
    if (rate == hb_audio_rates[i].rate)
      return 1;
  }
  return 0;
}


- (NSString *) audioCodecStringForPreset:(NSDictionary *)aPreset
{
  NSMutableString *codecString = nil;
  
  NSArray *audioList = [aPreset valueForKey:@"AudioList"];
  for (NSDictionary *audioDetails in audioList) {
    if ([[audioDetails objectForKey:@"AudioEncoder"] isEqualToString:@"AAC (faac)"]) {
      if (codecString) {
        [codecString appendString:@",faac"];
      } else {
        codecString = [NSMutableString stringWithString:@"faac"];
      }
    } else if ([[audioDetails objectForKey:@"AudioEncoder"] isEqualToString:@"AC3 Passthru"]) {
      if (codecString) {
        [codecString appendString:@",ac3"];
      } else {
        codecString = [NSMutableString stringWithString:@"ac3"];
      }
    }
  }
  
  return codecString;
}

- (NSString *) audioSampleRateForPreset:(NSDictionary *)aPreset
{
  NSMutableString *sampleRateString = nil;
  
  NSArray *audioList = [aPreset valueForKey:@"AudioList"];
  for (NSDictionary *audioDetails in audioList) {
    if ([audioDetails objectForKey:@"AudioSamplerate"]){
      if (sampleRateString) {
        [sampleRateString appendFormat:@",%@", [audioDetails objectForKey:@"AudioSamplerate"]];
      } else {
        sampleRateString = [NSMutableString stringWithFormat:@"%@", [audioDetails objectForKey:@"AudioSamplerate"]];
      }
    }
  }
  
  return sampleRateString;
}
   
- (NSString *) audioBitrateForPreset:(NSDictionary *)aPreset
{
  NSMutableString *bitRateString = nil;
  
  NSArray *audioList = [aPreset valueForKey:@"AudioList"];
  for (NSDictionary *audioDetails in audioList) {
    if ([audioDetails objectForKey:@"AudioBitrate"]){
      if (bitRateString) {
        [bitRateString appendFormat:@",%@", [audioDetails objectForKey:@"AudioBitrate"]];
      } else {
        bitRateString = [NSMutableString stringWithFormat:@"%@", [audioDetails objectForKey:@"AudioBitrate"]];
      }
    }
  }
  
  return bitRateString;
}

- (NSString *) drcForPreset:(NSDictionary *)aPreset
{
  NSMutableString *drcString = nil;
  
  NSArray *audioList = [aPreset valueForKey:@"AudioList"];
  for (NSDictionary *audioDetails in audioList) {
    if ([audioDetails objectForKey:@"AudioTrackDRCSlider"]){
      if (drcString) {
        [drcString appendFormat:@",%.1f", [[audioDetails objectForKey:@"AudioTrackDRCSlider"] floatValue]];
      } else {
        drcString = [NSMutableString stringWithFormat:@"%.1f", [[audioDetails objectForKey:@"AudioTrackDRCSlider"] floatValue]];
      }
    }
  }
  
  return drcString;
}

- (NSString *) audioMixdownForPreset:(NSDictionary *)aPreset
{
  NSMutableString *mixdownString = nil;
  
  NSArray *audioList = [aPreset valueForKey:@"AudioList"];
  for (NSDictionary *audioDetails in audioList) {
    if ([[audioDetails objectForKey:@"AudioMixdown"] isEqualToString:@"Dolby Pro Logic II"]) {
      if (mixdownString) {
        [mixdownString appendString:@",dpl2"];
      } else {
        mixdownString = [NSMutableString stringWithString:@"dpl2"];
      }
    } else  if ([[audioDetails objectForKey:@"AudioMixdown"] isEqualToString:@"AC3 Passthru"]) {
      if (mixdownString) {
        [mixdownString appendString:@",auto"];
      } else {
        mixdownString = [NSMutableString stringWithString:@"auto"];
      }
    }
  }
  return mixdownString;
}
@end
