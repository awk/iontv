//
//  RSOutlineView.m
//  recsched
//
//  Created by Andrew Kimpton on 9/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSOutlineView.h"


@implementation RSOutlineView

- (void) keyDown:(NSEvent *) theEvent
{
	NSString * tString;
	unsigned int stringLength;
	unsigned int i;
	unichar tChar;

	tString= [theEvent characters];

	stringLength=[tString length];

	for(i=0;i<stringLength;i++)
	{
		tChar=[tString characterAtIndex:i];

		if (tChar==0x7F)
		{
			NSMenuItem * tMenuItem;

			tMenuItem=[[NSMenuItem alloc] initWithTitle:@"" action:@selector(delete:) keyEquivalent:@""];

			if ([self validateUserInterfaceItem:tMenuItem]==YES)
			{
				[self delete:nil];
			}
			else
			{
				NSBeep();
			}

			return;
		}
	}

	[super keyDown:theEvent];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	if ([anItem action]==@selector(delete:))
	{
		if ([self numberOfSelectedRows]>0)
		{
			return [[self dataSource] validateUserInterfaceItem:anItem];
		}

		return NO;
	}

	return YES;
}

- (IBAction) delete:(id) sender
{
	if ([[self dataSource] respondsToSelector:@selector(deleteSelectedRowsOfOutlineView:)]==YES)
	{
		[[self dataSource] performSelector:@selector(deleteSelectedRowsOfOutlineView:) withObject:self];
	}
}

@end

