//  Copyright (c) 2007, Andrew Kimpton
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "AKColorExtensions.h"
#import "MainWindowController.h"
#import "NSManagedObjectContextAdditions.h"
#import "RSNotifications.h"
#import "RSRecording.h"
#import "ScheduleViewController.h"
#import "ScheduleGridView.h"
#import "ScheduleStationColumnView.h"
#import "ScheduleViewController.h"
#import "Z2ITStation.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

const float kScheduleDetailsPopUpTime = 3.0;

@interface ScheduleGridView(Private)
- (BOOL) scheduleIsVisible:(Z2ITSchedule*)inSchedule;
@end

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
- (Z2ITSchedule*) scheduleAtLocation:(NSPoint)localPoint withFrame:(NSRect)inFrame;
- (void) mouseDown:(NSEvent *)theEvent withFrame:(NSRect)inFrame;
- (NSRect) cellFrameRectForSchedule:(Z2ITSchedule *)inSchedule withPixelsPerMinute:(float)pixelsPerMinute;
- (NSCell*) cellForSchedule:(Z2ITSchedule*)inSchedule;
- (NSImage*) cellImageAtLocation:(NSPoint)localPoint withFrame:(NSRect) inFrame  inView:(NSView*)inView;
- (NSPoint) dragImageLocFor:(NSPoint)localPoint withFrame:(NSRect) inFrame;

@property (retain,getter=station) Z2ITStation    *mStation;
@end

@interface ScheduleCell : NSTextFieldCell
{
}

+ (NSGradient *)sharedGradient;

- (NSImage*) cellImageWithFrame:(NSRect)inFrame inView:(NSView*)inView;
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

    	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingAdded:) name:RSRecordingAddedNotification object:RSBackgroundApplication];
			[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingRemoved:) name:RSRecordingRemovedNotification object:RSBackgroundApplication];
		}
    return self;
}

- (void) dealloc 
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSRecordingAddedNotification object:RSBackgroundApplication];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSRecordingRemovedNotification object:RSBackgroundApplication];

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

- (void) restartPopupTimer
{
	if (mScheduleCellPopupTimer)
	{
		[mScheduleCellPopupTimer invalidate];
		mScheduleCellPopupTimer  = nil;
	}
	mScheduleCellPopupTimer = [NSTimer scheduledTimerWithTimeInterval:kScheduleDetailsPopUpTime target:self selector:@selector(showScheduleDetails:) userInfo:nil repeats:NO];
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
  {
	cellFrameRect.origin.y = kScheduleStationColumnViewCellHeight * scheduleGridLineIndex;
	[[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] mouseDown:theEvent withFrame:cellFrameRect];
  }
}

- (void) mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];
	NSRect cellFrameRect;
	NSImage *scheduleCellImage = nil;
	NSPoint dragImageLoc = NSMakePoint(0.0, 0.0);
	Z2ITSchedule* aSchedule = nil;
	Z2ITStation* theStation = nil;
	
	cellFrameRect.origin.x = 0;
	cellFrameRect.origin.y = 0;
	cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
	cellFrameRect.size.width = [self bounds].size.width;

	int scheduleGridLineIndex = localPoint.y / kScheduleStationColumnViewCellHeight;
	if (scheduleGridLineIndex < [mStationsInViewArray count])
	{
		cellFrameRect.origin.y = kScheduleStationColumnViewCellHeight * scheduleGridLineIndex;
		NSImage *anImage = [[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] cellImageAtLocation:localPoint withFrame:cellFrameRect inView:self];
		dragImageLoc = [[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] dragImageLocFor:localPoint withFrame:cellFrameRect];
		aSchedule = [[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] scheduleAtLocation:localPoint withFrame:cellFrameRect];
		theStation = [[mStationsInViewArray objectAtIndex:scheduleGridLineIndex] station];
		
		// Take the returned image and composite it into a new one with some transparency
		scheduleCellImage = [[NSImage alloc] initWithSize:[anImage size]];
		[scheduleCellImage lockFocus];
		[anImage compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver fraction:0.5];
		[scheduleCellImage unlockFocus];
	}
	
	if (aSchedule && theStation && scheduleCellImage)
	{
		NSDictionary *dragInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[[[aSchedule objectID] URIRepresentation] absoluteString], @"scheduleObjectURI",
			[[[theStation objectID] URIRepresentation] absoluteString], @"stationObjectURI",
			[[[mCurrentLineup objectID] URIRepresentation] absoluteString], @"currentLineupObjectURI",
			nil];
		
		NSPasteboard *pboard;
	 
		pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
		[pboard declareTypes:[NSArray arrayWithObject:RSSSchedulePBoardType]  owner:self];
		[pboard setPropertyList:dragInfoDict forType:RSSSchedulePBoardType];
	 
		[self dragImage:scheduleCellImage at:dragImageLoc offset:NSMakeSize(0, 0) event:theEvent pasteboard:pboard source:self slideBack:YES];
	}
    return;
}

