//
//  ScheduleHeaderView.h
//  recsched
//
//  Created by Andrew Kimpton on 1/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern const int kScheduleHeaderViewDefaultNumberOfCells;


@interface ScheduleHeaderView : NSView {

  NSMutableArray *mLabelCellArray;
  NSTextFieldCell *mStationCell;
  CFAbsoluteTime mStartTime;
}

+ (int) headerHeight;
- (void) updateCellLabels;
- (void) setStartTime:(CFAbsoluteTime)inStartTime;
@end
