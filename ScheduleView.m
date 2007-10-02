//
//  ScheduleView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleView.h"
#import "ScheduleStationColumnView.h"
#import "ScheduleHeaderView.h"
#import "Z2ITStation.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"


@implementation ScheduleView

- (float) timeSpan
{
  return 24 * 60;   // minutes
}

- (float) timePerLineIncrement
{
  return 30;      // minutes
}

- (float) visibleTimeSpan
{
  return 3 * 60; // minutes
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSRect subViewFrame = NSMakeRect(0, 0, frame.size.width, frame.size.height);

        // Add the time scroller to the bottom of the frame
        subViewFrame.size.height = [NSScroller scrollerWidth];
        subViewFrame.size.width -= ([NSScroller scrollerWidth] + [ScheduleStationColumnView columnWidth]);
        subViewFrame.origin.x = [ScheduleStationColumnView columnWidth];
        mTimeScroller = [[NSScroller alloc] initWithFrame:subViewFrame];
        [mTimeScroller setEnabled:YES];
        [mTimeScroller setAutoresizesSubviews:YES];
        [mTimeScroller setAutoresizingMask:NSViewWidthSizable];
        [mTimeScroller setAction:@selector(scrollerChanged:)];
        [mTimeScroller setTarget:self];
        
        // Add the station scroller to the right side
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.width = [NSScroller scrollerWidth];
        subViewFrame.size.height -= ([NSScroller scrollerWidth] + [ScheduleHeaderView headerHeight]);
        subViewFrame.origin.x = frame.size.width - [NSScroller scrollerWidth];
        subViewFrame.origin.y = [NSScroller scrollerWidth];
        
        mStationsScroller = [[NSScroller alloc] initWithFrame:subViewFrame];
        [mStationsScroller setEnabled:YES];
        [mStationsScroller setAutoresizesSubviews:YES];
        [mStationsScroller setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
        [mStationsScroller setAction:@selector(scrollerChanged:)];
        [mStationsScroller setTarget:self];
        
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.width = [ScheduleStationColumnView columnWidth];
        subViewFrame.size.height -= ([NSScroller scrollerWidth] + [ScheduleHeaderView headerHeight]);
        subViewFrame.origin.y += [NSScroller scrollerWidth];
        mStationColumnView = [[ScheduleStationColumnView alloc] initWithFrame:subViewFrame];
        [mStationColumnView setAutoresizingMask:NSViewHeightSizable];
        
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.height = [ScheduleHeaderView headerHeight];
        subViewFrame.size.width -= [NSScroller scrollerWidth];
        subViewFrame.origin.y  = frame.size.height - [ScheduleHeaderView headerHeight];
        mHeaderView = [[ScheduleHeaderView alloc] initWithFrame:subViewFrame];
        [mHeaderView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
        
        [self addSubview:mTimeScroller];
        [self addSubview:mStationsScroller];
        [self addSubview:mStationColumnView];
        [self addSubview:mHeaderView];
        
        [mTimeScroller release];
        [mStationsScroller release];
        [mStationColumnView release];
        [mHeaderView release];
        
        mSortedStationsArray = nil;

    }
    return self;
}

- (void) awakeFromNib
{
        // Setup KVO for selected stations
        mSortedStationsArray = nil;
        [mLineupArrayController addObserver:self forKeyPath:@"selectedObjects" options:0x0 context:NULL];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    [[NSColor redColor] set];
    [NSBezierPath strokeLineFromPoint:[self bounds].origin toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y + [self bounds].size.height)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x, [self bounds].origin.y + [self bounds].size.height) toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y)];
}

