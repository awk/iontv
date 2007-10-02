//
//  ScheduleView.h
//  recsched
//
//  Created by Andrew Kimpton on 1/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScheduleHeaderView;
@class ScheduleStationColumnView;
@class ScheduleGridView;

@interface ScheduleView : NSView {
  IBOutlet ScheduleHeaderView *mHeaderView;
  IBOutlet ScheduleStationColumnView *mStationColumnView;
  IBOutlet ScheduleGridView *mGridView;
  IBOutlet NSScroller *mStationsScroller;

  IBOutlet NSArrayController *mLineupArrayController;
  NSArray *mSortedStationsArray;
  CFAbsoluteTime mStartTime;
}

- (void) goBackwards;
- (void) goForward;
- (float) visibleTimeSpan;
- (float) timePerLineIncrement;
- (void) updateStationsScroller;
- (void) sortStationsArray;

@end
