//
//  MainWindowController.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITSchedule;
@class ScheduleView;

@interface MainWindowController : NSWindowController {
  IBOutlet NSButton *mGetScheduleButton;
  IBOutlet NSProgressIndicator *mParsingProgressIndicator;
  IBOutlet NSTextField *mParsingProgressInfoField;
  IBOutlet NSSplitView *mSplitView;
  IBOutlet NSView *mDetailView;
  IBOutlet NSView *mScheduleContainerView;
  IBOutlet ScheduleView *mScheduleView;
  IBOutlet NSObjectController *mCurrentSchedule;
  float mDetailViewMinHeight;
}

- (IBAction) getScheduleAction:(id)sender;
- (IBAction) cleanupAction:(id)sender;

- (void) setParsingInfoString:(NSString*)inInfoString;
- (void) setParsingProgressMaxValue:(double)inTotal;
- (void) setParsingProgressDoubleValue:(double)inValue;

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule;
@end
