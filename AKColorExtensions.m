//
//  AKColorExtensions.m
//  recsched
//
//  Created by Andrew Kimpton on 7/31/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AKColorExtensions.h"

void AdjustColorLightness(float *red, float *green, float *blue, float inLuma)
{
	float luma = inLuma;
	
	if (luma < -1)
		luma = -1;
	if (luma > 1)
		luma = 1;
		
	// Lightness algorithm
	// if luma < 0, use (1 + luma) * channel
	// if luma > 0 use 1 - (1 - luma) * (1 - channel)
	if (luma < 0)
	{
		(*red) = (1.0 + luma) * (*red);
		(*green) = (1.0 + luma) * (*green);
		(*blue) = (1.0 + luma) * (*blue);
	}
	else if (luma > 0)
	{
		(*red) = 1.0 - (1.0 - luma) * (1.0 - (*red));
		(*green) = 1.0 - (1.0 - luma) * (1.0 - (*green));
		(*blue) = 1.0 - (1.0 - luma) * (1.0 - (*blue));
	}
}

@implementation NSColor (AKColorExtensions)

- (NSColor*) darkerColorBy:(float)darkerAmount
{
	CGFloat r, g, b, a;
	r = [self redComponent];
	g = [self greenComponent];
	b = [self blueComponent];
	a = [self alphaComponent];
	AdjustColorLightness(&r,&g, &b, 0.0-darkerAmount);
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}

- (NSColor*) lighterColorBy:(float)lighterAmount
{
	CGFloat r, g, b, a;
	r = [self redComponent];
	g = [self greenComponent];
	b = [self blueComponent];
	a = [self alphaComponent];
	AdjustColorLightness(&r,&g, &b, 0.0+lighterAmount);
	return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}


@end
