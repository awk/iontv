//
//  ScheduleGridView.m
//  recsched
//
//  Created by Andrew Kimpton on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"
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
  ScheduleGridView *mGridView;
}

- (id) initWithGridView:(ScheduleGridView*)inGridView;
- (void) setStation:(Z2ITStation*)inStation;
- (void) setStartTime:(CFAbsoluteTime)inDate andDuration:(float)inMinutes;
- (void) drawCellsWithFrame:(NSRect) inFrame inView:(NSView *)inView;
- (void) mouseDown:(NSEvent *)theEvent withFrame:(NSRect)inFrame;
@end

@interface ScheduleCell : NSActionCell
{
  Z2ITSchedule *mSchedule;
}

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

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint eventLocation = [theEvent locationInWindow];
  NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
  NSRect cellFrameRect;
  cellFrameRect.origin.x = 0;
  cellFrameRect.origin.y = [self bounds].size.height;
  cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
  cellFrameRect.size.width = [self bounds].size.width;
  
  int scheduleGridLineIndex = ([self frame].size.height - localPoint.y) / kScheduleStationColumnViewCellHeight;
  [[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] mouseDown:theEvent withFrame:cellFrameRect];
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
    ScheduleGridLine *aGridLine = [[ScheduleGridLine alloc] initWithGridView:self];
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

- (void) setSelectedCell:(NSCell*)inCell
{
  [mSelectedCell setHighlighted:NO];
  [mSelectedCell autorelease];
  mSelectedCell = [inCell retain];
  [mSelectedCell setHighlighted:YES];
}

#pragma mark View Notifications

- (void)frameDidChange: (NSNotification *)notification
{
  [self updateStationsInViewArray];
  [self updateForNewStartTime];
}

@end

@implementation ScheduleGridLine

- (id) initWithGridView:(ScheduleGridView*)inGridView
{
  self = [super init];
  if (self != nil) {
    mGridView = inGridView;
  }
  return self;
}

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
    ScheduleCell *aTextCell = [[ScheduleCell alloc] initTextCell:@"--"];
    [aTextCell setBordered:YES];
    [aTextCell setObjectValue:[mSchedulesInLineArray objectAtIndex:i]];
    [mCellsInLineArray addObject:aTextCell];
    [aTextCell release];
  }
}

- (void) scheduleCellClicked:(id)sender
{
  NSLog(@"scheduleCellClicked - sender = %@", sender);
}

- (NSRect) cellFrameRectForSchedule:(Z2ITSchedule *)inSchedule withPixelsPerMinute:(float)pixelsPerMinute
{
  NSRect cellFrameRect;
  NSTimeInterval durationRemaining;
  NSTimeInterval offsetFromStart = [[inSchedule time] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];
  if (offsetFromStart > 0)
  {
    durationRemaining = [[inSchedule endTime] timeIntervalSinceDate:[inSchedule time]];
    cellFrameRect.origin.x = (offsetFromStart / 60.0) * pixelsPerMinute;
  }
  else
  {
    durationRemaining = [[inSchedule endTime] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];
    cellFrameRect.origin.x = 0;
  }
  float programRunTime = durationRemaining / 60.0;
  cellFrameRect.size.width = programRunTime * pixelsPerMinute;
  return cellFrameRect;
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
        cellFrameRect = [self cellFrameRectForSchedule:aSchedule withPixelsPerMinute:pixelsPerMinute];
        cellFrameRect.origin.y = inFrame.origin.y;
        cellFrameRect.size.height = inFrame.size.height;
        
        // Draw the cell
        [[mCellsInLineArray objectAtIndex:i] drawWithFrame:cellFrameRect inView:inView];
      }
    }
}

- (void)mouseDown:(NSEvent *)theEvent withFrame:(NSRect)inFrame
{
  NSPoint eventLocation = [theEvent locationInWindow];
  NSPoint localPoint = [mGridView convertPoint:eventLocation fromView:nil];
  
  // Calculate the pixels per minute value
  float pixelsPerMinute = inFrame.size.width / ((mEndTime - mStartTime) / 60);

  BOOL foundCell = NO;
  int i=0;
  Z2ITSchedule *aSchedule = nil;
  NSRect aCellFrameRect = NSMakeRect(0, 0, 0, 0);
  for (i=0; (i < [mCellsInLineArray count]) && (!foundCell); i++)
  {
      aSchedule = [mSchedulesInLineArray objectAtIndex:i];
      if (aSchedule)
      {
        aCellFrameRect = [self cellFrameRectForSchedule:aSchedule withPixelsPerMinute:pixelsPerMinute];
        aCellFrameRect.origin.y = 0;
        aCellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
        // We always make the click to be in the middle of the cell vertically
        localPoint.y = kScheduleStationColumnViewCellHeight / 2;
        if (NSPointInRect(localPoint, aCellFrameRect))
        {
          foundCell = YES;
          [mGridView setSelectedCell:[mCellsInLineArray objectAtIndex:i]];
        }
      }
  }
  if (foundCell)
  {
    MainWindowController *mwc = [[mGridView window] delegate];
    if ([mwc class] == [MainWindowController class])
    {
      [mwc setCurrentSchedule:aSchedule];
    }
    [mGridView setNeedsDisplay:YES];
  }
}

@end

@implementation ScheduleCell

- (void) setObjectValue:(id)anObject
{
  [mSchedule autorelease];
  mSchedule = [anObject retain];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  if ([self isHighlighted])
  {
    [NSGraphicsContext saveGraphicsState];
    [[NSColor colorForControlTint:NSGraphiteControlTint] set];
    [NSBezierPath fillRect:cellFrame];
    [NSGraphicsContext restoreGraphicsState];
  }
  
  // Inset the cell frame rect a little
  cellFrame.size.width -= 4;
  cellFrame.size.height -= 4;
  cellFrame.origin.x += 2;
  cellFrame.origin.y += 2;
  NSString *titleString = [[mSchedule program] title];
  [titleString drawInRect:cellFrame withAttributes:nil];
}

@end
