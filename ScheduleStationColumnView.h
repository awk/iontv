//
//  ScheduleStationColumnView.h
//  recsched
//
//  Created by Andrew Kimpton on 1/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITLineup;

const int kScheduleStationColumnViewWidth = 95;

@interface ScheduleStationColumnView : NSView {
  NSMutableArray *mStationLabelCellArray;
  NSArray *mSortedStationsArray;
  Z2ITLineup *mCurrentLineup;
  unsigned mStartStationIndex;
}

- (void) updateCellLabels;
- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
- (unsigned) numberStationsDisplayed;
- (void) setStartStationIndex:(unsigned)inIndex;
@end
