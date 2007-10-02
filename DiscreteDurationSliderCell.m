//
//  DiscreteDurationSliderCell.m
//  recsched
//
//  Created by Andrew Kimpton on 1/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DiscreteDurationSliderCell.h"
#import "DiscreteDurationSlider.h"


@implementation DiscreteDurationSliderCell

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
  if ([controlView class] == [DiscreteDurationSlider class])
  {
    [(DiscreteDurationSlider*)(controlView) hideDurationLabel:NO];
  }
  return [super startTrackingAt:startPoint inView:controlView];
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
  if ([controlView class] == [DiscreteDurationSlider class])
  {
    [(DiscreteDurationSlider*)(controlView) hideDurationLabel:YES];
  }
  [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];
}

- (void) setFloatValue:(float)aFloat
{
  NSLog(@"setFloatValue - %.2f", aFloat);
}
@end
