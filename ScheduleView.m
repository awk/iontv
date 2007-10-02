//
//  ScheduleView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecSchedNotifications.h"
#import "ScheduleView.h"
#import "ScheduleStationColumnView.h"
#import "ScheduleHeaderView.h"
#import "ScheduleGridView.h"
#import "Z2ITStation.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITSchedule.h"

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

        // Add the station scroller to the right side
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.width = [NSScroller scrollerWidth];
        subViewFrame.size.height -= [ScheduleHeaderView headerHeight];
        subViewFrame.origin.x = frame.size.width - [NSScroller scrollerWidth];
        
        mStationsScroller = [[NSScroller alloc] initWithFrame:subViewFrame];
        [mStationsScroller setEnabled:YES];
        [mStationsScroller setAutoresizesSubviews:YES];
        [mStationsScroller setAutoresizingMask:NSViewHeightSizable | NSViewMinXMargin];
        [mStationsScroller setAction:@selector(scrollerChanged:)];
        [mStationsScroller setTarget:self];
        
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.width = [ScheduleStationColumnView columnWidth];
        subViewFrame.size.height -= [ScheduleHeaderView headerHeight];
        mStationColumnView = [[ScheduleStationColumnView alloc] initWithFrame:subViewFrame];
        [mStationColumnView setAutoresizingMask:NSViewHeightSizable];
        
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.height = [ScheduleHeaderView headerHeight];
        subViewFrame.size.width -= [NSScroller scrollerWidth];
        subViewFrame.origin.y  = frame.size.height - [ScheduleHeaderView headerHeight];
        mHeaderView = [[ScheduleHeaderView alloc] initWithFrame:subViewFrame];
        [mHeaderView setAutoresizingMask:NSViewWidthSizable|NSViewMinYMargin];
        
        subViewFrame  = NSMakeRect(0, 0, frame.size.width, frame.size.height);
        subViewFrame.size.height -= [ScheduleHeaderView headerHeight];
        subViewFrame.size.width -= ([ScheduleStationColumnView columnWidth] + [NSScroller scrollerWidth]);
        subViewFrame.origin.x = [ScheduleStationColumnView columnWidth];
        mGridView = [[ScheduleGridView alloc] initWithFrame:subViewFrame];
        [mGridView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
        [mGridView setDelegate:delegate];
        
        [self addSubview:mStationsScroller];
        [self addSubview:mStationColumnView];
        [self addSubview:mHeaderView];
        [self addSubview:mGridView];
        
        mSortedStationsArray = nil;
        CFGregorianDate previousHour = CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),CFTimeZoneCopySystem());
        if (previousHour.minute > 30)
          previousHour.minute = 30;
        else
          previousHour.minute = 0;
        previousHour.second = 0;
        mStartTime = CFGregorianDateGetAbsoluteTime(previousHour,CFTimeZoneCopySystem());
        [mHeaderView setStartTime:mStartTime];
        [mGridView setStartTime:mStartTime];
        [mGridView setVisibleTimeSpan:[self visibleTimeSpan]];
    }
    return self;
}

- (void) dealloc 
{
  // Unregister for the update notifications
  [[NSNotificationCenter defaultCenter] removeObserver:self name:RSNotificationManagedObjectContextUpdated object:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
  
  [mStationsScroller release];
  [mStationColumnView release];
  [mHeaderView release];
  [mGridView release];
  [delegate release];
  
  [super dealloc];
}

- (void) awakeFromNib
{
        // Setup KVO for selected stations
        mSortedStationsArray = nil;
        [mCurrentLineup addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew context:nil];
        [mCurrentSchedule addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew context:nil];
        
        // Register to receive Managed Object context update notifications - when adding objects in to the context from a seperate
        // thread (during parsing) 'our' managed object context may not notify the NSObjectControllers that new data has been added
        // This notification is sent during the end of saving to notify everyone of new content
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateControllers) name:RSNotificationManagedObjectContextUpdated object:[[[NSApplication sharedApplication] delegate] managedObjectContext]];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:[self frame]];
//    [NSBezierPath strokeLineFromPoint:[self bounds].origin toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y + [self bounds].size.height)];
//    [NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x, [self bounds].origin.y + [self bounds].size.height) toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y)];
}

