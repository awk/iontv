//
//  JKSourceTableColumnHeaderCell.m
//  recsched
//
//  Created by Andrew Kimpton on 6/7/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKSourceTableColumnHeaderCell.h"


@implementation JKSourceTableColumnHeaderCell

- (id)initTextCell:(NSString *)text
{
    if (self = [super initTextCell:text]) 
    {

        return self;
    }
    return nil;
}


- (void)dealloc
{
    [super dealloc];
}


- (NSPoint) scalePoint:(NSPoint)inPoint withScaleFactor:(float)scaleFactor
{
  NSPoint scaledPoint = inPoint;
  
  if (scaleFactor != 1.0)
  {
      // Convert coordinates to device space units.
      scaledPoint.x *= scaleFactor;
      scaledPoint.y *= scaleFactor;
   
      // Normalize the point to integer pixel boundaries and then shift the origin by 0.5
      // to produce crisper lines.
      scaledPoint.x = floor(scaledPoint.x);
      scaledPoint.y = floor(scaledPoint.y);
      scaledPoint.x += 0.5;
      scaledPoint.y += 0.5;
   
      // Convert back to user space.
      scaledPoint.x /= scaleFactor;
      scaledPoint.y /= scaleFactor;
  }

  return scaledPoint;
}

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView*)inView
{
  [super drawWithFrame:inFrame inView:inView];
  
  // We draw three lines at the right hand of the header cell to indicate the 'thumb' that can be used to resize the
  // split view we're placed in.
  int i=0;
  NSPoint lineStart, lineEnd;
  
  // Lines start 10 pixels in from the end and have a gap of 3 pixels top/bottom.
  // Dark Color is 28% alpha black light color is 28% white
  lineStart.x = lineEnd.x = inFrame.origin.x + inFrame.size.width - 11;
  lineStart.y = inFrame.origin.y + 5;
  lineEnd.y = inFrame.origin.y + inFrame.size.height - 4;

  NSColor *dark = [[NSColor blackColor] colorWithAlphaComponent:0.45];
  NSColor *light= [[NSColor whiteColor] colorWithAlphaComponent:0.45];

  bool origAntiAliasState = [[NSGraphicsContext currentContext] shouldAntialias];
  [[NSGraphicsContext currentContext] setShouldAntialias:NO];
  
  [NSBezierPath setDefaultLineWidth:1.0];
  float scaleFactor = [[NSScreen mainScreen] userSpaceScaleFactor];
 
  for (i=0; i < 3; i++)
  {
    NSPoint scaledLineStart, scaledLineEnd;
    scaledLineStart = [self scalePoint:lineStart withScaleFactor:scaleFactor];
    scaledLineEnd = [self scalePoint:lineEnd withScaleFactor:scaleFactor];
    
    [dark setStroke];
    [NSBezierPath strokeLineFromPoint:scaledLineStart toPoint:scaledLineEnd];
    lineStart.x++; lineEnd.x++;
    scaledLineStart = [self scalePoint:lineStart withScaleFactor:scaleFactor];
    scaledLineEnd = [self scalePoint:lineEnd withScaleFactor:scaleFactor];
    [light setStroke];
    [NSBezierPath strokeLineFromPoint:scaledLineStart toPoint:scaledLineEnd];
    lineStart.x += 2;
    lineEnd.x += 2;
  }
  [[NSGraphicsContext currentContext] setShouldAntialias:origAntiAliasState];
}

@end
