//
//  ProgramSearchViewController.m
//  recsched
//
//  Created by Andrew Kimpton on 2/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ProgramSearchViewController.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

@implementation ProgramSearchViewController

- (void) dealloc {
	[mProgramsArrayController removeObserver:self forKeyPath:@"selectionIndex"];
	[super dealloc];
}

- (void) awakeFromNib
{
  NSSortDescriptor *titleSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
  NSSortDescriptor *subtitleSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"subTitle" ascending:YES] autorelease];
  NSArray *sortByTitleThenSubtitle = [NSArray arrayWithObjects:titleSortDescriptor, subtitleSortDescriptor, nil];
  [mProgramsArrayController setSortDescriptors:sortByTitleThenSubtitle];
  
  [mProgramsArrayController addObserver:self forKeyPath:@"selectedObjects" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
    if ((object == mProgramsArrayController) && ([keyPath isEqual:@"selectedObjects"]))
	{
		if ([[mProgramsArrayController selectedObjects] count] == 1)
		{
			// Take the first schedule in this programs list
			Z2ITSchedule *aSchedule;
			Z2ITProgram *aProgram = [[mProgramsArrayController selectedObjects] objectAtIndex:0];
			NSSet *schedules = [aProgram schedules];
			aSchedule = [schedules anyObject];
			[mCurrentSchedule setContent:aSchedule];
		}
    }
}
@end
