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

#import "ScheduleHeaderView.h"
#import "ScheduleView.h"
#import "ScheduleStationColumnView.h"

const int kScheduleHeaderViewDefaultNumberOfCells = 6;

@interface ScheduleHeaderCell : NSTextFieldCell {
}

+ (NSGradient*) sharedGradient;
@end

@implementation ScheduleHeaderCell

static NSGradient *sScheduleHeaderCellSharedGradient = nil;

+ (NSGradient*) sharedGradient {
  @synchronized(self) {
    if (!sScheduleHeaderCellSharedGradient) {
      sScheduleHeaderCellSharedGradient = [NSGradient alloc];
    }
  }
  return sScheduleHeaderCellSharedGradient;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  // set line width to 0 (smallest possible line - ie one pixel)
  [NSBezierPath setDefaultLineWidth:0.0];

  // Draw background
  NSGradient *aGradient = [ScheduleHeaderCell sharedGradient];
  [aGradient initWithStartingColor:[NSColor colorWithDeviceHue:0 saturation:0 brightness:187.0/255.0 alpha:1.0] endingColor:[NSColor colorWithDeviceHue:0 saturation:0 brightness:219.0/255.0 alpha:1.0]];
  [aGradient drawInRect:cellFrame angle:90.0];

  // Draw top/bottom lines
  [[NSColor colorWithDeviceRed:85.0/255.0 green:85.0/255.0 blue:85.0/255.0 alpha:1.0] set];
  NSRect topBottomRect = cellFrame;
  topBottomRect.size.height = 1.0;
  [NSBezierPath strokeLineFromPoint:topBottomRect.origin toPoint:NSMakePoint(topBottomRect.origin.x + topBottomRect.size.width, topBottomRect.origin.y)];

  topBottomRect.origin.y = cellFrame.origin.y + cellFrame.size.height - 1.5;
  [[NSColor colorWithDeviceRed:64.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0] set];
  [NSBezierPath strokeLineFromPoint:topBottomRect.origin toPoint:NSMakePoint(topBottomRect.origin.x + topBottomRect.size.width, topBottomRect.origin.y)];

  // Draw left/right sides
  NSRect dividerRect = cellFrame;
  dividerRect.origin.x =floor(dividerRect.origin.x)+0.5;
  dividerRect.size.height -= 3.0;
  dividerRect.origin.y += 1.0;
  [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.25] set];
  [NSBezierPath strokeLineFromPoint:dividerRect.origin toPoint:NSMakePoint(dividerRect.origin.x, dividerRect.origin.y+dividerRect.size.height)];

  dividerRect.origin.x = floor(cellFrame.origin.x + cellFrame.size.width) - 0.5;
  [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.25] set];
  [NSBezierPath strokeLineFromPoint:dividerRect.origin toPoint:NSMakePoint(dividerRect.origin.x, dividerRect.origin.y+dividerRect.size.height)];

  // Draw the label string
  NSMutableParagraphStyle *paraInfo = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  [paraInfo  setAlignment:[self alignment]];
  NSDictionary *stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[self textColor], NSForegroundColorAttributeName, paraInfo, NSParagraphStyleAttributeName, [self font], NSFontAttributeName, nil];
  [paraInfo release];
  NSRect stringBounds = [[self stringValue] boundingRectWithSize:cellFrame.size options:0 attributes:stringAttributes];
  stringBounds.origin.y = cellFrame.origin.y + ((cellFrame.size.height - stringBounds.size.height)/2);
  stringBounds.origin.x = cellFrame.origin.x;
  stringBounds.size.width = cellFrame.size.width;
  [[self stringValue] drawInRect:stringBounds withAttributes:stringAttributes];
}

@end

@implementation ScheduleHeaderView