- (void) mouseEntered:(NSEvent*) theEvent
{
	[self restartPopupTimer];
}

- (void) mouseExited:(NSEvent*) theEvent
{
//	NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (mScheduleCellPopupTimer)
	{
		[mScheduleCellPopupTimer invalidate];
		mScheduleCellPopupTimer  = nil;
	}
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
    for (ScheduleGridLine *aGridLine in mStationsInViewArray)
    {
      [aGridLine setStartTime:mStartTime andDuration:mVisibleTimeSpan];
    }
    [self setNeedsDisplay:YES];
}

- (void) updateSelectedScheduleCellTrackingArea
{
	// Remove any current tracking area
	if (mScheduleCellTrackingArea)
	{
		[self removeTrackingArea:mScheduleCellTrackingArea];
		[mScheduleCellTrackingArea release];
		mScheduleCellTrackingArea = nil;
	}
	
	// start tracking the mouse in the cell area - we use this to popup the larger program details window
	int gridLineIndex = 0;
	for (ScheduleGridLine *aGridLine in mStationsInViewArray)
	{
		if ([aGridLine station] == [mSelectedSchedule station])
		{
			float pixelsPerMinute = [self frame].size.width / mVisibleTimeSpan ;
			NSRect cellRect = [aGridLine cellFrameRectForSchedule:mSelectedSchedule withPixelsPerMinute:pixelsPerMinute];
			cellRect.origin.y = gridLineIndex * kScheduleStationColumnViewCellHeight;
			mScheduleCellTrackingArea = [[NSTrackingArea alloc] initWithRect:cellRect 
				options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow)
				 owner:self userInfo:nil];
			[self addTrackingArea:mScheduleCellTrackingArea];
			[self restartPopupTimer];
			break;
		}
		gridLineIndex++;
	}
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
  [self updateSelectedScheduleCellTrackingArea];
}

