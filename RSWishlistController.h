//
//  RSWishlistController.h
//  recsched
//
//  Created by Andrew Kimpton on 8/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSWishlistController : NSObject {
	IBOutlet NSPanel* mPredicatePanel;
	NSPredicate *mCurrentPredicate;
}

- (IBAction) predicateSheetOKAction:(id) sender;
- (IBAction) predicateSheetCancelAction:(id) sender;

@end
