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


#import "RSProgramSearchTableHeaderView.h"


@implementation RSProgramSearchTableHeaderView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
  }
  return self;
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
  NSMenu *theMenu = nil;
  if ([delegate respondsToSelector:@selector(tableHeaderView: menuForEvent:)]) {
    theMenu = [delegate tableHeaderView:self menuForEvent:theEvent];
  } else {
    theMenu = [[self class] defaultMenu];
  }
  return theMenu;
}

// Override respondsToSelector so that the contextual menu actions are enabled (if the delegate supports them)
- (BOOL)respondsToSelector:(SEL)aSelector {
  if ([super respondsToSelector:aSelector]) {
    return YES;
  } else {
    if ([delegate respondsToSelector:aSelector]) {
      return YES;
    }
  }
  return NO;
}

// We forward most everything to our delegate if we can - especially the action messages from the contextual menu
- (void)forwardInvocation:(NSInvocation *)anInvocation {
  if ([delegate respondsToSelector:[anInvocation selector]]) {
    [anInvocation invokeWithTarget:delegate];
  } else {
    [super forwardInvocation:anInvocation];
  }
}

// We need to override methodSignatureForSelector too in order for forwarding to work correctly
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
  if ([delegate respondsToSelector:aSelector]) {
    return [delegate methodSignatureForSelector:aSelector];
  } else {
    return [super methodSignatureForSelector:aSelector];
  }
}
@end
