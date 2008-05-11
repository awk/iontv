//
//  RSCalendarWeekView.h
//  recsched
//
//  Created by Andrew Kimpton on 5/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RSSeasonPassCalendarViewController;

@interface RSCalendarWeekView : NSControl {

  IBOutlet RSSeasonPassCalendarViewController *mCalendarController;
  
  NSMutableAttributedString *mDaysHeaderString;
  
  NSCalendarDate *mDrawingStartDate;
}

@end
