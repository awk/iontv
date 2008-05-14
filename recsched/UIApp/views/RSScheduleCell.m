//
//  RSScheduleCell.m
//  recsched
//
//  Created by Andrew Kimpton on 5/14/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AKColorExtensions.h"
#import "RSScheduleCell.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

@implementation RSScheduleCell

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

  			NSGradient *aGradient = [[RSScheduleCell sharedGradient] initWithStartingColor:topColor endingColor:bottomColor];
			[aGradient drawInBezierPath:framePath angle:90.0];
			
		}
		else
		{
			NSColor *bottomColor = [genreColor darkerColorBy:0.15];
			NSColor *topColor = [genreColor lighterColorBy:0.15];
			NSGradient *aGradient = [[RSScheduleCell sharedGradient] initWithStartingColor:topColor endingColor:bottomColor];
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