- (IBAction) scrollerChanged:(NSScroller*)inScroller
{
    float knobPosition = [inScroller floatValue];
    float newKnobPosition = knobPosition;
    BOOL updateScheduleView = NO;
    
    float lineIncrement = 0;
    float pageIncrement = 0;
    if (inScroller == mTimeScroller)
    {
      lineIncrement = [self timePerLineIncrement] / [self timeSpan];
      pageIncrement = [self visibleTimeSpan] / [self timeSpan];
    }
    if (inScroller == mStationsScroller)
    {
      lineIncrement = 1.0f / (float) [mSortedStationsArray count];
      pageIncrement = (float) [mStationColumnView numberStationsDisplayed] / (float) ([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]);
    }
    
    switch ([inScroller hitPart]) {
        case NSScrollerIncrementLine:
        // Include code here for the case where the down arrow is pressed
        newKnobPosition += lineIncrement;
            break;
        case NSScrollerIncrementPage:
        // Include code here for the case where CTRL + down arrow is pressed, or the space the scroll knob moves in is pressed
        newKnobPosition += pageIncrement;
            break;
        case NSScrollerDecrementLine:
        // Include code here for the case where the up arrow is pressed
        newKnobPosition -= lineIncrement;
            break;
        case NSScrollerDecrementPage:
        // Include code here for the case where CTRL + up arrow is pressed, or the space the scroll knob moves in is pressed
        newKnobPosition -= pageIncrement;
            break;
        case NSScrollerKnob:
        // This case is when the knob itself is pressed
            knobPosition = [inScroller floatValue];
            // Do something with the view
            updateScheduleView = YES;
        default:
            break;
    }
    updateScheduleView = updateScheduleView | (newKnobPosition != knobPosition);
    if (newKnobPosition != knobPosition)
    {
        [inScroller setFloatValue:newKnobPosition];
    }
    
    if (updateScheduleView)
    {
      if (inScroller == mTimeScroller)
      {
        CFGregorianUnits timeChange;
        memset(&timeChange, 0, sizeof(timeChange));
        timeChange.minutes = [inScroller floatValue] * [self timeSpan];
        CFAbsoluteTime newStartTime = CFAbsoluteTimeAddGregorianUnits(mStartTime,CFTimeZoneCopySystem(),timeChange);
        [mHeaderView setStartTime:newStartTime];
      }
      if (inScroller == mStationsScroller)
      {
        unsigned newStartIndex = ([inScroller floatValue] * (float)([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]) + 0.5);
        [mStationColumnView setStartStationIndex:newStartIndex];
      }
    }
}

#pragma mark Station list updating methods

// Compare two stations according to their overall lineup channel numbers (major and minor)
int sortStationsWithLineup(id thisStation, id otherStation, void *context)
{
  Z2ITLineup *currentLineup = (Z2ITLineup*)context;
  
  // We just look at the first lineup map - there's no real way to compare station
  // numbers across multiple maps.
  Z2ITLineupMap *lineupMapOtherStation, *lineupMapThisStation;
  
  lineupMapThisStation = [thisStation lineupMapForLineupID:[currentLineup lineupID]];
  lineupMapOtherStation = [otherStation lineupMapForLineupID:[currentLineup lineupID]];
  
  // Channel numbers are not neccessarily integers - they might be alphabetic
  int thisStationChannel = [[lineupMapThisStation channel] intValue];
  int otherStationChannel = [[lineupMapOtherStation channel] intValue];
  if ((thisStationChannel == otherStationChannel) && (thisStationChannel != 0))
  {
    // Numeric matching channel numbers so compare minor channel numbers
    NSNumber *thisStationChannelMinor = [lineupMapThisStation channelMinor];
    NSNumber *otherStationChannelMinor = [lineupMapOtherStation channelMinor];
   return ([thisStationChannelMinor compare:otherStationChannelMinor]);
  }
  else if ((thisStationChannel == 0) && (otherStationChannel == 0))
  {
    // Two alphabetic channels
    return ([[lineupMapThisStation channel] compare:[lineupMapOtherStation channel]]);
  }
  else
  {
    // Numeric (non-matching) channel numbers
    if (thisStationChannel < otherStationChannel)
      return NSOrderedAscending;
    else
      return NSOrderedDescending;
  }
}

- (void) updateStationsScroller
{
  float currOffset = [mStationsScroller floatValue];
  float knobProportion = (float)[mStationColumnView numberStationsDisplayed] / (float)([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]);
  [mStationsScroller setFloatValue:currOffset knobProportion:knobProportion];
}

- (void) sortStationsArray
{
  NSArray *aStationsArray = [[[mLineupArrayController selectedObjects] objectAtIndex:0] stations];
  Z2ITLineup* currentLineup = [[mLineupArrayController selectedObjects] objectAtIndex:0];
  mSortedStationsArray =  [aStationsArray sortedArrayUsingFunction:sortStationsWithLineup context:currentLineup];
  [mStationColumnView setSortedStationsArray:mSortedStationsArray forLineup:currentLineup] ;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == mLineupArrayController) && ([keyPath isEqual:@"selectedObjects"]))
    {
      [self sortStationsArray];
      [self updateStationsScroller];
    }
 }


@end
