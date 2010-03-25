//
//  RSSeasonPassCalendarCell.h
//  recsched
//
//  Created by Andrew Kimpton on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSSeasonPassCalendarCell : NSTextFieldCell {
  NSArray *scheduleList;
  NSMutableAttributedString *mEventString;
}

@property(retain) NSArray* scheduleList;

@end
