//
//  ScheduleGridView.m
//  recsched
//
//  Created by Andrew Kimpton on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleGridView.h"
#import "ScheduleStationColumnView.h"
#import "Z2ITStation.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

@interface ScheduleGridLine : NSObject
{
  NSMutableArray *mCellsInLineArray;
  NSArray        *mSchedulesInLineArray;
  Z2ITStation    *mStation;
  CFAbsoluteTime mStartTime;
  CFAbsoluteTime mEndTime;
}

- (void) setStation:(Z2ITStation*)inStation;
- (void) setStartTime:(CFAbsoluteTime)inDate andDuration:(float)inMinutes;
- (void) drawCellsWithFrame:(NSRect) inFrame inView:(NSView *)inView;
@end

@implementation ScheduleGridView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        int numStationsInView = frame.size.height / kScheduleStationColumnViewCellHeight;
        mStationsInViewArray = [[NSMutableArray alloc] initWithCapacity:numStationsInView];
//        mCellsInViewArray = [[NSMutableArray alloc] initWithCapacity:numStationsInView];
        mStartStationIndex = 0;
        mStartTime = CFAbsoluteTimeGetCurrent();

        [[NSNotificationCenter defaultCenter]  addObserver: self
          selector: @selector(frameDidChange:)
          name: NSViewFrameDidChangeNotification
          object: self];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
//    [[NSColor blueColor] set];
//    [NSBezierPath strokeLineFromPoint:[self bounds].origin toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y + [self bounds].size.height)];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x, [self bounds].origin.y + [self bounds].size.height) toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y)];

    NSRect cellFrameRect;
    cellFrameRect.origin.x = 0;
    cellFrameRect.origin.y = [self bounds].size.height;
    cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
    cellFrameRect.size.width = [self bounds].size.width;

    int i=0;
    for (i=0; i < [mStationsInViewArray count]; i++)
    {
      ScheduleGridLine *aGridLine = [mStationsInViewArray objectAtIndex:i];
      if (aGridLine)
      {
        cellFrameRect.origin.y -= kScheduleStationColumnViewCellHeight;
        [aGridLine drawCellsWithFrame:cellFrameRect inView:self];
      }
    }
}

- (void) updateStationsInViewArray
{
  // Update the stations in view array
  int i=0;
  [mStationsInViewArray removeAllObjects];
  
  int maxStationIndex = [mSortedStationsArray count];
  if (maxStationIndex > (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight))
    maxStationIndex = (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight);
  for (i=mStartStationIndex; i < maxStationIndex; i++)
  {
    ScheduleGridLine *aGridLine = [[ScheduleGridLine alloc] init];
    [aGridLine setStation:[mSortedStationsArray objectAtIndex:i]];
    
    [mStationsInViewArray addObject:aGridLine];
    [aGridLine release];
  }
  [self setNeedsDisplay:YES];
}

- (void) updateForNewStartTime
{
    int i=0;
    for (i=0; i < [mStationsInViewArray count]; i++)
    {
      ScheduleGridLine *aGridLine = [mStationsInViewArray objectAtIndex:i];
      [aGridLine setStartTime:mStartTime andDuration:mVisibleTimeSpan];
    }
    [self setNeedsDisplay:YES];
}

- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
{
  [mCurrentLineup autorelease];
  mCurrentLineup = [inLineup retain];
  [mSortedStationsArray autorelease];
  mSortedStationsArray = [inArray retain];
  [self updateStationsInViewArray];
  [self updateForNewStartTime];
}

- (void) setStartStationIndex:(unsigned)inIndex
{
  mStartStationIndex = inIndex;
  [self updateStationsInViewArray];
  [self updateForNewStartTime];
}

- (void) setStartTime:(CFAbsoluteTime)inStartTime
{
  mStartTime = inStartTime;
  [self updateForNewStartTime];
}

- (void) setVisibleTimeSpan:(float)inTimeSpan
{
  mVisibleTimeSpan = inTimeSpan;
  [self updateForNewStartTime];
}

#pragma mark View Notifications

- (void)frameDidChange: (NSNotification *)notification
{
  [self updateStationsInViewArray];
  [self updateForNewStartTime];
}

@end

@implementation ScheduleGridLine

- (void) setStation:(Z2ITStation*)inStation
{
  [mStation autorelease];
  mStation = [inStation retain];
}

- (void) setStartTime:(CFAbsoluteTime)inTime andDuration:(float)inMinutes
{
  mStartTime = inTime;
  mEndTime = mStartTime + (inMinutes * 60);
  
  // Get all the schedules for the specified range
  [mSchedulesInLineArray release];
  mSchedulesInLineArray = [[mStation schedulesBetweenStartTime:mStartTime andEndTime:mEndTime] retain];
  
  // Remove and reallocate all the display cells
  [mCellsInLineArray release];
  mCellsInLineArray = [[NSMutableArray alloc] initWithCapacity:[mSchedulesInLineArray count]];
  int i=0;
  for (i=0; i < [mSchedulesInLineArray count]; i++)
  {
    NSTextFieldCell *aTextCell = [[NSTextFieldCell alloc] initTextCell:@"--"];
    [aTextCell setBordered:YES];
    [mCellsInLineArray addObject:aTextCell];
    [aTextCell setStringValue:[[[mSchedulesInLineArray objectAtIndex:i] program] title]];
    [aTextCell release];
  }
}

- (void) drawCellsWithFrame:(NSRect) inFrame inView:(NSView *)inView
{
    NSRect cellFrameRect;
    cellFrameRect = inFrame;  // Start with the input dimensions

    int i=0;
  // Calculate the pixels per minute value
    float pixelsPerMinute = inFrame.size.width / ((mEndTime - mStartTime) / 60);

  // Iterate over all the cells drawing them with the correct size rect for the duration
    for (i=0; i < [mCellsInLineArray count]; i++)
    {
      Z2ITSchedule *aSchedule = [mSchedulesInLineArray objectAtIndex:i];
      if (aSchedule)
      {
        NSTimeInterval offsetFromStart = [[aSchedule time] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];
        if (offsetFromStart > 0)
          cellFrameRect.origin.x = (offsetFromStart / 60.0) * pixelsPerMinute;
        else
          cellFrameRect.origin.x = 0;
        NSTimeInterval durationRemaining = [[aSchedule endTime] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];
        float programRunTime = durationRemaining / 60.0;
        cellFrameRect.size.width = programRunTime * pixelsPerMinute;
        // Draw the cell
        [[mCellsInLineArray objectAtIndex:i] drawWithFrame:cellFrameRect inView:inView];
      }
    }
  
  
}
@end