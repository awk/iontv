//
//  Z2ITScheduleExtras.m
//  recsched
//
//  Created by Andrew Kimpton on 3/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Z2ITScheduleExtras.h"


@implementation Z2ITScheduleExtras

- (NSImage *) tvRatingImage
{
  NSImage *image = nil;
  
  [NSImage imageNamed:[self tvRatingImageName]];
  if (image == nil)
  {
    NSLog(@"tvRatingImage no image for %@", [self tvRatingImageName]);
  }
  return image;
}

@end
