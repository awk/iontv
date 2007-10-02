//
//  ScheduleDetailsPopupView.h
//  recsched
//
//  Created by Andrew Kimpton on 9/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern const float kScheduleDetailsPopupWidthPadding;
extern const float kScheduleDetailsPopupHeightPadding;

@interface ScheduleDetailsPopupView : NSView {

	IBOutlet NSObjectController *mCurrentSchedule;
	
	NSImage *mCloseBoxImage;
	NSImage *mCloseBoxPressedImage;
	BOOL mMouseInCloseBox;
	BOOL mTrackingCloseBox;
}

@end
