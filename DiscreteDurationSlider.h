//
//  DiscreteDurationSlider.h
//  recsched
//
//  Created by Andrew Kimpton on 1/30/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscreteDurationSlider : NSSlider {
  IBOutlet NSTextField *mDurationField;
}

- (void) hideDurationLabel:(BOOL)inHidden;

@end
