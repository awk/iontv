/*
 *  PreferenceKeys.h
 *  recsched
 *
 *  Created by Andrew Kimpton on 10/19/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

extern NSString *kScheduleDownloadDurationKey;
extern NSString *kWebServicesSDUsernameKey;
extern NSString *kScheduleDownloadDurationKey;
extern NSString *kRecordedProgramsLocationKey;
extern NSString *kTranscodedProgramsLocationKey;

extern NSString	*kTranscodeProgramsKey;
extern NSString	*kDeleteRecordingsAfterTranscodeKey;
extern NSString	*kAddTranscodingsToiTunesKey;
extern NSString *kDeleteTranscodingsAfterAddKey;

// Not really a key - just a string that's shared between the preferences, preferences UI and the download thread
extern NSString *kWebServicesSDHostname;
extern NSString *kWebServicesSDPath;