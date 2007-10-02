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

#import "JKSeparatorCell.h"


@implementation JKSeparatorCell

- (void) drawWithFrame:(NSRect)frame inView:(NSView *)controlView {
	float lineWidth = frame.size.width * 0.85;
	float lineX = (frame.size.width - lineWidth) / 2;
	float lineY = (frame.size.height - 2) / 2;
	lineY += 0.5;

	[[NSColor colorWithDeviceRed:0.820 green:0.847 blue:0.878 alpha:1.0] set];
	NSRectFill(NSMakeRect(frame.origin.x + lineX, frame.origin.y + lineY, lineWidth, 1));
	
	[[NSColor colorWithDeviceRed:0.976 green:1.0 blue:1.0 alpha:1.0] set];
	NSRectFill(NSMakeRect(frame.origin.x + lineX, frame.origin.y + lineY + 1, lineWidth, 1));
}

- (void) setPlaceholderString:(NSString *)placeholder {
	// do nothing, method is just here in case you bind to a string
	// value, like [NSObject description]
}
@end
