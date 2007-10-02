//
//  DiscreteDurationSlider.m
//  recsched
//
//  Created by Andrew Kimpton on 1/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DiscreteDurationSlider.h"
#import "DiscreteDurationSliderCell.h"


@implementation DiscreteDurationSlider


+ (Class)cellClass
{
	return [DiscreteDurationSliderCell class];
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    [super drawRect:rect];
}

- (void) hideDurationLabel:(BOOL)inHidden
{
  [mDurationField setHidden:inHidden];
}

@end
