//
//  RSTranscoding.m
//  recsched
//
//  Created by Andrew Kimpton on 10/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSTranscoding.h"
#import "RSRecording.h"

@implementation RSTranscoding

- (void) dealloc
{
	[transcodingImp release];
	[super dealloc];
}

- (void) finishedTranscode
{
	[self setStatus:[NSNumber numberWithInt:RSRecordingFinishedStatus]];
	[self setTranscodingImp:nil];
}

@dynamic mediaFile;
@dynamic status;
@dynamic schedule;
@synthesize transcodingImp;

@end


