//  Copyright (c) 2007, Andrew Kimpton
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
