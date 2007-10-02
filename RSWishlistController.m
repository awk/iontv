//
//  RSWishlistController.m
//  recsched
//
//  Created by Andrew Kimpton on 8/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSWishlistController.h"


@implementation RSWishlistController

#pragma mark Actions

- (IBAction) predicateSheetOKAction:(id) sender
{
	[NSApp stopModal];
}

- (IBAction) predicateSheetCancelAction:(id) sender
{
	[NSApp stopModal];
}

- (NSPredicate *) currentPredicate
{
	if (!mCurrentPredicate)
		mCurrentPredicate = [NSPredicate predicateWithFormat:@"name like 'Rick'"];
	return mCurrentPredicate;
}

- (void) setCurrentPredicate:(NSPredicate*)inPredicate
{
	if (inPredicate != mCurrentPredicate)
	{
		[mCurrentPredicate autorelease];
		mCurrentPredicate = [inPredicate retain];
	}
}

@end
