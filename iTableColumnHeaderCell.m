//
//  iTableColumnHeaderCell.m
//  iTableColumnHeader
//
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>
//

#import "iTableColumnHeaderCell.h"
#import "CTGradient.h"

@implementation iTableColumnHeaderCell


- (id)initTextCell:(NSString *)text
{
    if (self = [super initTextCell:text]) {
        attrs = [[NSMutableDictionary dictionaryWithDictionary:
                                        [[self attributedStringValue] 
                                                    attributesAtIndex:0 
                                                    effectiveRange:NULL]] 
                                                        mutableCopy];
        return self;
    }
    return nil;
}


- (void)dealloc
{
    [attrs release];
    [super dealloc];
}


- (void)drawWithFrame:(NSRect)inFrame inView:(NSView*)inView
{
	CTGradient *headerGradient;
	if ([inView isFlipped])
		headerGradient = [CTGradient gradientWithBeginningColor:[NSColor colorWithDeviceHue:0.0 saturation:0.0 brightness:0.9137 alpha:1.0] endingColor:[NSColor colorWithDeviceHue:1.0 saturation:0.0071 brightness:0.5490 alpha:1.0]];
	else
		headerGradient = [CTGradient gradientWithBeginningColor:[NSColor colorWithDeviceHue:1.0 saturation:0.0071 brightness:0.5490 alpha:1.0] endingColor:[NSColor colorWithDeviceHue:0.0 saturation:0.0 brightness:0.9137 alpha:1.0]];

	[headerGradient fillRect:inFrame angle:90.0];

    /* Draw white text centered, but offset down-left. */
    float offset = 0.5;
    [attrs setValue:[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] 
             forKey:@"NSColor"];
    
    NSRect centeredRect = inFrame;
    centeredRect.size = [[self stringValue] sizeWithAttributes:attrs];
    centeredRect.origin.x += 
        ((inFrame.size.width - centeredRect.size.width) / 2.0) - offset;
    centeredRect.origin.y = 
        ((inFrame.size.height - centeredRect.size.height) / 2.0) + offset;
    [[self stringValue] drawInRect:centeredRect withAttributes:attrs];
    
    /* Draw black text centered. */
    [attrs setValue:[NSColor blackColor] forKey:@"NSColor"];
    centeredRect.origin.x += offset;
    centeredRect.origin.y -= offset;
    [[self stringValue] drawInRect:centeredRect withAttributes:attrs];

// Draw the column divider.
   [[NSColor darkGrayColor] set];
    NSRect dividerRect = NSMakeRect(inFrame.origin.x + inFrame.size.width - 1, 0, 1,inFrame.size.height);
   NSRectFill(dividerRect);}


- (id)copyWithZone:(NSZone *)zone
{
    id newCopy = [super copyWithZone:zone];
    [attrs retain];
    return newCopy;
}


@end
