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

@implementation ScheduleGridView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        int numStationsInView = frame.size.height / kScheduleStationColumnViewCellHeight;
        mStationsInViewArray = [[NSMutableArray alloc] initWithCapacity:numStationsInView];
        mCellsInViewArray = [[NSMutableArray alloc] initWithCapacity:numStationsInView];
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
    cellFrameRect.size.width = 150;

    int i=0;
    float pixelsPerMinute = [self frame].size.width / mVisibleTimeSpan;
    for (i=0; i < [mCellsInViewArray count]; i++)
    {
      Z2ITSchedule *aSchedule = [[mStationsInViewArray objectAtIndex:i] scheduleAtTime:mStartTime];
      if (aSchedule)
      {
        cellFrameRect.origin.y -= kScheduleStationColumnViewCellHeight;
        NSTimeInterval durationRemaining = [[aSchedule endTime] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];
        float programRunTime = durationRemaining / 60.0;
        cellFrameRect.size.width = programRunTime * pixelsPerMinute;
        [[mCellsInViewArray objectAtIndex:i] drawWithFrame:cellFrameRect inView:self];
      }
    }
}

- (void) updateStationsInViewArray
{
  // Update the stations in view array
  int i=0;
  [mStationsInViewArray removeAllObjects];
  [mCellsInViewArray removeAllObjects];
  
  int maxStationIndex = [mSortedStationsArray count];
  if (maxStationIndex > (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight))
    maxStationIndex = (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight);
  for (i=mStartStationIndex; i < maxStationIndex; i++)
  {
    [mStationsInViewArray addObject:[mSortedStationsArray objectAtIndex:i]];
    NSTextFieldCell *aTextCell = [[NSTextFieldCell alloc] initTextCell:@"--"];
    [aTextCell setBordered:YES];
    [mCellsInViewArray addObject:aTextCell];
    [aTextCell release];
  }
  [self setNeedsDisplay:YES];
}

- (void) updateForNewStartTime
{
    CFAbsoluteTime currentTime = mStartTime;
    int i=0;
    for (i=0; i < [mCellsInViewArray count]; i++)
    {
      Z2ITStation *aStation = [mStationsInViewArray objectAtIndex:i];
      Z2ITProgram *aProgram = [aStation programAtTime:currentTime];
      NSTextFieldCell *aTextField = [mCellsInViewArray objectAtIndex:i];
      if (aProgram)
        [aTextField setStringValue:[aProgram title]];
      else
        [aTextField setStringValue:@""];
        
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
