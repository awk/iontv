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

#import <Cocoa/Cocoa.h>
#import "RSActivityDisplayProtocol.h"

@class RSActivityAggregateViewController;
@class RSActivityListView;
@class RSActivityViewController;

@interface RSActivityWindowController : NSWindowController {
  IBOutlet RSActivityViewController *activityViewController;
}

@property (readonly) RSActivityViewController *activityViewController;

@end

@interface RSActivityViewController : NSObject <RSActivityDisplay> {
  IBOutlet RSActivityAggregateViewController *mAggregateViewControllerTemplate;
  IBOutlet NSView *mAggregateViewTemplate;
  IBOutlet RSActivityListView *mListView;
  
//  NSMutableDictionary *mActivitiesDictionary;
    NSConnection *activityConnection;
}

@property (readonly) NSConnection *activityConnection;

@end

@interface RSActivityAggregateViewController : NSObject
{
  IBOutlet NSProgressIndicator *mProgressIndicator;
  IBOutlet NSTextField *mInfoField;
  IBOutlet NSView *mActivityAggregateView;
  
  NSDictionary *mActivityInfoDictionary;
  BOOL mCancelClicked;
}

- (NSView*) aggregateView;

- (void) setInfoString:(NSString*)inInfoString;
- (void) setProgressIndeterminate:(BOOL)isIndeterminate;
- (void) setProgressMaxValue:(double)inTotal;
- (void) setProgressDoubleValue:(double)inValue;
- (void) incrementProgressBy:(double)delta;
- (BOOL) shouldCancel;

- (IBAction) cancelButtonAction:(id)sender;
@end
