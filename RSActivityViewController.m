//
//  ActivityViewController.m
//  recsched
//
//  Created by Andrew Kimpton on 9/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSActivityViewController.h"
#import "recsched_AppDelegate.h"
#import "RecSchedProtocol.h"

@implementation RSActivityViewController

- (void) awakeFromNib
{
	// Register ourselves for the display/feedback methods called by the server
    NSConnection *theConnection;

    theConnection = [NSConnection defaultConnection];
    [theConnection setRootObject:self];
    if ([theConnection registerName:kRecUIActivityConnectionName] == NO) 
    {
            /* Handle error. */
            NSLog(@"Error registering connection");
    }
	else
		[[[NSApp delegate] recServer] activityDisplayAvailable];
	
}

- (void) dealloc
{
	[[[NSApp delegate] recServer] activityDisplayUnavailable];
	
	[super dealloc];
}

- (void) beginActivity
{
  [mParsingProgressIndicator setHidden:NO];
  [mParsingProgressIndicator setIndeterminate:NO];
  [mParsingProgressInfoField setHidden:NO];
}

- (void) endActivity
{
  [mParsingProgressIndicator stopAnimation:self];
  [mParsingProgressIndicator setHidden:YES];
  [mParsingProgressIndicator setIndeterminate:NO];
  [mParsingProgressInfoField setHidden:YES];
}

- (void) setActivityInfoString:(NSString*)inInfoString
{
  [mParsingProgressInfoField setStringValue:inInfoString];
  [mParsingProgressInfoField setHidden:NO];
}

- (void) setActivityProgressIndeterminate:(BOOL)isIndeterminate
{
  [mParsingProgressIndicator setHidden:NO];
  [mParsingProgressIndicator setIndeterminate:isIndeterminate];
	if (isIndeterminate == YES)
		[mParsingProgressIndicator startAnimation:self];
	else
		[mParsingProgressIndicator stopAnimation:self];
}

- (void) setActivityProgressMaxValue:(double)inTotal
{
  [mParsingProgressIndicator setMaxValue:inTotal];
  [mParsingProgressIndicator setHidden:NO];
}

- (void) setActivityProgressDoubleValue:(double)inValue
{
  [mParsingProgressIndicator setDoubleValue:inValue];
}

@end
