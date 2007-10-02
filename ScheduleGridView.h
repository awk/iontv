//
//  ScheduleGridView.h
//  recsched
//
//  Created by Andrew Kimpton on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITLineup;
@class Z2ITSchedule;

@interface ScheduleGridView : NSControl {
  NSMutableArray *mStationsInViewArray;
  NSArray *mSortedStationsArray;
  Z2ITLineup *mCurrentLineup;
  unsigned mStartStationIndex;
  CFAbsoluteTime mStartTime;
  float mVisibleTimeSpan;
  NSCell *mSelectedCell;
  Z2ITSchedule *mSelectedSchedule;
  id  delegate;
	NSTrackingArea *mScheduleCellTrackingArea;
	NSTimer *mScheduleCellPopupTimer;
}

- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
- (void) setStartStationIndex:(unsigned)inIndex;
- (void) setStartTime:(CFAbsoluteTime)inStartTime;
- (void) setVisibleTimeSpan:(float)inTimeSpan;
- (void) setSelectedSchedule:(Z2ITSchedule*)inSchedule;
- (id) delegate;
- (void) setDelegate:(id)inDelegate;
@end
