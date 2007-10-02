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
}

- (IBAction) scheduleControlClicked:(id)sender;
@end
