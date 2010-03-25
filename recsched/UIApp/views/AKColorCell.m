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

#import "AKColorCell.h"


@implementation AKColorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSRect square = NSInsetRect (cellFrame, 0.5, 0.5);  // move in half a point to put the lines on even point boundries

  // use the smallest size to square off the box & center the box
  if (square.size.height < square.size.width) {
    square.size.width = square.size.height;
    square.origin.x = square.origin.x + (cellFrame.size.width - square.size.width) / 2.0;
  } else {
    square.size.height = square.size.width;
    square.origin.y = square.origin.y + (cellFrame.size.height - square.size.height) / 2.0;
  }

  // draw a black border around the color
  [[NSColor blackColor] set];
  [NSBezierPath strokeRect: square];

  // inset the color 2 points from the border and draw it
  NSColor *myColor = nil;
  if ([self objectValue]) {
    myColor = [NSUnarchiver unarchiveObjectWithData:[self objectValue]];
  }
  if (myColor) {
    [myColor drawSwatchInRect: NSInsetRect (square, 2.0, 2.0)];
  }
}

- (void)setPlaceholderString:(NSString *)string {
  // No placeholder details
}

@end
