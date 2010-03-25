//  Copyright (c) 2007, Andrew Kimpton
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "RSActivityViewController.h"
#import "recsched_AppDelegate.h"
#import "RecSchedProtocol.h"
#import "RSActivityListView.h"

@interface RSActivityUnitTestInfo : NSObject {
 @public
  size_t activityToken;
  int maxProgress;
  int currentProgress;
}

@property size_t activityToken;
@property int maxProgress;
@property int currentProgress;
@end

@implementation RSActivityUnitTestInfo
@synthesize maxProgress;
@synthesize currentProgress;
@synthesize activityToken;
@end

@implementation RSActivityWindowController
@synthesize activityViewController;
@end

@implementation RSActivityViewController

- (void)unitTest {
  const double kUnitTestProgressMaxValue = 15.0;
  int i=0;
  for (i = 1; i <= 4; i++) {
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

- (void)unitTestIncrementActivity:(NSTimer*) aTimer {
  RSActivityUnitTestInfo *testInfo = [aTimer userInfo];

  [self setActivity:testInfo->activityToken incrementBy:1.0];
  if ((testInfo->currentProgress++) > testInfo->maxProgress) {
    [aTimer invalidate];
    [self endActivity:testInfo->activityToken];
    [testInfo release];
  }
}

- (void)awakeFromNib {
  // Register ourselves for the display/feedback methods called by the server
  activityConnection = [[NSConnection alloc] init];
  [activityConnection setRootObject:self];
  if ([activityConnection registerName:kRecUIActivityConnectionName] == NO) {
    /* Handle error. */
    NSLog(@"Error registering connection");
  } else {
    [[[NSApp delegate] recServer] activityDisplayAvailable];
  }
}

- (void)destroyActivityConnection {
  [[[NSApp delegate] recServer] activityDisplayUnavailable];
  [activityConnection registerName:nil];
  [activityConnection invalidate];
  [activityConnection release];
  activityConnection = nil;
}

- (void)dealloc {
  [[[NSApp delegate] recServer] activityDisplayUnavailable];
  [self destroyActivityConnection];
  [super dealloc];
}

- (size_t)createActivity {
  // Create the new Aggregate view controller
  RSActivityAggregateViewController *anAggregateViewController = [[RSActivityAggregateViewController alloc] init];
  if (![NSBundle loadNibNamed:@"ActivityAggregateView" owner:anAggregateViewController]) {
    NSLog(@"Error loading aggregate activity view NIB");
    return 0;
  }

  // Add the aggregate view to the list view
  [mListView addSubview:[anAggregateViewController aggregateView]];

  return (size_t)anAggregateViewController;
}

- (void)endActivity:(size_t)activityToken {
  [(RSActivityAggregateViewController*) activityToken release];
}

- (size_t)setActivity:(size_t)activityToken infoString:(NSString *)inInfoString {
  [(RSActivityAggregateViewController*) activityToken setInfoString:inInfoString];
  return activityToken;
}

- (size_t)setActivity:(size_t)activityToken progressIndeterminate:(BOOL)isIndeterminate {
  [(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:isIndeterminate];
  return activityToken;
}

- (size_t)setActivity:(size_t)activityToken progressMaxValue:(double)inTotal {
  [(RSActivityAggregateViewController*) activityToken setProgressMaxValue:inTotal];
  return activityToken;
}

- (size_t)setActivity:(size_t)activityToken progressDoubleValue:(double)inValue {
  [(RSActivityAggregateViewController*) activityToken setProgressDoubleValue:inValue];
  return activityToken;
}

- (size_t)setActivity:(size_t)activityToken incrementBy:(double)delta {
  [(RSActivityAggregateViewController*) activityToken incrementProgressBy:delta];
  return activityToken;
}

- (size_t)shouldCancelActivity:(size_t)activityToken cancel:(BOOL*)cancel {
  if (cancel) {
    *cancel = [(RSActivityAggregateViewController*) activityToken shouldCancel];
  }
  return activityToken;
}

@synthesize activityConnection;

@end

@implementation RSActivityAggregateViewController

- (void)dealloc {
  [mActivityAggregateView removeFromSuperview];

  [mActivityAggregateView release];
  [super dealloc];
}

- (NSView *)aggregateView {
  return mActivityAggregateView;
}

- (void)setInfoString:(NSString *)inInfoString {
  [mInfoField setStringValue:inInfoString];
}

- (void)setProgressIndeterminate:(BOOL)isIndeterminate {
  [mProgressIndicator setIndeterminate:isIndeterminate];
  if (isIndeterminate) {
    [mProgressIndicator startAnimation:self];
  } else {
    [mProgressIndicator stopAnimation:self];
  }
}

- (void)setProgressMaxValue:(double)inTotal {
  [mProgressIndicator setMaxValue:inTotal];
  [mProgressIndicator setDoubleValue:0.0];
}

- (void)setProgressDoubleValue:(double)inValue {
  [mProgressIndicator setDoubleValue:inValue];
}

- (void)incrementProgressBy:(double)delta {
  [mProgressIndicator incrementBy:delta];
}

- (BOOL)shouldCancel {
  return mCancelClicked;
}

- (IBAction)cancelButtonAction:(id)sender {
  mCancelClicked = YES;
}

@end