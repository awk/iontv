//
//  ScheduleHeaderView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/23/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleHeaderView.h"
#import "ScheduleStationColumnView.h"
#import "iTableColumnHeaderCell.h"

@implementation ScheduleHeaderView

+ (int) headerHeight
{
        float fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
        NSFont *theFont = [NSFont systemFontOfSize:fontSize];
        
        NSTextFieldCell *aStationCell = [[NSTextFieldCell alloc] initTextCell:@"Station"];
        [aStationCell setBordered:YES];
        [aStationCell setAlignment:NSCenterTextAlignment];
        [aStationCell setFont:theFont];
        [aStationCell setControlSize:NSSmallControlSize];
        NSSize cellSize = [aStationCell cellSize];
        [aStationCell release];
        return cellSize.height;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        mLabelCellArray = [[NSMutableArray alloc] initWithCapacity:kScheduleHeaderViewDefaultNumberOfCells];
        mStartTime = CFAbsoluteTimeGetCurrent();
        float fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
        NSFont *theFont = [NSFont systemFontOfSize:fontSize];
        
        mStationCell = [[NSTextFieldCell alloc] initTextCell:@"Station"];
        [mStationCell setBordered:YES];
        [mStationCell setAlignment:NSCenterTextAlignment];
        [mStationCell setFont:theFont];
        [mStationCell setControlSize:NSSmallControlSize];

        int i=0;
        for (i = 0; i < kScheduleHeaderViewDefaultNumberOfCells; i++)
        {
          NSTextFieldCell *aLabelCell = [[NSTextFieldCell alloc] initTextCell:@"--"];
          [aLabelCell setBordered:YES];
          [aLabelCell setAlignment:NSCenterTextAlignment];
          [aLabelCell setFont:theFont];
          [aLabelCell setControlSize:NSSmallControlSize];
          [mLabelCellArray addObject:aLabelCell];
          [aLabelCell release];
        }
        NSSize cellSize = [[mLabelCellArray objectAtIndex:0] cellSize];
        [self setFrameSize:NSMakeSize(frame.size.width,cellSize.height)];
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
    // Drawing code here.
    NSRect cellFrameRect;
    cellFrameRect.origin.x = cellFrameRect.origin.y = 0;
    cellFrameRect.size.height = [self bounds].size.height;
    cellFrameRect.size.width = [ScheduleStationColumnView columnWidth];
    [mStationCell drawWithFrame:cellFrameRect inView:self];
    // Subdivide the current bounds width into even spaced pieces (to number of cells in the array)
    int numberLabelCells = [mLabelCellArray count];
    int aCellWidth = ([self bounds].size.width - [ScheduleStationColumnView columnWidth]) / numberLabelCells;
    int i=0;
    cellFrameRect = NSMakeRect([ScheduleStationColumnView columnWidth], 0, aCellWidth, [self bounds].size.height);
    for (i=0; i < numberLabelCells; i++)
    {
      [[mLabelCellArray objectAtIndex:i] drawWithFrame:cellFrameRect inView:self];
      cellFrameRect.origin.x += aCellWidth;
    }
}

- (void) setStartTime:(CFAbsoluteTime)inStartTime
{
  mStartTime = inStartTime;
  [self updateCellLabels];
}

- (void) updateCellLabels
{
  // Starting with the start date go back to the nearest 30 minute start and then
  // work forward in 30 minute increments for each cell in the header updating
  // the string as we go
  CFAbsoluteTime cellStartTime, cellEndTime;
  cellStartTime = mStartTime;
  int numberOfCells = [mLabelCellArray count];
  int i=0;
  CFGregorianUnits thirtyMinutes;
  memset(&thirtyMinutes,0,sizeof(thirtyMinutes));
  thirtyMinutes.minutes = 30;
  for (i=0; i < numberOfCells; i++)
  {
    cellEndTime = CFAbsoluteTimeAddGregorianUnits(cellStartTime,CFTimeZoneCopySystem(),thirtyMinutes);
    CFGregorianDate cellStartDate = CFAbsoluteTimeGetGregorianDate(cellStartTime,CFTimeZoneCopySystem());
    CFGregorianDate cellEndDate = CFAbsoluteTimeGetGregorianDate(cellEndTime, CFTimeZoneCopySystem());

    NSString *cellStr = [NSString stringWithFormat:@"%02d:%02d - %02d:%02d", cellStartDate.hour, cellStartDate.minute, cellEndDate.hour, cellEndDate.minute];
    // Set the cell label
    [[mLabelCellArray objectAtIndex:i] setStringValue:cellStr];
    // incremement the start date
    cellStartTime = CFAbsoluteTimeAddGregorianUnits(cellStartTime,CFTimeZoneCopySystem(),thirtyMinutes);
  }
  [self setNeedsDisplay:YES];
}

@end
