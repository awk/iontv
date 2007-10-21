/*
 *  PreferenceKeys.c
 *  recsched
 *
 *  Created by Andrew Kimpton on 10/19/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#include "PreferenceKeys.h"

NSString *kWebServicesSDUsernameKey = @"SDUsername";			// Here because we don't link Preferences.m into the server
NSString *kScheduleDownloadDurationKey = @"scheduleDownloadDuration";
NSString *kRecordedProgramsLocationKey = @"recordedProgramsLocation";
NSString *kTranscodedProgramsLocationKey = @"transcodedProgramsLocation";

NSString *kTranscodeProgramsKey = @"transcodePrograms";
NSString *kDeleteRecordingsAfterTranscodeKey = @"deleteRecordingsAfterTranscode";
NSString *kAddTranscodingsToiTunesKey = @"addTranscodingsToiTunes";
NSString *kDeleteTranscodingsAfterAddKey = @"deleteTranscodingsAfterAdd";

