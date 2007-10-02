//
//  ScheduleViewController.h
//  recsched
//
//  Created by Andrew Kimpton on 1/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScheduleHeaderView;
@class ScheduleStationColumnView;

@interface ScheduleViewController : NSObject {
  IBOutlet ScheduleHeaderView *mHeaderView;
  IBOutlet ScheduleStationColumnView *mStationColumnView;
  IBOutlet NSScroller *mTimeScroller;
  IBOutlet NSScroller *mStationsScroller;
  IBOutlet NSArrayController *mStationArrayController;
  IBOutlet NSArrayController *mLineupArrayController;
  NSArray *mSortedStationsArray;
  CFAbsoluteTime mStartTime;
}

- (IBAction) scrollerChanged:(NSScroller*)inScroller;

@end
