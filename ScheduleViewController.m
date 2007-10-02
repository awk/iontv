//
//  ScheduleViewController.m
//  recsched
//
//  Created by Andrew Kimpton on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleViewController.h"
#import "ScheduleView.h"

enum { kPreviousTimeSegment = 0, kDaySegment, kHourSegment, kNextTimeSegment };

@implementation ScheduleViewController

- (IBAction) scheduleControlClicked:(id)sender
{
  int clickedSegment = [sender selectedSegment];
  switch (clickedSegment)
  {
    case kPreviousTimeSegment:
      [mScheduleView goBackwards];
      break;
    case kNextTimeSegment:
      [mScheduleView goForward];
      break;
    default:
      break;
  }
}

@end
