//
//  RSActivityListView.h
//  recsched
//
//  Created by Andrew Kimpton on 9/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSActivityListView : NSView {
	CGFloat mRowHeight;
	
	NSMutableArray *mActivityViews;
}

@end
