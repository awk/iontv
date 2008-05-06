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

#import "RSCalendarMonthView.h"
#import "RSSeasonPassCalendarViewController.h"

@interface RSCalendarMonthView (Private)

- (void) updateMonthHeaderString;

@end

@implementation RSCalendarMonthView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self setPostsFrameChangedNotifications:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChangeNotification:) name:NSViewFrameDidChangeNotification object:self];
    }
    
    NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:11.0];
    NSColor *headerTextColor = [NSColor colorWithDeviceHue:0 saturation:0 brightness:98.0/255.0 alpha:1.0];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, 
                                     headerTextColor, NSForegroundColorAttributeName,
                                     nil];
    NSMutableString *daysHeaderText = [NSMutableString string];
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    NSArray *daysOfWeek = [dateFormatter weekdaySymbols];
    int i = 0;
    for (i = 0; i < 7; i++)
    {
      [daysHeaderText appendFormat:@"\t%@", [daysOfWeek objectAtIndex:i]];
    }
    daysHeaderString = [[NSMutableAttributedString alloc] initWithString:daysHeaderText attributes:attrsDictionary];

    return self;
}

- (void) awakeFromNib
{
  [mCalendarController addObserver:self forKeyPath:@"displayStartDate" options:0 context:nil];
  [mCalendarController addObserver:self forKeyPath:@"selectedDate" options:0 context:nil];
}

- (void)drawRect:(NSRect)rect {
    // Fill with white background
    [[NSColor whiteColor] setFill];
    [NSBezierPath fillRect:rect];
    
    NSRect headerFrame = [self frame];
    headerFrame.size.height = 50;
    headerFrame.origin.y = NSMaxY([self frame]) - headerFrame.size.height;
  
    // Draw the dividing line across the top
    [[NSColor colorWithDeviceHue:0 saturation:0 brightness:204.0/255.0 alpha:1.0] setStroke];
    NSPoint leftEdge = headerFrame.origin;
    NSPoint rightEdge = NSMakePoint(NSMaxX(headerFrame), headerFrame.origin.y);
    leftEdge.y += 0.5;
    rightEdge.y += 0.5;
    NSBezierPath *aPath = [[[NSBezierPath alloc] init] autorelease];
    [aPath moveToPoint:leftEdge];
    [aPath lineToPoint:rightEdge];
    [aPath setLineWidth:1.0];
    [aPath stroke];
    
    // Draw the column boundaries
    [aPath removeAllPoints];
    int i = 0;
    for (i = 1; i < 7; i++)
    {
      NSPoint top, bottom;
      top.y = headerFrame.origin.y;
      bottom.y = NSMinY([self frame]);
      top.x = bottom.x = floor(i * ([self frame].size.width / 7.0)) + 0.5;
      [aPath moveToPoint:bottom];
      [aPath lineToPoint:top];
    }
    [aPath setLineWidth:1.0];
    [aPath stroke];
    
    // Draw the row boundaries
    [aPath removeAllPoints];
    for (i = 1; i < 5; i++)
    {
      NSPoint left, right;
      left.x = NSMinX([self frame]);
      right.x = NSMaxX([self frame]);
      left.y = right.y = floor((i * ([self frame].size.height - 50.0) / 5.0)) + 0.5;
      [aPath moveToPoint:left];
      [aPath lineToPoint:right];
    }
    [aPath setLineWidth:1.0];
    [aPath stroke];
    
    // Draw the Text across the top
    NSRect textFrame = headerFrame;
    NSSize textSize = [monthHeaderString size];
    textFrame.size.height = textSize.height;
    textFrame.origin.y += 20;
    [monthHeaderString drawInRect:textFrame];
    
    textFrame = headerFrame;
    textSize = [daysHeaderString size];
    textFrame.size.height = textSize.height;
    textFrame.origin.y += 3;
    [daysHeaderString drawInRect:textFrame];
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
  if ((object == mCalendarController) && ([keyPath isEqual:@"displayStartDate"]))
  {
    [self updateMonthHeaderString];
  }
  if ((object == mCalendarController) && ([keyPath isEqual:@"selectedDate"]))
  {
    NSLog(@"selectedDate changed => %@", mCalendarController.selectedDate);
    [self setNeedsDisplay:YES];
  }
}


@end

@implementation RSCalendarMonthView (Private)

- (void) frameDidChangeNotification:(NSNotification*)aNotification
{
    // Create the tab stop list for the days of the week headings
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    NSMutableArray *tabStopArray = [NSMutableArray arrayWithCapacity:7];

    int i = 0;
    for (i = 0; i < 7; i++)
    {
      NSPoint tabPoint;
      tabPoint.x = (([self frame].size.width/7.0) * i) + (0.5 * [self frame].size.width / 7.0);
      NSTextTab *aTab = [[[NSTextTab alloc] initWithType:NSCenterTabStopType location:tabPoint.x] autorelease];
      [tabStopArray addObject:aTab];
    }

    [paragraphStyle setTabStops:tabStopArray];
    NSRange entireStringRange = NSMakeRange(0, [daysHeaderString length]);
    [daysHeaderString beginEditing];
    [daysHeaderString removeAttribute:NSParagraphStyleAttributeName range:entireStringRange];
    [daysHeaderString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:entireStringRange];
    [daysHeaderString endEditing];
}

- (void) updateMonthHeaderString
{
    NSFont *font = [NSFont fontWithName:@"Helvetica Neue Bold" size:18.0];
    NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [paragraphStyle setAlignment:NSCenterTextAlignment];
    NSColor *headerTextColor = [NSColor colorWithDeviceHue:0 saturation:0 brightness:63.0/255.0 alpha:1.0];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, 
                                     paragraphStyle, NSParagraphStyleAttributeName,
                                     headerTextColor, NSForegroundColorAttributeName,
                                     nil];

    NSAttributedString *monthString = [[[NSAttributedString alloc] initWithString:[mCalendarController.displayStartDate descriptionWithCalendarFormat:@"%B %Y"] attributes:attrsDictionary] autorelease];
    [monthHeaderString release];
    monthHeaderString = [monthString retain];

    [self setNeedsDisplay:YES];
}

@end
