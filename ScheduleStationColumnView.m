//
//  ScheduleStationColumnView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleStationColumnView.h"
#import "ScheduleViewController.h"
#import "Z2ITStation.h"
#import "Z2ITLineupMap.h"
#import "Z2ITLineup.h"

const int kScheduleStationColumnViewDefaultNumberOfCells = 200;
const int kScheduleStationColumnViewWidth = 95;
const int kScheduleStationColumnViewCellHeight = 40;

@interface ScheduleStationColumnCell : NSTextFieldCell {
}

+ (NSGradient*) sharedGradient;

@end

@implementation ScheduleStationColumnCell

static NSGradient *sScheduleStationColumnCellSharedGradient = nil;

+ (NSGradient*) sharedGradient
{
	if (!sScheduleStationColumnCellSharedGradient)
	{
		sScheduleStationColumnCellSharedGradient = [NSGradient alloc];
	}
	return sScheduleStationColumnCellSharedGradient;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	// Fill with the dark gray gradient
	NSGradient *aGradient = [[ScheduleStationColumnCell sharedGradient] initWithStartingColor:[NSColor colorWithDeviceHue:0 saturation:0 brightness:0.3922 alpha:1.0] endingColor:[NSColor colorWithDeviceHue:0 saturation:0 brightness:0.4980 alpha:1.0]];
	[aGradient drawInRect:cellFrame angle:90.0];
	
	// Draw the frame
	[[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0.65] set];
	[NSBezierPath strokeRect:cellFrame];
	
	// Draw the label string
	NSMutableParagraphStyle *paraInfo = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paraInfo  setAlignment:[self alignment]];
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[self textColor], NSForegroundColorAttributeName, paraInfo, NSParagraphStyleAttributeName, nil];
	[paraInfo release];
	NSRect stringBounds = [[self stringValue] boundingRectWithSize:cellFrame.size options:0 attributes:stringAttributes];
	stringBounds.origin.y = cellFrame.origin.y + ((cellFrame.size.height - stringBounds.size.height)/2);
	stringBounds.size.width = cellFrame.size.width;
	[[self stringValue] drawInRect:stringBounds withAttributes:stringAttributes];
	
	// Draw the top highlight
	NSPoint topHighlightLeft = cellFrame.origin;
	topHighlightLeft.y = (cellFrame.origin.y + cellFrame.size.height - 2.0) + 0.5;
	topHighlightLeft.x = cellFrame.origin.x+1;
	NSPoint topHighlightRight = topHighlightLeft;
	topHighlightRight.x = topHighlightLeft.x + cellFrame.size.width-2;
	[[NSColor colorWithDeviceRed:0.7176 green:0.7176 blue:0.7176 alpha:1.0] set];
	[NSBezierPath strokeLineFromPoint:topHighlightLeft toPoint:topHighlightRight];
	[[NSColor colorWithDeviceRed:0.498 green:0.498 blue:0.498 alpha:1.0] set];
	topHighlightLeft.y--; topHighlightRight.y--;
	[NSBezierPath strokeLineFromPoint:topHighlightLeft toPoint:topHighlightRight];
}

@end

@implementation ScheduleStationColumnView

+ (int) columnWidth
{
  return kScheduleStationColumnViewWidth;
}

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
}
 
- (void)drawRect:(NSRect)rect {
	// Draw the content cells
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
    
    for (Z2ITStation *aStation in mSortedStationsArray)
    {
      Z2ITLineupMap *aLineupMap = [aStation lineupMapForLineupID:[mCurrentLineup lineupID]];
      NSString *cellString = [NSString stringWithFormat:@"%@ - %@", [aLineupMap channel], [aStation valueForKey:@"callSign"]];
      ScheduleStationColumnCell *aLabelCell = [[ScheduleStationColumnCell alloc] initTextCell:cellString];
//      [aLabelCell setBordered:YES];
      [aLabelCell setAlignment:NSCenterTextAlignment];
      [aLabelCell setFont:theFont];
      [aLabelCell setControlSize:NSSmallControlSize];
	  [aLabelCell setTextColor:[NSColor whiteColor]];
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

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint eventLocation = [theEvent locationInWindow];
  NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
  NSRect cellFrameRect;
  cellFrameRect.origin.x = 0;
  cellFrameRect.origin.y = [self bounds].size.height;
  cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
  cellFrameRect.size.width = [self bounds].size.width;
  
  if ([self acceptsFirstResponder])
    [[self window] makeFirstResponder:self];
  
  int scheduleGridLineIndex = ([self frame].size.height - localPoint.y) / kScheduleStationColumnViewCellHeight;
  Z2ITStation *selectedStation = [mSortedStationsArray objectAtIndex:scheduleGridLineIndex+mStartStationIndex];
  if ([self delegate] && ([[self delegate] respondsToSelector:@selector(setCurrentStation:)]))
  {
    [[self delegate] setCurrentStation:selectedStation];
  }
}

- (NSMenu*) menuForEvent:(NSEvent*) theEvent
{
	NSMenu *theMenu = [self menu];
	
	// Handle the mouse down to select a cell.
	[self mouseDown:theEvent];
	return theMenu;
}



@synthesize mStartStationIndex;
@end
