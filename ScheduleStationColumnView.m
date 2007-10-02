//
//  ScheduleStationColumnView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleStationColumnView.h"
#import "Z2ITStation.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"

const int kScheduleStationColumnViewCellHeight = 16;
const int kScheduleStationColumnViewDefaultNumberOfCells = 200;

@implementation ScheduleStationColumnView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        mStationLabelCellArray = [[NSMutableArray alloc] initWithCapacity:kScheduleStationColumnViewDefaultNumberOfCells];
        mSortedStationsArray = nil;
        mCurrentLineup = nil;
        
        [self setFrameSize:NSMakeSize(kScheduleStationColumnViewWidth, [self frame].size.height)];
    }
    return self;
}

- (void) dealloc {
  [mSortedStationsArray release];
  [mStationLabelCellArray release];
  [mCurrentLineup release];
  [super dealloc];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    NSRect cellFrameRect;
    cellFrameRect.origin.x = 0;
    cellFrameRect.origin.y = [self bounds].size.height;
    cellFrameRect.size.width = [self bounds].size.width;
    cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;

    // Only draw as many cells as there is space
    int numberLabelCells = [mStationLabelCellArray count] <  ([self bounds].size.height / kScheduleStationColumnViewCellHeight) ? [mStationLabelCellArray count]  : ([self bounds].size.height / kScheduleStationColumnViewCellHeight);
    if (numberLabelCells == 0)
      return;   // Nothing to draw
      
    // We always draw one more cell than neccessary to accomodate partial scrolling
    numberLabelCells++;
    
    int i=0;
    for (i=mStartStationIndex; (i < (mStartStationIndex + numberLabelCells)) && (i < [mStationLabelCellArray count]); i++)
    {
      cellFrameRect.origin.y -= kScheduleStationColumnViewCellHeight;
      [[mStationLabelCellArray objectAtIndex:i] drawWithFrame:cellFrameRect inView:self];
    }
}

- (void) updateCellLabels
{
    if (!mSortedStationsArray)
      return;
    
    [mStationLabelCellArray removeAllObjects];
    
    float fontSize = [NSFont systemFontSizeForControlSize:NSSmallControlSize];
    NSFont *theFont = [NSFont systemFontOfSize:fontSize];
    
    int i=0;
    for (i = 0; i < [mSortedStationsArray count]; i++)
    {
      Z2ITStation *aStation = [mSortedStationsArray objectAtIndex:i];
      Z2ITLineupMap *aLineupMap = [aStation lineupMapForLineupID:[mCurrentLineup lineupID]];
      NSString *cellString = [NSString stringWithFormat:@"%@ - %@", [aLineupMap channel], [aStation valueForKey:@"callSign"]];
      NSTextFieldCell *aLabelCell = [[NSTextFieldCell alloc] initTextCell:cellString];
      [aLabelCell setBordered:YES];
      [aLabelCell setAlignment:NSCenterTextAlignment];
      [aLabelCell setFont:theFont];
      [aLabelCell setControlSize:NSSmallControlSize];
      [mStationLabelCellArray addObject:aLabelCell];
      [aLabelCell release];
    }
    [self setNeedsDisplay:YES];
}

- (void) setSortedStationsArray:(NSArray*)inArray forLineup:(Z2ITLineup*)inLineup;
{
  [mCurrentLineup autorelease];
  mCurrentLineup = [inLineup retain];
  [mSortedStationsArray autorelease];
  mSortedStationsArray = [inArray retain];
  [self updateCellLabels];
}

- (unsigned) numberStationsDisplayed
{
  // Return a float since we may have part of a stations displayed
  int numStations = [self frame].size.height / kScheduleStationColumnViewCellHeight;
  return numStations;
}

- (void) setStartStationIndex:(unsigned)inIndex
{
  mStartStationIndex = inIndex;
  [self setNeedsDisplay:YES];
}


@end