- (void) setStartTime:(CFAbsoluteTime)inStartTime
{
  mStartTime = inStartTime;
  [self updateForNewStartTime];
  [self updateSelectedScheduleCellTrackingArea];
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
  for (ScheduleGridLine *aGridLine in mStationsInViewArray)
  {
    if ([aGridLine station] == [inSchedule station])
    {
      NSCell *aCell = [aGridLine cellForSchedule:inSchedule];
      [self setSelectedCell:aCell];
	  break;
    }
  }
  [mSelectedSchedule autorelease];
  mSelectedSchedule = [inSchedule retain];
  [self updateSelectedScheduleCellTrackingArea];
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

- (void)updateTrackingAreas
{
	[self updateSelectedScheduleCellTrackingArea];
}

- (void) showScheduleDetails:(NSTimer*) theTimer
{
	[mScheduleCellPopupTimer invalidate];
	mScheduleCellPopupTimer = nil;
	// Is the mouse inside the tracking area ? Only show the schedule details popup if it is
	NSPoint mousePoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
	if ([self mouse:mousePoint inRect:[mScheduleCellTrackingArea rect]])
	{
		if (delegate && ([delegate respondsToSelector:@selector(showScheduleDetailsWithStartingFrame:)]))
		{
			NSRect frameInScreenCoords = [self convertRect:[mScheduleCellTrackingArea rect] toView:nil];
			frameInScreenCoords.origin = [[self window] convertBaseToScreen:frameInScreenCoords.origin];
			[delegate showScheduleDetailsWithStartingFrame:frameInScreenCoords];
		}
	}
}

#pragma mark Drag and Drop

- (NSDragOperation)draggingSourceOperationMask
{
	return NSDragOperationGeneric;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	// No copy/link semantics when dragging
	return YES;
}

#pragma mark View Notifications

- (void)frameDidChange: (NSNotification *)notification
{
  [self updateStationsInViewArray];
  [self updateForNewStartTime];
}

- (void)recordingAdded: (NSNotification *)notification
{
  NSArray *newRecordings = [[notification userInfo] valueForKey:RSRecordingAddedRecordingsURIKey];
  for (NSString *newRecordingURIString in newRecordings)
  {
    NSURL *newRecordingURI = [NSURL URLWithString:newRecordingURIString];
    NSManagedObjectID *newRecordingID = [[[NSApp delegate] persistentStoreCoordinator] managedObjectIDForURIRepresentation:newRecordingURI];
    RSRecording *newRecording = (RSRecording *) [[[NSApp delegate] managedObjectContext] objectWithID:newRecordingID];
    if ([self scheduleIsVisible:newRecording.schedule])
    {
      [[[NSApp delegate] managedObjectContext] refreshObjectWithoutCache:newRecording.schedule mergeChanges:YES];
      [self setNeedsDisplay:YES];
    }
  }
}

- (void)recordingRemoved: (NSNotification *)notification
{
	NSURL *removedRecordingOfScheduleURI = [NSURL URLWithString:[[notification userInfo] valueForKey:RSRecordingRemovedRecordingOfScheduleURIKey]];
	NSManagedObjectID *removedRecordingOfScheduleID = [[[NSApp delegate] persistentStoreCoordinator] managedObjectIDForURIRepresentation:removedRecordingOfScheduleURI];
	Z2ITSchedule *removedRecordingOfSchedule = (Z2ITSchedule *) [[[NSApp delegate] managedObjectContext] objectWithID:removedRecordingOfScheduleID];
	if ([self scheduleIsVisible:removedRecordingOfSchedule])
	{
		[[[NSApp delegate] managedObjectContext] refreshObjectWithoutCache:removedRecordingOfSchedule mergeChanges:YES];
		[self setNeedsDisplay:YES];
	}
}

@synthesize mStartTime;
@synthesize mVisibleTimeSpan;
@synthesize mStartStationIndex;
@synthesize mSelectedSchedule;
@end

@implementation ScheduleGridView(Private)

- (BOOL) scheduleIsVisible:(Z2ITSchedule*)inSchedule
{
	BOOL isVisible = NO;
	
	NSDate *gridStartDate = [NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime];
	NSDate *gridEndDate = [NSDate dateWithTimeIntervalSinceReferenceDate:mStartTime+mVisibleTimeSpan];
	// Schedule starts between grid start and end times
	if (([gridStartDate compare:inSchedule.time] == NSOrderedAscending) && ([inSchedule.time compare:gridEndDate] == NSOrderedDescending))
	{
		isVisible = YES;
	}
	
	// Schedule ends between grid start and end times
	if (([gridStartDate compare:inSchedule.endTime] == NSOrderedAscending) && ([inSchedule.endTime compare:gridEndDate] == NSOrderedDescending))
	{
		isVisible = YES;
	}
	
	if (isVisible)
	{
		for (ScheduleGridLine *aGridLine in mStationsInViewArray)
		{
			if ([aGridLine station] == [inSchedule station])
			{
				isVisible = YES;
				break;
			}
		}
	}
	return isVisible;
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

  for (id loopItem in mSchedulesInLineArray)
  {
    ScheduleCell *aTextCell = [[ScheduleCell alloc] initTextCell:@"--"];
    [aTextCell setBordered:YES];
    [aTextCell setRepresentedObject:loopItem];
    [aTextCell setStringValue:[[loopItem program] title]];
    if ([mGridView selectedSchedule] == loopItem)
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
  for (theCell in mCellsInLineArray)
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
  cellFrameRect.size.height = kScheduleStationColumnViewCellHeight;
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

- (Z2ITSchedule*) scheduleAtLocation:(NSPoint)localPoint withFrame:(NSRect)inFrame
{
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
        }
      }
  }
  if (foundCell)
	return aSchedule;
  else
	return nil;
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

- (NSImage*) cellImageAtLocation:(NSPoint)localPoint withFrame:(NSRect) inFrame inView:(NSView*)inView
{
  // Calculate the pixels per minute value
  float pixelsPerMinute = inFrame.size.width / ((mEndTime - mStartTime) / 60);

  NSImage *cellImage = nil;
  
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
          cellImage  = [[mCellsInLineArray objectAtIndex:i] cellImageWithFrame:aCellFrameRect inView:inView];
        }
      }
  }
  return cellImage;
}

