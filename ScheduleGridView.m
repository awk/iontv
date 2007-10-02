//
//  ScheduleGridView.m
//  recsched
//
//  Created by Andrew Kimpton on 2/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AKColorExtensions.h"
#import "MainWindowController.h"
#import "ScheduleViewController.h"
#import "ScheduleGridView.h"
#import "ScheduleStationColumnView.h"
#import "ScheduleViewController.h"
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
- (Z2ITStation*) station;
- (void) setStartTime:(CFAbsoluteTime)inDate andDuration:(float)inMinutes;
- (void) drawCellsWithFrame:(NSRect) inFrame inView:(NSView *)inView;
- (void) mouseDown:(NSEvent *)theEvent withFrame:(NSRect)inFrame;
- (NSCell*) cellForSchedule:(Z2ITSchedule*)inSchedule;
@end

@interface ScheduleCell : NSTextFieldCell
{
}

+ (NSGradient *)sharedGradient;

@end

@implementation ScheduleGridView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        int numStationsInView = frame.size.height / kScheduleStationColumnViewCellHeight;
        mStationsInViewArray = [[NSMutableArray alloc] initWithCapacity:numStationsInView];
        mStartStationIndex = 0;
        mStartTime = CFAbsoluteTimeGetCurrent();

        [[NSNotificationCenter defaultCenter]  addObserver: self
          selector: @selector(frameDidChange:)
          name: NSViewFrameDidChangeNotification
          object: self];
    }
    return self;
}

- (void) dealloc 
{
  [delegate release];
  [mSelectedSchedule release];
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
 
- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) isFlipped
{
	// We need to be flipped in order for the layout manager to draw text correctly
	return YES;
}

- (void)drawRect:(NSRect)rect 
{
    NSRect cellFrameRect;
    cellFrameRect.origin.x = 0;
    cellFrameRect.origin.y = ([mStationsInViewArray count]-1) * kScheduleStationColumnViewCellHeight;
    cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
    cellFrameRect.size.width = [self bounds].size.width;

	// We draw from the bottom up so that the shadow below the selected cell is not 'covered' by the 
	// cell contents drawn beneath it.
    int i=0;
    for (i = [mStationsInViewArray count]-1; i >= 0; i--)
    {
      ScheduleGridLine *aGridLine = [mStationsInViewArray objectAtIndex:i];
      if (aGridLine)
      {
		[[NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0] setFill];
		NSRectFill(cellFrameRect);

        [aGridLine drawCellsWithFrame:cellFrameRect inView:self];

        cellFrameRect.origin.y -= kScheduleStationColumnViewCellHeight;
      }
    }
	
    // Draw a shadow down the left edge to look as though it was 'cast' by the station column
	if ([mStationsInViewArray count] > 0)
	{
		[NSGraphicsContext saveGraphicsState];
		NSShadow *aShadow = [[NSShadow alloc] init];
		[aShadow setShadowOffset:NSMakeSize(0.0, 0.0)];
		[aShadow setShadowBlurRadius:5.0f];
		[aShadow setShadowColor:[NSColor blackColor]];
		[aShadow set];

		[[NSColor blackColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x-0.5, [self bounds].origin.y) toPoint:NSMakePoint([self bounds].origin.x-0.5, [self bounds].origin.y + [self bounds].size.height)];
		[aShadow release];
		[NSGraphicsContext restoreGraphicsState];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
  NSPoint eventLocation = [theEvent locationInWindow];
  NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
  NSRect cellFrameRect;
  cellFrameRect.origin.x = 0;
  cellFrameRect.origin.y = 0;
  cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
  cellFrameRect.size.width = [self bounds].size.width;
  
  if ([self acceptsFirstResponder])
    [[self window] makeFirstResponder:self];
  
  int scheduleGridLineIndex = localPoint.y / kScheduleStationColumnViewCellHeight;
  if (scheduleGridLineIndex < [mStationsInViewArray count])
	[[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] mouseDown:theEvent withFrame:cellFrameRect];
}

- (NSMenu*) menuForEvent:(NSEvent*) theEvent
{
	NSMenu *theMenu = [self menu];
	
	// Handle the mouse down to select a cell.
	[self mouseDown:theEvent];
	return theMenu;
}

- (void) updateStationsInViewArray
{
  // Update the stations in view array
  int i=0;
  [mStationsInViewArray removeAllObjects];
  
  int maxStationIndex = [mSortedStationsArray count];
  
  // We add one here to accomodate the potentially 'partial' display of the station at the bottom of the scroll area
  if (maxStationIndex > (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight)+1)
    maxStationIndex = (mStartStationIndex + [self frame].size.height/kScheduleStationColumnViewCellHeight)+1;
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
  [self setNeedsDisplay:YES];
}

- (void) setSelectedSchedule:(Z2ITSchedule*)inSchedule
{
  NSEnumerator *anEnumerator = [mStationsInViewArray objectEnumerator];
  ScheduleGridLine *aGridLine;
  while ((aGridLine = [anEnumerator nextObject]) != nil)
  {
    if ([aGridLine station] == [inSchedule station])
    {
      NSCell *aCell = [aGridLine cellForSchedule:inSchedule];
      [self setSelectedCell:aCell];
    }
  }
  [mSelectedSchedule autorelease];
  mSelectedSchedule = [inSchedule retain];
}

- (Z2ITSchedule*) selectedSchedule
{
  return mSelectedSchedule;
}

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule
{
  if (delegate && ([delegate respondsToSelector:@selector(setCurrentSchedule:)]))
  {
    [delegate setCurrentSchedule:inSchedule];
  }
  if (delegate && ([delegate respondsToSelector:@selector(setCurrentStation:)]))
  {
	[delegate setCurrentStation:[inSchedule station]];
  }
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
	mCellsInLineArray = nil;
  }
  return self;
}

