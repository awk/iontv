/* 

Copyright (c) 2006 Joris Kluivers

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the 
Software, and to permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

More information:
http://joris.kluivers.nl

*/

#import "JKImageTextCell.h"


@implementation JKImageTextCell
- (id) initTextCell:(NSString *)txt {
	self = [super initTextCell:txt];
	
	if (self) {
		[self setImage:nil];
		textColor = [[NSColor blackColor] retain];
		[self setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	
	return self;
}

- (id) initImageCell:(NSImage *)cellImg {
	self = [self initTextCell:@"Default text"];
	
	if (self) {
		[self setImage:cellImg];
	}
	
	return self;
}

#pragma mark -
#pragma mark Accessors

- (NSImage *) image {
	return image;
}

- (void) setImage:(NSImage *)newImage {
	[newImage retain];
	[image release];
	image = newImage;
}

- (void) setTextColor:(NSColor *)txtColor {
	[txtColor retain];
	[textColor release];
	textColor = txtColor;
}

- (NSColor *) textColor {
	return textColor;
}

#pragma mark -
#pragma mark Drawing

- (NSRect) titleRectForBounds:(NSRect)bounds {
	NSRect imageRect = [self imageRectForBounds:bounds];
	NSSize titleSize = [[self title] sizeWithAttributes:nil];
	NSRect titleRect = bounds;
	
	titleRect.origin.x += 5;
	if ([self image] != nil) {
		titleRect.origin.x += imageRect.origin.x + imageRect.size.width;
		titleRect.size.width -= imageRect.size.width + 5;
	}
	titleRect.origin.y = titleRect.origin.y + (bounds.size.height - titleSize.height) / 2;
	titleRect.size.width -= 5; // padding right
	
	return titleRect;
}

- (NSRect) imageRectForBounds:(NSRect)bounds {
	return NSMakeRect(bounds.origin.x + 5, bounds.origin.y + 1, bounds.size.height - 2, bounds.size.height - 2);
}

- (void) drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
	if ([self image] != nil) {
		[[self image] setFlipped:YES];
		[[self image] setSize:[self imageRectForBounds:frame].size];
		[[self image] setScalesWhenResized:YES];

		[[self image] drawInRect:[self imageRectForBounds:frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	
	
	/*[[self textColor] set];
	[[self title] drawInRect:[self titleRectForBounds:frame] withAttributes:[NSMutableDictionary dictionaryWithObjectsAndKeys:[self textColor], NSForegroundColorAttributeName, nil]];
	*/
	[super drawWithFrame:[self titleRectForBounds:frame] inView:controlView];
}
@end
