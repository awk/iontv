//
//  ScheduleStationColumnView.h
//  recsched
//
//  Created by Andrew Kimpton on 1/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern const int kScheduleStationColumnViewCellHeight;

@class Z2ITLineup;

@interface ScheduleStationColumnView : NSControl {
  NSMutableArray *mStationLabelCellArray;
  NSArray *mSortedStationsArray;
  Z2ITLineup *mCurrentLineup;
  unsigned mStartStationIndex;
  id delegate;
}

+ (int) columnWidth;
- (void) updateCellLabels;
- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
- (unsigned) numberStationsDisplayed;
- (void) setStartStationIndex:(unsigned)inIndex;
- (id) delegate;
- (void) setDelegate:(id)inDelegate;
@property (setter=setStartStationIndex:) unsigned mStartStationIndex;
@end
