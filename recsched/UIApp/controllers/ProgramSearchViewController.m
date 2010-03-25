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

#import "ProgramSearchViewController.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

NSString *kSubtitleColumnIdentifier = @"subtitleColumn";
NSString *kDescriptionColumnIdentifier = @"descriptionColumn";

@implementation ProgramSearchViewController

- (void)dealloc {
  [mProgramsArrayController removeObserver:self forKeyPath:@"selectionIndex"];
  [super dealloc];
}

- (void)awakeFromNib {
  NSSortDescriptor *titleSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
  NSSortDescriptor *subtitleSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"subTitle" ascending:YES] autorelease];
  NSArray *sortByTitleThenSubtitle = [NSArray arrayWithObjects:titleSortDescriptor, subtitleSortDescriptor, nil];
  [mProgramsArrayController setSortDescriptors:sortByTitleThenSubtitle];

  [mProgramsArrayController addObserver:self forKeyPath:@"selectedObjects" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  // Changing the current selection here must be combined with a test of the
  // visiblity of the search view - otherwise we'll update the selection during startup with the
  // first program in the list of all programs.
  if ((object == mProgramsArrayController) && ([keyPath isEqual:@"selectedObjects"]) && (self.searchViewHidden == NO) ) {
    if ([[mProgramsArrayController selectedObjects] count] == 1) {
      // Take the first schedule in this programs list
      Z2ITSchedule *aSchedule;
      Z2ITProgram *aProgram = [[mProgramsArrayController selectedObjects] objectAtIndex:0];
      NSSet *schedules = [aProgram schedules];
      aSchedule = [schedules anyObject];
      [mCurrentSchedule setContent:aSchedule];
    }
  }
}

- (NSView *)view {
  return mProgramSearchView;
}

- (BOOL)searchViewHidden {
  return searchViewHidden;
}

- (void)setSearchViewHidden:(BOOL)isHidden {
  [mProgramSearchView setHidden:isHidden];
  searchViewHidden = isHidden;
}

#pragma mark Action Methods (from Search Table View)

- (void)showSubtitleColumn:(id)sender {
  NSTableColumn *subtitleColumn = [mProgramTableView tableColumnWithIdentifier:kSubtitleColumnIdentifier];
  if (subtitleColumn) {
    if ([subtitleColumn isHidden]) {
      [subtitleColumn setHidden:NO];
    } else {
      [subtitleColumn setHidden:YES];
    }
  }
}

- (void)showDescriptionColumn:(id)sender {
  NSTableColumn *descriptionColumn = [mProgramTableView tableColumnWithIdentifier:kDescriptionColumnIdentifier];
  if (descriptionColumn) {
    if ([descriptionColumn isHidden]) {
      [descriptionColumn setHidden:NO];
    } else {
      [descriptionColumn setHidden:YES];
    }
  }
}

#pragma mark RSTableHeaderView delegate methods

- (NSMenu *)tableHeaderView:(NSTableHeaderView *)tableHeaderView menuForEvent:(NSEvent *)event {
  NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
  NSMenuItem *theItem = nil;
  theItem = [theMenu insertItemWithTitle:@"Subtitle" action:@selector(showSubtitleColumn:) keyEquivalent:@"" atIndex:0];
  [theItem setTarget:self];
  if ([[mProgramTableView tableColumnWithIdentifier:kSubtitleColumnIdentifier] isHidden]) {
    [theItem setState:NSOffState];
  } else {
    [theItem setState:NSOnState];
  }
  theItem = [theMenu insertItemWithTitle:@"Description" action:@selector(showDescriptionColumn:) keyEquivalent:@"" atIndex:0];
  [theItem setTarget:self];
  if ([[mProgramTableView tableColumnWithIdentifier:kDescriptionColumnIdentifier] isHidden]) {
    [theItem setState:NSOffState];
  } else {
    [theItem setState:NSOnState];
  }
  return theMenu;
}

@end