- (NSPoint) dragImageLocFor:(NSPoint)localPoint withFrame:(NSRect) inFrame
{
  // Calculate the pixels per minute value
  float pixelsPerMinute = inFrame.size.width / ((mEndTime - mStartTime) / 60);

  NSPoint dragImageLoc = NSMakePoint(0.0, 0.0);
  
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
		aCellFrameRect.origin.y = inFrame.origin.y + aCellFrameRect.size.height;
		NSRect hitRect = aCellFrameRect;
		hitRect.origin.y = 0;
        hitRect.size.height = kScheduleStationColumnViewCellHeight;
        // We always make the click to be in the middle of the cell vertically
		localPoint.y = kScheduleStationColumnViewCellHeight / 2;
        if (NSPointInRect(localPoint, hitRect))
        {
          foundCell = YES;
	      dragImageLoc.x = aCellFrameRect.origin.x;
	      dragImageLoc.y = aCellFrameRect.origin.y;
        }
      }
  }
  return dragImageLoc;
}

@synthesize mStation;
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

	[layoutManager setTypesetterBehavior:NSTypesetterLatestBehavior /*NSTypesetterBehavior_10_2_WithCompatibility*/];
	[layoutManager addTextContainer:textContainer];
	[textStorage addLayoutManager:layoutManager];

	[textStorage addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, [textStorage length])];
	[textContainer setLineFragmentPadding:0.0];

	NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	if ([self isHighlighted])
	{
		[textStorage setForegroundColor:[NSColor whiteColor]];
	}
	else
	{
		[textStorage setForegroundColor:[NSColor blackColor]];
	}
	
        Z2ITSchedule *aSchedule = [self representedObject];
        if (aSchedule.recording != nil)
        {
          // Draw a small red dot inset from the bottom corner of the schedule rect to indicate that this program
          // has or will be recorded.
          NSRect recordingRectBounds = NSMakeRect(0, 0, 7, 7);
          recordingRectBounds.origin.x = NSMaxX(textRect) - recordingRectBounds.size.width - 3;
          recordingRectBounds.origin.y = NSMaxY(textRect) - recordingRectBounds.size.height - 3;
          NSBezierPath *recordingDot = [NSBezierPath bezierPathWithOvalInRect:recordingRectBounds];
          [NSGraphicsContext saveGraphicsState];
          NSShadow *aShadow = [[NSShadow alloc] init];
          [aShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
          [aShadow setShadowBlurRadius:3.0f];
          [aShadow setShadowColor:[NSColor blackColor]];
          [aShadow set];
          [[NSColor redColor] set];
          [recordingDot fill];
          [aShadow release];
          [NSGraphicsContext restoreGraphicsState];
        }
	[layoutManager drawGlyphsForGlyphRange: glyphRange atPoint: textRect.origin];
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

- (NSImage*) cellImageWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	// Draw with a zero, zero origin.
	cellFrame.origin.x = cellFrame.origin.y = 0;
	
	// Turn off 'highlight' state (if true)
	BOOL currentHighlight = [self isHighlighted];
	[self setHighlighted:NO];
	
	NSImage* anImage = [[[NSImage alloc] initWithSize:cellFrame.size] autorelease];
	// Flip origin (for Text drawing ?)
	[anImage setFlipped:YES];
	[anImage lockFocus];

	[self drawWithFrame:cellFrame inView:controlView];
	
	[anImage unlockFocus];

	// Restore flip ?
	[anImage setFlipped:NO];
	
	// Restore highlight state
	[self setHighlighted:currentHighlight];
	
	return anImage;
}

@end

