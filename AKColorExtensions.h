//
//  AKColorExtensions.h
//  recsched
//
//  Created by Andrew Kimpton on 7/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (AKColorExtensions)

- (NSColor*) darkerColorBy:(float)darkerAmount;
- (NSColor*) lighterColorBy:(float)lighterAmount;

@end
