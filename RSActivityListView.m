//
//  RSActivityListView.m
//  recsched
//
//  Created by Andrew Kimpton on 9/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSActivityListView.h"


@implementation RSActivityListView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		mRowHeight = 35.0f;	// As reasonable a start as any
		mActivityViews = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void) dealloc
{
	[mActivityViews release];
	[super dealloc];
}

- (BOOL) isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)rect {
	NSRect rowRect = NSMakeRect(0, 0, [self frame].size.width, mRowHeight);
	NSArray *colorArray = [NSColor controlAlternatingRowBackgroundColors];
	
	// Start at the top of the view
	rowRect.origin.y = 0;
	int colorIndex = 0;
	while (rowRect.origin.y < [self bounds].size.height)
	{
		[[colorArray objectAtIndex:colorIndex] set];
		[NSBezierPath fillRect:rowRect];
		
		rowRect.origin.y += rowRect.size.height;
		colorIndex++;
		if (colorIndex > ([colorArray count]-1))
			colorIndex = 0;
	}
}

- (void)didAddSubview:(NSView *)subview;
{
	// Relocate the subview so that it's at the end of the list
	NSRect subviewFrame = [subview frame];
	subviewFrame.origin.y = [mActivityViews count] * [subview bounds].size.height;
	subviewFrame.size.width = [self frame].size.width;
	[subview setFrame:subviewFrame];
	
	[mActivityViews addObject:subview];
	[self setNeedsDisplay:YES];
}

- (void)willRemoveSubview:(NSView *)subview
{
	NSUInteger startingIndex = [mActivityViews indexOfObjectIdenticalTo:subview];
	if (startingIndex == NSNotFound)
		return;		// Odd the view isn't in the array of activity views !
	
	CGFloat heightOfViewBeingRemoved = [subview bounds].size.height;
	// Move all the subviews beneath this one up one
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.5f];
	startingIndex++;
	for ( ; startingIndex < [mActivityViews count]; startingIndex++)
	{
		NSRect subviewFrame = [[mActivityViews objectAtIndex:startingIndex] frame];
		subviewFrame.origin.y -= heightOfViewBeingRemoved;
		[[[mActivityViews objectAtIndex:startingIndex] animator] setFrame:subviewFrame];
	}
	[NSAnimationContext endGrouping];
	[mActivityViews removeObjectIdenticalTo:subview];
}

- (void)setRowHeight:(CGFloat)rowHeight
{
	if (rowHeight > 0)
	{
		mRowHeight = rowHeight;
		[self setNeedsDisplay:YES];
	}
}

@end
