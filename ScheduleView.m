//
//  ScheduleView.m
//  recsched
//
//  Created by Andrew Kimpton on 1/26/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleView.h"


@implementation ScheduleView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    [[NSColor redColor] set];
    [NSBezierPath strokeLineFromPoint:[self bounds].origin toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y + [self bounds].size.height)];
    [NSBezierPath strokeLineFromPoint:NSMakePoint([self bounds].origin.x, [self bounds].origin.y + [self bounds].size.height) toPoint:NSMakePoint([self bounds].origin.x + [self bounds].size.width,[self bounds].origin.y)];
}

@end
