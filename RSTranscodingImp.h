//
//  RSTranscodingImp.h
//  recsched
//
//  Created by Andrew Kimpton on 10/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "hb.h"

@class RSTranscoding;

@interface RSTranscodingImp : NSObject {
	hb_title_t *mHandbrakeTitle;
	hb_job_t *mHandbrakeJob;
	hb_handle_t *mHandbrakeHandle;
	
	RSTranscoding *mTranscoding;

	id mUIActivity;
	size_t mActivityToken;
	float mLastProgressValue;
}

- (id) initWithTranscoding:(RSTranscoding *)mTranscoding;

- (void) setTitle:(hb_title_t*)aTitle;
- (void) setupJobWithPreset:(NSDictionary*)aPreset;
- (void) beginTranscodeWithHandle:(hb_handle_t*)handbrakeHandle toDestinationPath:(NSString*)destinationPath usingPreset:(NSDictionary*)aPreset;

@property (retain,getter=transcoding) RSTranscoding * mTranscoding;

@end