- (id) delegate
{
  return delegate;
}

- (void) setDelegate:(id)inDelegate
{
  if (delegate != inDelegate)
  {
    [delegate release];
    delegate = [inDelegate retain];
  }
  
  // Also set the delegate on our 'contained' subview that handles the grid
  [mGridView setDelegate:inDelegate];
}

- (void) setStartTime:(CFAbsoluteTime)inTime
{
  mStartTime = inTime;
  [mGridView setStartTime:mStartTime];
  [mHeaderView setStartTime:mStartTime];
}

- (void) stationsScrollerChanged:(NSScroller *)inScroller
{

    float knobPosition = [inScroller floatValue];
    float newKnobPosition = knobPosition;
    BOOL updateScheduleView = NO;
    
    float lineIncrement = 0;
    float pageIncrement = 0;

    lineIncrement = 1.0f / (float) [mSortedStationsArray count];
    pageIncrement = (float) [mStationColumnView numberStationsDisplayed] / (float) ([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]);
    
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
      unsigned newStartIndex = ([inScroller floatValue] * (float)([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]) + 0.5);
      [mStationColumnView setStartStationIndex:newStartIndex];
      [mGridView setStartStationIndex:newStartIndex];
    }
}

- (IBAction) scrollerChanged:(NSScroller*)inScroller
{
    if (inScroller == mStationsScroller)
      [self stationsScrollerChanged:inScroller];
}

- (void) scrollToStation:(Z2ITStation*) inStation
{
  int stationIndex = [mSortedStationsArray indexOfObject:inStation];
  if (stationIndex != NSNotFound)   // It might not be in the current array - since we may need to change lineups (somewhere else)
  {
    int currStartIndex = ([mStationsScroller floatValue] * (float)([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]) + 0.5);
    if ((stationIndex < currStartIndex) || (stationIndex > currStartIndex + [mStationColumnView numberStationsDisplayed]))
    {
        // Incorrect conversion here for scroller value
        float newScroller = stationIndex / ((float)([mSortedStationsArray count] - [mStationColumnView numberStationsDisplayed]) + 0.5);
        [mStationsScroller setFloatValue:newScroller];
        [mStationColumnView setStartStationIndex:stationIndex];
        [mGridView setStartStationIndex:stationIndex];
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
  NSArray *aStationsArray = [[mCurrentLineup content] stations];
  Z2ITLineup* currentLineup = [mCurrentLineup content];
  mSortedStationsArray =  [aStationsArray sortedArrayUsingFunction:sortStationsWithLineup context:currentLineup];
  [mStationColumnView setSortedStationsArray:mSortedStationsArray forLineup:currentLineup] ;
  [mGridView setSortedStationsArray:mSortedStationsArray forLineup:currentLineup];
}

- (void) updateForCurrentSchedule
{
  // Set the time (if we have to change it)
  CFAbsoluteTime startTime = [[[mCurrentSchedule content] time] timeIntervalSinceReferenceDate];
  CFAbsoluteTime endTime = [[[mCurrentSchedule content] endTime] timeIntervalSinceReferenceDate];
  if ((endTime < mStartTime)
      || (startTime > mStartTime + ([self visibleTimeSpan] * 60)))
  {
    // We need to set the view to the nearest 30 minutes prior to the selected item
    startTime = startTime - (30*60);
    startTime = floor(startTime / (30*60)) * (30*60);
    [self setStartTime:startTime];
  }

  // Scroll if the selected station is not visible
  [self scrollToStation:[[mCurrentSchedule content] station]];
  [mGridView setSelectedSchedule:[mCurrentSchedule content]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == mCurrentLineup) && ([keyPath isEqual:@"content"]))
    {
      // Update the stations list
      [self sortStationsArray];
      [self updateStationsScroller];

      // Make sure the current schedule item is visible
      [self updateForCurrentSchedule];
    }
    if ((object == mCurrentSchedule) && ([keyPath isEqual:@"content"]))
    {
      [self updateForCurrentSchedule];
    }
 }

- (void) updateControllers
{
  [mCurrentLineup prepareContent];
}

@end
