//
//  MainWindowController.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XMLParsingProgressDisplayProtocol.h"

@class Z2ITSchedule;
@class ScheduleView;
@class RSWishlistController;

@interface MainWindowController : NSWindowController <XMLParsingProgressDisplay> {
  IBOutlet NSSegmentedControl *mGetScheduleButton;
  IBOutlet NSProgressIndicator *mParsingProgressIndicator;
  IBOutlet NSTextField *mParsingProgressInfoField;
  IBOutlet NSSplitView *mScheduleSplitView;
  IBOutlet NSSplitView *mTopLevelSplitView;
  IBOutlet NSOutlineView *mViewSelectionOutlineView;
  IBOutlet NSView *mDetailView;
  IBOutlet NSView *mScheduleContainerView;
  IBOutlet NSView *mProgramSearchView;
  IBOutlet ScheduleView *mScheduleView;
  IBOutlet NSPanel *mPredicatePanel;
  IBOutlet RSWishlistController *mWishlistController;
  IBOutlet NSObjectController *mCurrentSchedule;
  IBOutlet NSObjectController *mCurrentStation;
  IBOutlet NSObjectController *mCurrentLineup;
  IBOutlet NSTreeController *mViewSelectionTreeController;
  
  float mDetailViewMinHeight;
}

- (IBAction) getScheduleAction:(id)sender;
- (IBAction) cleanupAction:(id)sender;
- (IBAction) recordShow:(id)sender;
- (IBAction) recordSeasonPass:(id)sender;
- (IBAction) watchStation:(id)sender;
- (IBAction) createWishlist:(id)sender;

- (void) showViewForTableSelection:(int) selectedRow;

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule;
- (Z2ITSchedule*) currentSchedule;
@end