- (void) setStation:(Z2ITStation*)inStation
{
  [mStation autorelease];
  mStation = [inStation retain];
}

- (Z2ITStation*)station
{
  return mStation;
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
    [aTextCell setRepresentedObject:[mSchedulesInLineArray objectAtIndex:i]];
    [aTextCell setStringValue:[[[mSchedulesInLineArray objectAtIndex:i] program] title]];
    if ([mGridView selectedSchedule] == [mSchedulesInLineArray objectAtIndex:i])
    {
      [mGridView setSelectedCell:aTextCell];
    }
    [mCellsInLineArray addObject:aTextCell];
    [aTextCell release];
  }
}

- (void) scheduleCellClicked:(id)sender
{
  NSLog(@"scheduleCellClicked - sender = %@", sender);
}

- (NSCell*) cellForSchedule:(Z2ITSchedule*)inSchedule
{
  NSCell *theCell = nil;
  NSEnumerator *anEnumerator = [mCellsInLineArray objectEnumerator];
  while ((theCell = [anEnumerator nextObject]) != nil)
  {
    if ([theCell representedObject] == inSchedule)
      break;
  }
  return theCell;
}

- (NSRect) cellFrameRectForSchedule:(Z2ITSchedule *)inSchedule withPixelsPerMinute:(float)pixelsPerMinute
{
  NSRect cellFrameRect;
  NSTimeInterval durationRemaining;
  NSTimeInterval offsetFromStart = [[inSchedule time] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime]];

	durationRemaining = [[inSchedule endTime] timeIntervalSinceDate:[inSchedule time]];
	cellFrameRect.origin.x = (offsetFromStart / 60.0) * pixelsPerMinute;

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
    [mGridView setCurrentSchedule:aSchedule];
    [mGridView setNeedsDisplay:YES];
  }
}

@end

@implementation ScheduleCell

static NSGradient *sScheduleCellSharedGradient = nil;

