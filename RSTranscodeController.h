//
//  RSTranscodeController.h
//  recsched
//
//  Created by Andrew Kimpton on 10/10/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include "hb.h"

@class RSTranscoding;

@interface RSTranscodeController : NSObject {
    hb_handle_t	   *mHandbrakeHandle;		// Connection to the Handbrake libraries
	
	NSArrayController *mRecordingsArrayController;
	NSArrayController *mTranscodingsArrayController;
	
	RSTranscoding *mCurrentTranscoding;
}

@end
