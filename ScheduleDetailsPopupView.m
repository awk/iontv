//
//  ScheduleDetailsPopupView.m
//  recsched
//
//  Created by Andrew Kimpton on 9/3/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleDetailsPopupView.h"
#import "AKColorExtensions.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"

const float kScheduleDetailsPopupWidthPadding = 15.0;
const float kScheduleDetailsPopupHeightPadding = 15.0;

@implementation ScheduleDetailsPopupView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self)
	{
		mCloseBoxImage = [NSImage imageNamed:@"closebox.png"];
		mCloseBoxPressedImage = [NSImage imageNamed:@"closebox_pressed.png"];
		mMouseInCloseBox = NO;
		
		[self setWantsLayer:YES];		// Turn on CoreAnimation for this view (and subviews too).
    }
    return self;
}

- (void) awakeFromNib
{
	// We need to no when the selected schedule changes so we can update
	[mCurrentSchedule addObserver:self forKeyPath:@"content" options:0 context:nil];
}

- (NSRect) closeBoxRect
{
	NSRect insetFrame = NSInsetRect([self frame], kScheduleDetailsPopupWidthPadding + 2.0, kScheduleDetailsPopupHeightPadding + 1.5);

	NSRect closeBoxRect;
	closeBoxRect.size = [mCloseBoxImage size];
	closeBoxRect.origin.x = insetFrame.origin.x - 15;
	closeBoxRect.origin.y = insetFrame.origin.y + insetFrame.size.height - 17;
	return closeBoxRect;
}

- (void)drawRect:(NSRect)rect
{
	NSRect insetFrame = NSInsetRect([self frame], kScheduleDetailsPopupWidthPadding + 2.0, kScheduleDetailsPopupHeightPadding + 1.5);
	
	// Curved corners radius
	float radius = 8.0;
	NSBezierPath *framePath = nil;
	
	framePath = [NSBezierPath bezierPathWithRoundedRect:insetFrame xRadius:radius yRadius:radius];
	
	if (framePath)
	{
		// Fill the frame with our genre color
		NSColor *genreColor = nil;
		if ([mCurrentSchedule content])
		{
			NSData *genreColorData = [[[[mCurrentSchedule content] program] genreWithRelevance:0] valueForKeyPath:@"genreClass.color"];
			if (genreColorData)
				genreColor = [NSUnarchiver unarchiveObjectWithData:genreColorData];
			else
			{
				genreColor = [NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:1.0];
			}
		}

		NSColor *bottomColor = [genreColor darkerColorBy:0.15];
		NSColor *topColor = [genreColor lighterColorBy:0.15];

		[NSGraphicsContext saveGraphicsState];
		NSShadow *aShadow = [[NSShadow alloc] init];
		[aShadow setShadowOffset:NSMakeSize(4.0, -7.0)];
		[aShadow setShadowBlurRadius:14.0f];
		[aShadow setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.75]];
		[aShadow set];
		[bottomColor setFill];
		[framePath fill];
		[aShadow release];
		[NSGraphicsContext restoreGraphicsState];

		NSGradient *aGradient = [[[NSGradient alloc] initWithStartingColor:bottomColor endingColor:topColor] autorelease];
		[aGradient drawInBezierPath:framePath angle:90.0];
		
		// Set the base genre color for the outline
		[[genreColor darkerColorBy:0.40] set];
		[framePath stroke];
	}
	
	// Draw the close box in the top right corner
	NSImage *theCloseBoxImage;
	if (mMouseInCloseBox)
		theCloseBoxImage = mCloseBoxPressedImage;
	else
		theCloseBoxImage = mCloseBoxImage;
		
	[theCloseBoxImage compositeToPoint:[self closeBoxRect].origin operation:NSCompositeSourceOver];
}

- (void) mouseDown:(NSEvent*) theEvent
{
  NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if ([self mouse:localPoint inRect:[self closeBoxRect]] == YES)
  {
	mMouseInCloseBox = YES;
	mTrackingCloseBox = YES;
	[self setNeedsDisplayInRect:[self closeBoxRect]];
  }
}

- (void) mouseDragged:(NSEvent*) theEvent
{
  NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if (mTrackingCloseBox)
  {
	mMouseInCloseBox = [self mouse:localPoint inRect:[self closeBoxRect]] == YES;
	[self setNeedsDisplayInRect:[self closeBoxRect]];
	return;
  }

  // Not tracking the close box so move the window
  NSPoint windowOrigin = [[self window] frame].origin;
  [[self window] setFrameOrigin:NSMakePoint(windowOrigin.x + [theEvent deltaX], windowOrigin.y - [theEvent deltaY])];
}

- (void) mouseUp:(NSEvent*) theEvent
{
  NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  if (mTrackingCloseBox && [self mouse:localPoint inRect:[self closeBoxRect]] == YES)
  {
		// Fade out the window on close
		[[[self window] animator] setAlphaValue:0.0];
	}
	mMouseInCloseBox = NO;
	mTrackingCloseBox = NO;
	[self setNeedsDisplayInRect:[self closeBoxRect]];
 }

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
    if ((object == mCurrentSchedule) && ([keyPath isEqual:@"content"]))
	{
		[self setNeedsDisplay:YES];
	}
}
@end
