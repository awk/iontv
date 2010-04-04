//  Copyright (c) 2007, Andrew Kimpton
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "AKColorExtensions.h"

void AdjustColorLightness(CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat inLuma)
{
  CGFloat luma = inLuma;

  if (luma < -1) {
    luma = -1;
  }
  if (luma > 1) {
    luma = 1;
  }
  // Lightness algorithm
  // if luma < 0, use (1 + luma) * channel
  // if luma > 0 use 1 - (1 - luma) * (1 - channel)
  if (luma < 0) {
    (*red) = (1.0 + luma) * (*red);
    (*green) = (1.0 + luma) * (*green);
    (*blue) = (1.0 + luma) * (*blue);
  } else if (luma > 0) {
    (*red) = 1.0 - (1.0 - luma) * (1.0 - (*red));
    (*green) = 1.0 - (1.0 - luma) * (1.0 - (*green));
    (*blue) = 1.0 - (1.0 - luma) * (1.0 - (*blue));
  }
}

@implementation NSColor (AKColorExtensions)

- (NSColor *)darkerColorBy:(float)darkerAmount {
  CGFloat r, g, b, a;
  r = [self redComponent];
  g = [self greenComponent];
  b = [self blueComponent];
  a = [self alphaComponent];
  AdjustColorLightness(&r,&g, &b, 0.0-darkerAmount);
  return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}

- (NSColor *)lighterColorBy:(float)lighterAmount {
  CGFloat r, g, b, a;
  r = [self redComponent];
  g = [self greenComponent];
  b = [self blueComponent];
  a = [self alphaComponent];
  AdjustColorLightness(&r,&g, &b, 0.0+lighterAmount);
  return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
}


@end
