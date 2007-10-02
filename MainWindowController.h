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
  IBOutlet NSSplitView *mScheduleSplitView;
  IBOutlet NSSplitView *mTopLevelSplitView;
  IBOutlet NSTableView *mViewSelectionTableView;
  IBOutlet NSView *mDetailView;
  IBOutlet NSView *mScheduleContainerView;
  IBOutlet NSView *mProgramSearchView;
  IBOutlet ScheduleView *mScheduleView;
  IBOutlet NSObjectController *mCurrentSchedule;
  IBOutlet NSArrayController *mViewSelectionArrayController;
  
  // Cells used by the Source View selector 'table'
  NSCell *mSeparatorCell;
  NSCell *mDefaultCell;

  float mDetailViewMinHeight;
  id mRecServer;
}

- (IBAction) getScheduleAction:(id)sender;
- (IBAction) cleanupAction:(id)sender;
- (IBAction) recordShow:(id)sender;
- (IBAction) recordSeasonPass:(id)sender;
- (IBAction) quitServer:(id)sender;

- (void) setParsingInfoString:(NSString*)inInfoString;
- (void) setParsingProgressMaxValue:(double)inTotal;
- (void) setParsingProgressDoubleValue:(double)inValue;

- (void) showViewForTableSelection:(int) selectedRow;

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule;
- (Z2ITSchedule*) currentSchedule;
@end
