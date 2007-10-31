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
@class RSWishlistController;
@class ProgramSearchViewController;

extern NSString *RSSSchedulePBoardType;

@interface MainWindowController : NSWindowController {
  IBOutlet NSSegmentedControl *mGetScheduleButton;
  IBOutlet NSSplitView *mScheduleSplitView;
  IBOutlet NSSplitView *mTopLevelSplitView;
  IBOutlet NSOutlineView *mViewSelectionOutlineView;
  IBOutlet NSView *mDetailView;
  IBOutlet NSView *mScheduleContainerView;
  IBOutlet ScheduleView *mScheduleView;
  IBOutlet NSPanel *mPredicatePanel;
  IBOutlet RSWishlistController *mWishlistController;
  IBOutlet NSObjectController *mCurrentSchedule;
  IBOutlet NSObjectController *mCurrentStation;
  IBOutlet NSObjectController *mCurrentLineup;
  IBOutlet NSTreeController *mViewSelectionTreeController;
  
  IBOutlet NSArrayController *mRecordingsArrayController;
  
  IBOutlet NSArrayController *mLineupsArrayController;
  
  IBOutlet ProgramSearchViewController *mProgramSearchViewController;
  
  float mDetailViewMinHeight;
  NSArray *mDraggedNodes;		// Temporary copy of the nodes being dragged around
}

- (IBAction) getScheduleAction:(id)sender;
- (IBAction) cleanupAction:(id)sender;
- (IBAction) recordShow:(id)sender;
- (IBAction) recordSeasonPass:(id)sender;
- (IBAction) watchStation:(id)sender;
- (IBAction) createWishlist:(id)sender;

- (void) setGetScheduleButtonEnabled:(BOOL)enabled;

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule;
- (Z2ITSchedule*) currentSchedule;
@end
