//
//  ScheduleGridView.h
//  recsched
//
//  Created by Andrew Kimpton on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITLineup;

@interface ScheduleGridView : NSControl {
  NSMutableArray *mStationsInViewArray;
//  NSMutableArray *mCellsInViewArray;
  NSArray *mSortedStationsArray;
  Z2ITLineup *mCurrentLineup;
  unsigned mStartStationIndex;
  CFAbsoluteTime mStartTime;
  float mVisibleTimeSpan;
  NSCell *mSelectedCell;
}

- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
- (void) setStartStationIndex:(unsigned)inIndex;
- (void) setStartTime:(CFAbsoluteTime)inStartTime;
- (void) setVisibleTimeSpan:(float)inTimeSpan;
@end
