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
#import "RSActivityListView.h"

@interface RSActivityUnitTestInfo : NSObject
{
	@public
	size_t activityToken;
	int maxProgress;
	int currentProgress;
}

@end

@implementation RSActivityUnitTestInfo
@end

@implementation RSActivityViewController

- (void) unitTest
{
	const double kUnitTestProgressMaxValue = 15.0;
	int i=0;
	for (i = 1; i <= 4; i++)
	{
		// Create an activity
		size_t testActivityToken = [self createActivity];
		[self setActivity:testActivityToken infoString:[NSString stringWithFormat:@"Activity %d", i]];
		[self setActivity:testActivityToken progressMaxValue:kUnitTestProgressMaxValue*i];
		
		RSActivityUnitTestInfo *testInfo = [[RSActivityUnitTestInfo alloc] init];
		testInfo->activityToken = testActivityToken;
		testInfo->maxProgress = kUnitTestProgressMaxValue*i;
		testInfo->currentProgress = 0;
		[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(unitTestIncrementActivity:) userInfo:testInfo repeats:YES];
	}
}

- (void) unitTestIncrementActivity:(NSTimer*) aTimer
{
	RSActivityUnitTestInfo *testInfo = [aTimer userInfo];
	
	[self setActivity:testInfo->activityToken incrementBy:1.0];
	if ((testInfo->currentProgress++) > testInfo->maxProgress)
	{
		[aTimer invalidate];
		[self endActivity:testInfo->activityToken];
		[testInfo release];
	}
}

- (void) awakeFromNib
{
	// Register ourselves for the display/feedback methods called by the server
    NSConnection *theConnection;

    theConnection = [NSConnection defaultConnection];
    [theConnection setRootObject:self];
    if ([theConnection registerName:kRecUIActivityConnectionName] == NO) 
    {
		theConnection = [[NSConnection alloc] init];
		[theConnection setRootObject:self];
		if ([theConnection registerName:kRecUIActivityConnectionName] == NO) 
		{
            /* Handle error. */
            NSLog(@"Error registering connection");
		}
		else
			[[[NSApp delegate] recServer] activityDisplayAvailable];
    }
	else
		[[[NSApp delegate] recServer] activityDisplayAvailable];
}

- (void) dealloc
{
	[[[NSApp delegate] recServer] activityDisplayUnavailable];
	
	[super dealloc];
}

- (size_t) createActivity
{
	// Create the new Aggregate view controller
	RSActivityAggregateViewController *anAggregateViewController = [[RSActivityAggregateViewController alloc] init];
	if (![NSBundle loadNibNamed:@"ActivityAggregateView" owner:anAggregateViewController])
	{
		NSLog(@"Error loading aggregate activity view NIB");
		return 0;
	}
	
	// Add the aggregate view to the list view
	[mListView addSubview:[anAggregateViewController aggregateView]];
	
	return (size_t)anAggregateViewController;
}

- (void) endActivity:(size_t)activityToken
{
	[(RSActivityAggregateViewController*) activityToken release];
}

- (void) setActivity:(size_t)activityToken infoString:(NSString*)inInfoString
{
	[(RSActivityAggregateViewController*) activityToken setInfoString:inInfoString];
}

- (void) setActivity:(size_t)activityToken progressIndeterminate:(BOOL)isIndeterminate
{
	[(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:isIndeterminate];
}

- (void) setActivity:(size_t)activityToken progressMaxValue:(double)inTotal
{
	[(RSActivityAggregateViewController*) activityToken setProgressMaxValue:inTotal];
}

- (void) setActivity:(size_t)activityToken incrementBy:(double)delta
{
	[(RSActivityAggregateViewController*) activityToken incrementProgressBy:delta];
}

@end

@implementation RSActivityAggregateViewController

- (void) dealloc
{
	[mActivityAggregateView removeFromSuperview];
	
	[mActivityAggregateView release];
	[super dealloc];
}

- (NSView*) aggregateView
{
	return mActivityAggregateView;
}

- (void) setInfoString:(NSString*)inInfoString
{
	[mInfoField setStringValue:inInfoString];
}

- (void) setProgressIndeterminate:(BOOL)isIndeterminate
{
	[mProgressIndicator setIndeterminate:isIndeterminate];
	if (isIndeterminate)
		[mProgressIndicator startAnimation:self];
	else
		[mProgressIndicator stopAnimation:self];
}

- (void) setProgressMaxValue:(double)inTotal
{
	[mProgressIndicator setMaxValue:inTotal];
	[mProgressIndicator setDoubleValue:0.0];
}

- (void) setProgressDoubleValue:(double)inValue
{
	[mProgressIndicator setDoubleValue:inValue];
}

- (void) incrementProgressBy:(double)delta
{
	[mProgressIndicator incrementBy:delta];
}

- (IBAction) cancelButtonAction:(id)sender
{
	NSLog(@"Cancel Button");
}

@end