//
//  ActivityViewController.h
//  recsched
//
//  Created by Andrew Kimpton on 9/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSActivityDisplayProtocol.h"

@class RSActivityAggregateViewController;
@class RSActivityListView;

@interface RSActivityViewController : NSObject <RSActivityDisplay> {
  IBOutlet RSActivityAggregateViewController *mAggregateViewControllerTemplate;
  IBOutlet NSView *mAggregateViewTemplate;
  IBOutlet RSActivityListView *mListView;
  
//  NSMutableDictionary *mActivitiesDictionary;
}

@end

@interface RSActivityAggregateViewController : NSObject
{
  IBOutlet NSProgressIndicator *mProgressIndicator;
  IBOutlet NSTextField *mInfoField;
  IBOutlet NSView *mActivityAggregateView;
  
  NSDictionary *mActivityInfoDictionary;
}

- (NSView*) aggregateView;

- (void) setInfoString:(NSString*)inInfoString;
- (void) setProgressIndeterminate:(BOOL)isIndeterminate;
- (void) setProgressMaxValue:(double)inTotal;
- (void) setProgressDoubleValue:(double)inValue;
- (void) incrementProgressBy:(double)delta;

- (IBAction) cancelButtonAction:(id)sender;
@end
