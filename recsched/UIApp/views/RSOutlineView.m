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

#import "RSOutlineView.h"
#import "MainWindowController.h"

@implementation RSOutlineView

- (void)keyDown:(NSEvent *)theEvent {
  NSString *tString;
  unsigned int stringLength;
  unsigned int i;
  unichar tChar;

  tString= [theEvent characters];

  stringLength=[tString length];

  for(i=0;i<stringLength;i++)   {
    tChar=[tString characterAtIndex:i];

    if (tChar==0x7F) {
      NSMenuItem * tMenuItem;

      tMenuItem=[[NSMenuItem alloc] initWithTitle:@"" action:@selector(delete:) keyEquivalent:@""];

      if ([self validateUserInterfaceItem:tMenuItem]==YES) {
        [self delete:nil];
      } else {
        NSBeep();
      }

      return;
    }
  }

  [super keyDown:theEvent];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem {
  if ([anItem action]==@selector(delete:)) {
    if ([self numberOfSelectedRows]>0) {
      MainWindowController *mwc = nil;
      if ([[self dataSource] class] == [MainWindowController class]) {
        mwc = (MainWindowController *)[self dataSource];
      }
      return [mwc validateUserInterfaceItem:anItem];
    }

    return NO;
  }

  return YES;
}

- (IBAction)delete:(id) sender {
  if ([[self dataSource] respondsToSelector:@selector(deleteSelectedRowsOfOutlineView:)]==YES) {
    [[self dataSource] performSelector:@selector(deleteSelectedRowsOfOutlineView:) withObject:self];
  }
}

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row {
  id anItem = [self itemAtRow:row];
  if (anItem && ([[self delegate] respondsToSelector:@selector(outlineView:shouldShowDisclosureTriangleForItem:)] == YES))   {
    NSObject *mwc = [self delegate];
    if ([mwc outlineView:self shouldShowDisclosureTriangleForItem:anItem] == YES) {
      return [super frameOfOutlineCellAtRow:row];
    } else {
      return NSZeroRect;
    }
  } else {
    return [super frameOfOutlineCellAtRow:row];
  }
}

@end

