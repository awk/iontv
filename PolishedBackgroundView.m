//
//  PolishedBackgroundView.m
//  recsched
//
//  Created by Andrew Kimpton on 5/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PolishedBackgroundView.h"


const float kBackgroundViewGreyShade = 0.902;

@implementation PolishedBackgroundView

- (void)drawRect:(NSRect)aRect
{
  [[NSColor colorWithDeviceRed:kBackgroundViewGreyShade green:kBackgroundViewGreyShade blue:kBackgroundViewGreyShade alpha:1.0] set];
  NSRectFill(aRect);
}

- (BOOL)isOpaque
{
  return YES;
}

@end