+ (NSGradient*) sharedGradient
{
	if (!sScheduleCellSharedGradient)
	{
		sScheduleCellSharedGradient = [NSGradient alloc];
	}
	return sScheduleCellSharedGradient;
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	if (cellFrame.origin.x < 0)
	{
		// Make sure the frame for the text is visible (but that the right end stays put)
		cellFrame.size.width += (cellFrame.origin.x-2.0);
		cellFrame.origin.x = 2;
	}
	
	if (cellFrame.size.width < 20)
		return;		// No point trying to draw in something so small
		
	NSRect textRect = NSInsetRect(cellFrame, 4, 2);
	
	NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:[self stringValue]] autorelease];
	NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize: textRect.size] autorelease];
	NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];

	[layoutManager setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];

	[textStorage addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textStorage length])];
	[textContainer setLineFragmentPadding:0.0];

	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	[controlView lockFocus];
	if ([self isHighlighted])
	{
		[textStorage setForegroundColor:[NSColor whiteColor]];
	}
	else
	{
		[textStorage setForegroundColor:[NSColor blackColor]];
	}
	
	[layoutManager drawGlyphsForGlyphRange: glyphRange atPoint: textRect.origin];
	[controlView unlockFocus];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect insetCellFrame = NSInsetRect(cellFrame, 2.0, 1.5);
	
	// Curved corners radius
	float radius = 8.0;
	NSBezierPath *framePath = nil;
	
	framePath = [NSBezierPath bezierPathWithRoundedRect:insetCellFrame xRadius:radius yRadius:radius];
	
	if (framePath)
	{
		// Fill the frame with our genre color
		NSColor *genreColor = nil;
		if ([self representedObject])
		{
			NSData *genreColorData = [[[[self representedObject] program] genreWithRelevance:0] valueForKeyPath:@"genreClass.color"];
			if (genreColorData)
				genreColor = [NSUnarchiver unarchiveObjectWithData:genreColorData];
			else
			{
				genreColor = [NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:1.0];
			}
		}

		if ([self isHighlighted])
		{
			NSColor *bottomColor;
			NSColor *topColor;
			if (![[controlView window] isKeyWindow])
			{
				bottomColor = [NSColor colorWithDeviceRed:138.0/255.0 green:138.0/255.0 blue:138.0/255.0 alpha:1.0];
				topColor = [NSColor colorWithDeviceRed:180.0/255.0 green:180.0/255.0 blue:180.0/255.0 alpha:1.0];
			}
			else if ([[controlView window] firstResponder] == controlView)
			{
				bottomColor = [NSColor colorWithDeviceRed:22.0/255.0 green:83.0/255.0 blue:170.0/255.0 alpha:1.0];
				topColor = [NSColor colorWithDeviceRed:92.0/255.0 green:147.0/255.0 blue:214.0/255.0 alpha:1.0];
			}
			else
			{
				bottomColor = [NSColor colorWithDeviceRed:111.0/255.0 green:130.0/255.0 blue:170.0/255.0 alpha:1.0];
				topColor = [NSColor colorWithDeviceRed:162.0/255.0 green:177.0/255.0 blue:208.0/255.0 alpha:1.0];
			}
			
	
			[NSGraphicsContext saveGraphicsState];
			NSShadow *aShadow = [[NSShadow alloc] init];
			[aShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
			[aShadow setShadowBlurRadius:5.0f];
			[aShadow setShadowColor:[NSColor blackColor]];
			[aShadow set];
			[bottomColor setFill];
			[framePath fill];
			[aShadow release];
			[NSGraphicsContext restoreGraphicsState];

  			NSGradient *aGradient = [[ScheduleCell sharedGradient] initWithStartingColor:topColor endingColor:bottomColor];
			[aGradient drawInBezierPath:framePath angle:90.0];
			
		}
		else
		{
			NSColor *bottomColor = [genreColor darkerColorBy:0.15];
			NSColor *topColor = [genreColor lighterColorBy:0.15];
			NSGradient *aGradient = [[ScheduleCell sharedGradient] initWithStartingColor:topColor endingColor:bottomColor];
			[aGradient drawInBezierPath:framePath angle:90.0];
			
			// Set the base genre color for the outline
			[[genreColor darkerColorBy:0.40] set];
			[framePath stroke];
		}

//		if ([self isHighlighted])
//		{
//			[[self highlightColorWithFrame:cellFrame inView:controlView] set];
//			[framePath setLineWidth:3];
//  		[framePath stroke];
//		}

	}
	
	[self drawInteriorWithFrame:insetCellFrame inView:controlView];
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  if ([[controlView window] firstResponder] == controlView)
    return [NSColor alternateSelectedControlColor];
  else
    return [NSColor lightGrayColor];
}

@end

