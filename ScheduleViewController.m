//
//  ScheduleViewController.m
//  recsched
//
//  Created by Andrew Kimpton on 1/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleViewController.h"
#import "ScheduleHeaderView.h"
#import "ScheduleStationColumnView.h"
#import "Z2ITLineup.h"
#import "Z2ITStation.h"
#import "Z2ITLineupMap.h"

const float kScheduleViewDefaultVisibleTimeSpan = 3 * 60;
const float kScheduleViewDefaultTimeSpan = 24 * 60;
const float kScheduleViewTimePerLineIncrement = 30;

@implementation ScheduleViewController

- (void) awakeFromNib
{
  // Setup the Time Scroller
  [mTimeScroller setControlSize:NSRegularControlSize];
  [mTimeScroller setEnabled:YES];
  NSRect scrollerPartRect = [mTimeScroller rectForPart:NSScrollerIncrementLine];
  NSRect scrollerFrame = [mTimeScroller frame];
  scrollerFrame.size.height = scrollerPartRect.size.height;
  scrollerFrame.size.width -= kScheduleStationColumnViewWidth;
  scrollerFrame.origin.x += kScheduleStationColumnViewWidth;
  [mTimeScroller setFrame:scrollerFrame];
  [mTimeScroller setFloatValue:0.0 knobProportion:kScheduleViewDefaultVisibleTimeSpan / kScheduleViewDefaultTimeSpan];

  // Setup the stations scroller
  [mStationsScroller setControlSize:NSRegularControlSize];
  [mStationsScroller setEnabled:YES];
  [mStationsScroller setFloatValue:0.0 knobProportion:1.0];

  mStartTime = CFAbsoluteTimeGetCurrent();
  [mHeaderView setStartTime:mStartTime];

  mSortedStationsArray = nil;
  [mLineupArrayController addObserver:self forKeyPath:@"selectedObjects" options:0x0 context:NULL];
}

- (void) dealloc {
  [mSortedStationsArray release];
  [super dealloc];
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
      lineIncrement = kScheduleViewTimePerLineIncrement / kScheduleViewDefaultTimeSpan;
      pageIncrement = kScheduleViewDefaultVisibleTimeSpan / kScheduleViewDefaultTimeSpan;
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
        timeChange.minutes = [inScroller floatValue] * kScheduleViewDefaultTimeSpan;
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