+ (int) headerHeight {
  return 18;
}

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
    mLabelCellArray = [[NSMutableArray alloc] initWithCapacity:kScheduleHeaderViewDefaultNumberOfCells];
    mStartTime = CFAbsoluteTimeGetCurrent();
    float fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
    NSFont *theFont = [NSFont systemFontOfSize:fontSize];

    mStationCell = [[ScheduleHeaderCell alloc] initTextCell:@"Station"];
    [mStationCell setBordered:NO];
    [mStationCell setAlignment:NSCenterTextAlignment];
    [mStationCell setFont:theFont];
    [mStationCell setControlSize:NSSmallControlSize];

    int i=0;
    for (i = 0; i < kScheduleHeaderViewDefaultNumberOfCells; i++) {
      ScheduleHeaderCell *aLabelCell = [[ScheduleHeaderCell alloc] initTextCell:@"--"];
      [aLabelCell setBordered:NO];
      [aLabelCell setAlignment:NSCenterTextAlignment];
      [aLabelCell setFont:theFont];
      [aLabelCell setControlSize:NSSmallControlSize];
      [mLabelCellArray addObject:aLabelCell];
      [aLabelCell release];
    }
    [self setFrameSize:NSMakeSize(frame.size.width,[ScheduleHeaderView headerHeight])];
    [self updateCellLabels];
  }
  return self;
}

- (void) dealloc {
  [mLabelCellArray release];
  [mStationCell release];
  [super dealloc];
}

- (void)drawRect:(NSRect)rect {
  // Draw contents (labels)
  ScheduleView *parentView = (ScheduleView*) [self superview];
  float pixelsPerMinute = ([self frame].size.width - [ScheduleStationColumnView columnWidth]) / ([parentView visibleTimeSpan]);

  NSRect cellFrameRect;
  cellFrameRect.origin.x = cellFrameRect.origin.y = 0;
  cellFrameRect.size.height = [self bounds].size.height;
  cellFrameRect.size.width = [ScheduleStationColumnView columnWidth];
  [mStationCell cellSizeForBounds:cellFrameRect];
  [mStationCell drawWithFrame:cellFrameRect inView:self];

  // Subdivide the current bounds width into even spaced pieces (to number of cells in the array)
  float aCellWidth = pixelsPerMinute * [parentView timePerLineIncrement];
  cellFrameRect = NSMakeRect([ScheduleStationColumnView columnWidth], 0, aCellWidth, [self bounds].size.height);
  for (id loopItem in mLabelCellArray) {
    [loopItem drawWithFrame:cellFrameRect inView:self];
    cellFrameRect.origin.x += aCellWidth;
  }
}

- (void)setStartTime:(CFAbsoluteTime)inStartTime {
  mStartTime = inStartTime;
  [self updateCellLabels];
}

- (void)updateCellLabels {
  // Starting with the start date go back to the nearest 30 minute start and then
  // work forward in 30 minute increments for each cell in the header updating
  // the string as we go
  CFAbsoluteTime cellStartTime, cellEndTime;
  cellStartTime = mStartTime;
  CFGregorianUnits thirtyMinutes;
  memset(&thirtyMinutes,0,sizeof(thirtyMinutes));
  thirtyMinutes.minutes = 30;
  for (id loopItem in mLabelCellArray) {
    CFTimeZoneRef systemTimeZone = CFTimeZoneCopySystem();
    cellEndTime = CFAbsoluteTimeAddGregorianUnits(cellStartTime, systemTimeZone,thirtyMinutes);
    CFGregorianDate cellStartDate = CFAbsoluteTimeGetGregorianDate(cellStartTime, systemTimeZone);
    CFGregorianDate cellEndDate = CFAbsoluteTimeGetGregorianDate(cellEndTime, systemTimeZone);

    NSString *cellStr = [NSString stringWithFormat:@"%02d:%02d - %02d:%02d", cellStartDate.hour, cellStartDate.minute, cellEndDate.hour, cellEndDate.minute];
    // Set the cell label
    [loopItem setStringValue:cellStr];
    // incremement the start date
    cellStartTime = CFAbsoluteTimeAddGregorianUnits(cellStartTime, systemTimeZone,thirtyMinutes);
    CFRelease(systemTimeZone);
  }
  [self setNeedsDisplay:YES];
}

@synthesize mStartTime;
@end
