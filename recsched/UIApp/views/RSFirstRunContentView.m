//
//  RSFirstRunContentView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSFirstRunContentView.h"


@implementation RSFirstRunContentView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
  }
  return self;
}

- (void)drawRect:(NSRect)rect {
  // Drawing code here.
  NSImage *bkgdImage = [NSImage imageNamed:@"assistantBackground.tiff"];
  [bkgdImage drawAtPoint:NSMakePoint(0, 0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0f];
}

@end
