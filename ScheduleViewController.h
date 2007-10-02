//
//  ScheduleViewController.h
//  recsched
//
//  Created by Andrew Kimpton on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ScheduleView;

@interface ScheduleViewController : NSObject {
    IBOutlet ScheduleView *mScheduleView;
    IBOutlet NSSegmentedControl *mScheduleTimeSegmentedControl;
    IBOutlet NSObjectController *mCurrentSchedule;
    IBOutlet NSObjectController *mCurrentLineup;
    CFAbsoluteTime mStartTime;
}

- (void) updateSegmentDisplay;
- (void) updateSegmentMenus;
- (CFAbsoluteTime) startTime;
- (void) setStartTime:(CFAbsoluteTime)inStartTime;
- (IBAction) scheduleControlClicked:(id)sender;
@end
