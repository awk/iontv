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
@class Z2ITSchedule;
@class Z2ITStation;

@interface ScheduleView : NSView {
  IBOutlet ScheduleHeaderView *mHeaderView;
  IBOutlet ScheduleStationColumnView *mStationColumnView;
  IBOutlet ScheduleGridView *mGridView;
  IBOutlet NSScroller *mStationsScroller;

  IBOutlet NSObjectController *mCurrentLineup;
  IBOutlet NSObjectController *mCurrentSchedule;
  NSArray *mSortedStationsArray;
  CFAbsoluteTime mStartTime;
  IBOutlet id delegate;       // Note no 'm' here so that it 'looks like' all the other delegate mechanisms in IB.
}

- (void) setStartTime:(CFAbsoluteTime) inStartTime;
- (void) scrollToStation:(Z2ITStation*) inStation;
- (float) visibleTimeSpan;
- (float) timePerLineIncrement;
- (void) updateStationsScroller;
- (void) sortStationsArray;
- (id) delegate;
- (void) setDelegate:(id)inDelegate;

@property (setter=setStartTime:) CFAbsoluteTime mStartTime;
@end
