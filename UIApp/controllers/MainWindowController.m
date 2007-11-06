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

#import "MainWindowController.h"
#import "ScheduleView.h"
#import "Preferences.h"
#import "RSRecording.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"
#import "HDHomeRunTuner.h"
#import "RecSchedProtocol.h"
#import "ScheduleViewController.h"
#import "ProgramSearchViewController.h"

@implementation MainWindowController

const CGFloat kSourceListMaxWidth = 250;
const CGFloat kSourceListMinWidth = 150;

NSString *RSSSchedulePBoardType = @"RSSchedulePasteboardType";
NSString *RSSourceListPBoardType = @"RSSourceListPasteboardType";

NSString *RSSourceListNodeProgramsType = @"PROGRAMS";
NSString *RSSourceListNodeFutureRecordingsType = @"FUTURE RECORDINGS";
NSString *RSSourceListNodePastRecordingsType = @"PAST RECORDINGS";
NSString *RSSourceListNodeSeasonPassesType = @"SEASON PASSES";

NSString *RSSourceListExpandableKey = @"expandable";
NSString *RSSourceListHeadingKey = @"heading";
NSString *RSSourceListLabelKey = @"label";
NSString *RSSourceListChildrenKey = @"children";
NSString *RSSourceListTypeKey = @"type";
NSString *RSSourceListPriorityKey = @"priority";
NSString *RSSourceListActionMessageNameKey = @"actionMessageName";
NSString *RSSourceListCanAcceptDropKey = @"canAcceptDrop";
NSString *RSSourceListObjectIDKey = @"objectID";
NSString *RSSourceListDeletableKey = @"deletable";
NSString *RSSourceListDeleteMessageNameKey = @"deleteMessageName";

#pragma mark Source List Management

// Merge the two arrays returning the resultant merged array
- (NSArray*) mergeRecordingArray:(NSArray*)firstArray withArray:(NSArray*)secondArray
{
	NSMutableArray *mergedRecordingArray = nil;
	NSMutableArray *myFirstArray = [firstArray mutableCopy];
	NSMutableArray *mySecondArray = [secondArray mutableCopy];
	
	if (myFirstArray)
	{
		NSMutableArray *futureRecordingsToDrop = [NSMutableArray arrayWithCapacity:[myFirstArray count]];
		
		// Walk the list of schedules to be recorded - if they're already in the first array we can 'drop' them
		for (NSMutableDictionary* aFutureRecordingNode in myFirstArray)
		{
			// Get the Object ID for the schedule
			NSManagedObjectID *anObjectID = [aFutureRecordingNode valueForKey:RSSourceListObjectIDKey];
			RSRecording *aRecording = (RSRecording*) [[[NSApp delegate] managedObjectContext] objectWithID:anObjectID];
			
			// If the schedule isn't in the list of items to be recorded we should drop it from the firstArray
			if (![mySecondArray containsObject:aRecording])
			{
				// However we can't just remove it since we're in the middle of iterating over the firstArray
				// so instead we'll add it to an array of recordings to be dropped en masse at the end of iterations.
				[futureRecordingsToDrop addObject:aFutureRecordingNode];
			}
			else
			{
				// Lastly we should remove it from the list of secondArray array 
				if (aRecording)
					[mySecondArray removeObject:aRecording];
			}
		}
		[myFirstArray removeObjectsInArray:futureRecordingsToDrop];
	}
	// No future recordings array - create one
	if (myFirstArray)
	{
		mergedRecordingArray = [myFirstArray copy];
	}
	else
		mergedRecordingArray = [[NSMutableArray alloc] initWithCapacity:[mySecondArray count]];


	for (RSRecording *aRecording in mySecondArray)
	{
		NSMutableDictionary *aFutureRecordingNode = [[NSMutableDictionary alloc] init];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSString *timeStr = [dateFormatter stringFromDate:aRecording.schedule.time];
		NSString *labelStr = [NSString stringWithFormat:@"%@ - %@", timeStr, aRecording.schedule.program.title];
		[aFutureRecordingNode setValue:labelStr forKey:RSSourceListLabelKey];
		[aFutureRecordingNode setValue:[aRecording objectID] forKey:RSSourceListObjectIDKey];
		[aFutureRecordingNode setValue:@"futureRecordingSelected:" forKey:RSSourceListActionMessageNameKey];
		[aFutureRecordingNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListDeletableKey];
		[aFutureRecordingNode setValue:@"deleteFutureRecording:" forKey:RSSourceListDeleteMessageNameKey];
		[mergedRecordingArray addObject:aFutureRecordingNode];
	}
	return [mergedRecordingArray autorelease];
}

- (void) updateSourceListForRecordings
{
	NSMutableArray *schedulesToBeRecorded = [NSMutableArray arrayWithArray:[RSRecording fetchRecordingsInManagedObjectContext:[[NSApp delegate]managedObjectContext] afterDate:[NSDate date] withStatus:RSRecordingNotYetStartedStatus]];
	
	NSArray *treeNodes = [mViewSelectionTreeController content];
	NSMutableDictionary *aSourceListNode = nil;
	NSMutableArray *futureRecordingsArray  = nil;
	for (aSourceListNode in treeNodes)
	{
		if ([aSourceListNode valueForKey:RSSourceListTypeKey] == RSSourceListNodeFutureRecordingsType)
		{
			futureRecordingsArray = [aSourceListNode valueForKey:RSSourceListChildrenKey];
			NSArray *mergedFutureRecordingsArray = [self mergeRecordingArray:futureRecordingsArray withArray:schedulesToBeRecorded];
			[aSourceListNode setValue:mergedFutureRecordingsArray forKey:RSSourceListChildrenKey];
		}
		else if ([aSourceListNode valueForKey:RSSourceListTypeKey] == RSSourceListNodePastRecordingsType)
		{
			NSMutableArray *pastRecordings = [NSMutableArray arrayWithArray:[RSRecording fetchRecordingsInManagedObjectContext:[[NSApp delegate]managedObjectContext] beforeDate:[NSDate date]]];
			NSMutableArray *pastRecordingsArray  = [aSourceListNode valueForKey:RSSourceListChildrenKey];
			NSArray *mergedPastRecordingsArray = [self mergeRecordingArray:pastRecordingsArray withArray:pastRecordings];
			[aSourceListNode setValue:mergedPastRecordingsArray forKey:RSSourceListChildrenKey];
		}
	}
}

- (void) addSourceListNodes
{
	NSMutableArray *treeNodes = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSMutableDictionary *aSourceListNode = [[NSMutableDictionary alloc] init];
	[aSourceListNode setValue:@"PROGRAMS" forKey:RSSourceListLabelKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:NO] forKey:RSSourceListExpandableKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListHeadingKey];
	[aSourceListNode setValue:[NSNumber numberWithInt:1] forKey:RSSourceListPriorityKey];
	[aSourceListNode setValue:[[[NSMutableSet alloc] initWithCapacity:2] autorelease] forKey:RSSourceListChildrenKey];
	[aSourceListNode setValue:RSSourceListNodeProgramsType forKey:RSSourceListTypeKey];
	[treeNodes addObject:aSourceListNode];
	
	NSMutableDictionary *aChildSourceListNode = [[NSMutableDictionary alloc] init];
	[aChildSourceListNode setValue:@"Schedule" forKey:RSSourceListLabelKey];
//	[aChildSourceListNode setValue:aSourceListNode forKey:@"parent"];
	[aChildSourceListNode setValue:@"showSchedule:" forKey:RSSourceListActionMessageNameKey];
	[aChildSourceListNode setValue:[NSNumber numberWithInt:1] forKey:RSSourceListPriorityKey];
	[[aSourceListNode valueForKey:RSSourceListChildrenKey] addObject:aChildSourceListNode];
	[aChildSourceListNode release];
	
	aChildSourceListNode = [[NSMutableDictionary alloc] init];
	[aChildSourceListNode setValue:@"Search" forKey:RSSourceListLabelKey];
//	[aChildSourceListNode setValue:aSourceListNode forKey:@"parent"];
	[aChildSourceListNode setValue:@"showSearch:" forKey:RSSourceListActionMessageNameKey];
	[aChildSourceListNode setValue:[NSNumber numberWithInt:2] forKey:RSSourceListPriorityKey];
	[[aSourceListNode valueForKey:RSSourceListChildrenKey] addObject:aChildSourceListNode];
	[aChildSourceListNode release];
	[aSourceListNode release];
	
	aSourceListNode = [[NSMutableDictionary alloc] init];
	[aSourceListNode setValue:@"FUTURE RECORDINGS" forKey:RSSourceListLabelKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListExpandableKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListHeadingKey];
	[aSourceListNode setValue:[NSNumber numberWithInt:2] forKey:RSSourceListPriorityKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListCanAcceptDropKey];
	[aSourceListNode setValue:RSSourceListNodeFutureRecordingsType forKey:RSSourceListTypeKey];
	[treeNodes addObject:aSourceListNode];
	[aSourceListNode release];
	
	aSourceListNode = [[NSMutableDictionary alloc] init];
	[aSourceListNode setValue:@"PAST RECORDINGS" forKey:RSSourceListLabelKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListExpandableKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListHeadingKey];
	[aSourceListNode setValue:[NSNumber numberWithInt:3] forKey:RSSourceListPriorityKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:NO] forKey:RSSourceListCanAcceptDropKey];
	[aSourceListNode setValue:RSSourceListNodePastRecordingsType forKey:RSSourceListTypeKey];
	[treeNodes addObject:aSourceListNode];
	[aSourceListNode release];

	aSourceListNode = [[NSMutableDictionary alloc] init];
	[aSourceListNode setValue:@"SEASON PASSES" forKey:RSSourceListLabelKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListExpandableKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListHeadingKey];
	[aSourceListNode setValue:[NSNumber numberWithInt:4] forKey:RSSourceListPriorityKey];
	[aSourceListNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListCanAcceptDropKey];
	[aSourceListNode setValue:RSSourceListNodeSeasonPassesType forKey:RSSourceListTypeKey];
	[treeNodes addObject:aSourceListNode];
	[aSourceListNode release];
	
	[mViewSelectionTreeController setContent:treeNodes];
	[treeNodes release];
}

#pragma mark Initialization/Startup

- (void) awakeFromNib
{
  // Don't cause resizing when items are expanded
  [mViewSelectionOutlineView setAutoresizesOutlineColumn:NO];
  [self addSourceListNodes];
  
  // Sort based on the 'priority' of the node
  NSSortDescriptor *aSortDescriptor = [[[NSSortDescriptor alloc] initWithKey:RSSourceListPriorityKey ascending:YES] autorelease];
  [mViewSelectionTreeController setSortDescriptors:[NSArray arrayWithObject:aSortDescriptor]];
  
  // Start with the very first (Programs) item expanded
  [mViewSelectionOutlineView reloadItem:nil reloadChildren:YES];
  [mViewSelectionOutlineView expandItem:nil expandChildren:NO];
  
  [mViewSelectionTreeController addObserver:self forKeyPath:@"selection" options:0 context:nil];		// Watch for changes to view selection
  NSIndexPath *anIndexPath = [NSIndexPath indexPathWithIndex:0];
  anIndexPath = [anIndexPath indexPathByAddingIndex:0];
  [mViewSelectionTreeController setSelectionIndexPath:anIndexPath];
  
  // Vertical mouse motion can begin a drag.
  [mViewSelectionOutlineView setVerticalMotionCanBeginDrag:YES];
  
  // Register for drag-n-drop on the outline view
  [mViewSelectionOutlineView registerForDraggedTypes:[NSArray arrayWithObject:RSSSchedulePBoardType]];

	// Observe the arranged list of future recordings - changes to this mean that there are new recordings
	// or some have been removed and we should update the UI.
	[mRecordingsArrayController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:nil];

  mDetailViewMinHeight = [mDetailView frame].size.height;
  NSView *bottomContainerView = [[mScheduleSplitView subviews] objectAtIndex:1];
  [bottomContainerView addSubview:mScheduleContainerView];
  [bottomContainerView addSubview:[mProgramSearchViewController view]];
  
  NSSize scheduleSize = [bottomContainerView frame].size;
  NSRect newFrame = [mScheduleContainerView frame];
  newFrame.size = scheduleSize;
  [mScheduleContainerView setFrame:newFrame];
  [mScheduleContainerView setHidden:NO];
  newFrame = [[mProgramSearchViewController view] frame];
  newFrame.size = scheduleSize;
  [[mProgramSearchViewController view] setFrame:newFrame];
  mProgramSearchViewController.searchViewHidden=YES;
  
  [mTopLevelSplitView setDividerStyle:NSSplitViewDividerStyleThin];
  [mTopLevelSplitView setPosition:kSourceListMinWidth + ((kSourceListMaxWidth - kSourceListMinWidth) / 2) ofDividerAtIndex:0];
  
  [[[mScheduleSplitView subviews] objectAtIndex:0] addSubview:mDetailView];
  newFrame = [mDetailView frame];
  newFrame.size = [[[mScheduleSplitView subviews] objectAtIndex:0] frame].size;
  [mDetailView setFrame:newFrame];

  [mScheduleSplitView setDividerStyle:NSSplitViewDividerStyleThin];
  [mScheduleSplitView setPosition:mDetailViewMinHeight ofDividerAtIndex:0];

  [mScheduleSplitView adjustSubviews];
  [mTopLevelSplitView adjustSubviews];
  
  [mCurrentSchedule setContent:nil];

  // Watch for the RSParsingCompleteNotification to reset our object controllers
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parsingCompleteNotification:) name:RSParsingCompleteNotification object:[NSApp delegate]];
  
  
  // Restore our previous lineup choice
  NSString *lineupObjectURIString = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentLineupURIKey];
  NSURL *lineupObjectURI = nil;
  if (lineupObjectURIString)
  {
	lineupObjectURI = [NSURL URLWithString:lineupObjectURIString];
	NSManagedObjectID *lineupObjectID = [[[NSApp delegate] persistentStoreCoordinator] managedObjectIDForURIRepresentation:lineupObjectURI];
	Z2ITLineup *aLineup = (Z2ITLineup*) [[[NSApp delegate] managedObjectContext] objectWithID:lineupObjectID];
	[mCurrentLineup setContent:aLineup];
  }
  else
  {
	NSError *error = nil;
	[mLineupsArrayController fetchWithRequest:[mLineupsArrayController defaultFetchRequest] merge:NO error:&error];
	if (error == nil)
		[mCurrentLineup setContent:[[mLineupsArrayController arrangedObjects] objectAtIndex:0]];
  }
  
  // Restore our previous schedule choice
  NSString *scheduleObjectURIString = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentScheduleURIKey];
  NSURL *scheduleObjectURI = nil;
  if (scheduleObjectURIString)
  {
	scheduleObjectURI = [NSURL URLWithString:scheduleObjectURIString];
	NSManagedObjectID *scheduleObjectID = [[[NSApp delegate] persistentStoreCoordinator] managedObjectIDForURIRepresentation:scheduleObjectURI];
	Z2ITSchedule *aSchedule = (Z2ITSchedule*) [[[NSApp delegate] managedObjectContext] objectWithID:scheduleObjectID];
	[mCurrentSchedule setContent:aSchedule];
  }
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:RSParsingCompleteNotification object:[NSApp delegate]];

  // Store the current schedule into the preferences
  [[NSUserDefaults standardUserDefaults] setObject:[[[[mCurrentSchedule content] objectID] URIRepresentation] absoluteString] forKey:kCurrentScheduleURIKey];
  [[NSUserDefaults standardUserDefaults] synchronize];  
  
  // Store the current lineup into the preferences
  NSManagedObjectID *lineupObjectID = [[mCurrentLineup content] objectID];
  NSURL* lineupObjectURI = [lineupObjectID URIRepresentation];

  [[NSUserDefaults standardUserDefaults] setObject:[lineupObjectURI absoluteString] forKey:kCurrentLineupURIKey];
  [[NSUserDefaults standardUserDefaults] synchronize];  
  [super dealloc];
}

#pragma mark Action Methods

- (void) setGetScheduleButtonEnabled:(BOOL)enabled
{
  [mGetScheduleButton setEnabled:enabled forSegment:0];
}

- (IBAction) getScheduleAction:(id)sender
{
  [self setGetScheduleButtonEnabled:NO];
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  
  // Converting the current time to a Gregorian Date with no timezone gives us a GMT time that
  // SchedulesDirect expects
  CFGregorianDate startDate = CFAbsoluteTimeGetGregorianDate(currentTime,NULL);
  
  // Retrieve 'n' hours of data
  CFGregorianUnits retrieveRange;
  memset(&retrieveRange, 0, sizeof(retrieveRange));
  float hours = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationKey] floatValue];
  retrieveRange.hours = (int) hours;
    
  CFAbsoluteTime endTime = CFAbsoluteTimeAddGregorianUnits(currentTime, NULL, retrieveRange);
  CFGregorianDate endDate = CFAbsoluteTimeGetGregorianDate(endTime,NULL);
  
  NSString *startDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", startDate.year, startDate.month, startDate.day, startDate.hour];
  NSString *endDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", endDate.year, endDate.month, endDate.day, endDate.hour];
  
  // Send the message to the background server
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:startDateStr, @"startDateStr", endDateStr, @"endDateStr", nil /* really needs to be a DO port or similar */, @"dataRecipient", nil];
  [[[NSApp delegate] recServer] performDownload:callData];
  [callData release];
}

- (IBAction) cleanupAction:(id)sender
{
#if 0
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];
  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
  [callData release];
#endif
}

- (IBAction) recordShow:(id)sender
{
	if ([[NSApp delegate] recServer])
		[[[NSApp delegate] recServer] addRecordingOfSchedule:[[mCurrentSchedule content] objectID]];
}

- (IBAction) recordSeasonPass:(id)sender
{
	NSLog(@"Create a season pass");
}

- (IBAction) watchStation:(id)sender
{
	// Find the HDHRTuner for the station/lineup pair
	Z2ITStation *aStation = [mCurrentStation content];
	Z2ITLineup *aLineup = [mCurrentLineup content];

	NSSet *hdhrStations = [aStation hdhrStations];
	HDHomeRunStation *aHDHRStation;
	for (aHDHRStation in hdhrStations)
	{
		if (([aHDHRStation z2itStation] == aStation) && ([[[aHDHRStation channel] tuner] lineup] == aLineup))
		{
			[[[NSApplication sharedApplication] delegate] launchVLCAction:sender withParentWindow:[self window] startStreaming:aHDHRStation];
			break;
		}
	}
}

- (IBAction) createWishlist:(id)sender
{
	[NSApp beginSheet:mPredicatePanel modalForWindow:[self window] modalDelegate:mWishlistController didEndSelector:nil contextInfo:nil];
	[NSApp runModalForWindow:[self window]];
	[NSApp endSheet:mPredicatePanel];
	[mPredicatePanel orderOut:self];
}

#pragma mark Callback Methods

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule
{
  [mCurrentSchedule setContent:inSchedule];
}

- (Z2ITSchedule *)currentSchedule
{
  return [mCurrentSchedule content];
}

- (void) showSchedule:(id)anArgument
{
	[mScheduleContainerView setHidden:NO];
	[mProgramSearchViewController setSearchViewHidden:YES];
}

- (void) showSearch:(id)anArgument
{
	[mScheduleContainerView setHidden:YES];
	[mProgramSearchViewController setSearchViewHidden:NO];
}

- (void) futureRecordingSelected:(id)anArgument
{
	NSManagedObjectID *anObjectID = [anArgument valueForKey:RSSourceListObjectIDKey];
	RSRecording *aRecording = (RSRecording*) [[[NSApp delegate] managedObjectContext] objectWithID:anObjectID];
	if (aRecording)
		[self setCurrentSchedule:aRecording.schedule];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
    if ((object == mViewSelectionTreeController) && ([keyPath isEqual:@"selection"]))
	{
		if ([[mViewSelectionTreeController selection] valueForKey:RSSourceListActionMessageNameKey] != NSNoSelectionMarker)
		{
			NSLog(@"Show view selection for %@", [[mViewSelectionTreeController selection] valueForKey:RSSourceListLabelKey]);
			SEL actionSelector = NSSelectorFromString([[mViewSelectionTreeController selection] valueForKey:RSSourceListActionMessageNameKey]);
			if ([self respondsToSelector:actionSelector])
				[self performSelector:actionSelector withObject:[mViewSelectionTreeController selection]];
		}
    }
	if ((object == mRecordingsArrayController) && ([keyPath isEqual:@"arrangedObjects"]))
	{
		// The list of future recordings has changed - update the UI.
		[self updateSourceListForRecordings];
	}
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	BOOL enableItem = NO;
	
	if (([anItem action] == @selector(watchStation:)) || ([anItem action] == @selector(recordShow:)) || ([anItem action] == @selector(recordSeasonPass:)))
	{
		if ([mCurrentStation content] != nil)
		{
			enableItem = [[mCurrentStation content] hasValidTunerForLineup:[mCurrentLineup content]];
		}
	}
	
	if ([anItem action] == @selector(delete:))
	{
		// Do we have a selection
		NSTreeNode *theSelection = [mViewSelectionTreeController selection];
		if (theSelection)
		{
			// Is it 'deletable' ?
			if ([theSelection valueForKey:RSSourceListDeletableKey] != nil)
			{
				enableItem = [[theSelection valueForKey:RSSourceListDeletableKey] boolValue];
			}
		}
	}
	
	if ([anItem action] == @selector(createWishlist:))
		enableItem = YES;
		
	return enableItem;
}

- (void) deleteFutureRecording:(id)anArgument
{
	NSManagedObjectID *anObjectID = [anArgument valueForKey:RSSourceListObjectIDKey];
	Z2ITSchedule *aSchedule = (Z2ITSchedule*) [[[NSApp delegate] managedObjectContext] objectWithID:anObjectID];
	
	NSLog(@"deleteFutureRecording - %@, %@", anArgument, aSchedule);
//	if (aSchedule)
//	{
//		[aSchedule setToBeRecorded:[NSNumber numberWithBool:NO]];
//	}
}

- (void) parsingCompleteNotification:(NSNotification*)aNotification
{
	// Store the current lineup selection (if there is one)
	Z2ITLineup *currentLineup = [mCurrentLineup content];
	NSError *error = nil;
	[mLineupsArrayController fetchWithRequest:[mLineupsArrayController defaultFetchRequest] merge:NO error:&error];
	
	if (error)
	{
		NSLog(@"parsingCompleteNotification - fetchWithRequest got error %@", error);
	}
	if (!currentLineup)
	{
		currentLineup = [[mLineupsArrayController arrangedObjects] objectAtIndex:0];
	}

	[mCurrentLineup setContent:currentLineup];
	
	// Trigger the schedule view to redraw
	[[mScheduleView delegate] setStartTime:[[mScheduleView delegate] startTime]];
}

#pragma mark Window Delegate Methods

/**
    Returns the NSUndoManager for the window.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[[NSApp delegate] managedObjectContext] undoManager];
}

- (void) windowWillClose:(NSNotification*)aNotification
{
  [self autorelease];
}

#pragma mark Split View Delegate Methods

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == mTopLevelSplitView)
	{
		if (proposedMaximumPosition > kSourceListMaxWidth)
			return kSourceListMaxWidth;
		else
			return proposedMaximumPosition;
	}
	if (splitView == mScheduleSplitView)
	{
		if (proposedMaximumPosition > mDetailViewMinHeight)
			return mDetailViewMinHeight;
		else
			return proposedMaximumPosition;
	}
	return proposedMaximumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (splitView == mTopLevelSplitView)
	{
		if (proposedMinimumPosition < kSourceListMinWidth)
			return kSourceListMinWidth;
		else
			return proposedMinimumPosition;
	}
	return proposedMinimumPosition;
}

#pragma mark View Selection Table Delegate Methods


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if (item == nil)
		return NO;
	NSMutableDictionary *aTreeNode = [item representedObject];
	NSNumber *headingFlag = [aTreeNode valueForKey:RSSourceListHeadingKey];
	if (headingFlag && ([headingFlag boolValue] == YES))
		return NO;
	else
		return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSMutableDictionary *aTreeNode = [item representedObject];
	NSNumber *expandableFlag = [aTreeNode valueForKey:RSSourceListExpandableKey];
	if (expandableFlag && ([expandableFlag boolValue] == NO))
		return NO;
	else
		return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
	NSMutableDictionary *aTreeNode = [item representedObject];
	NSNumber *expandableFlag = [aTreeNode valueForKey:RSSourceListExpandableKey];
	if (expandableFlag && ([expandableFlag boolValue] == NO))
		return NO;
	else
		return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	NSMutableDictionary *aTreeNode = [item representedObject];
	NSNumber *headingFlag = [aTreeNode valueForKey:RSSourceListHeadingKey];
	if (headingFlag && ([headingFlag boolValue] == YES))
		return YES;
	else
		return NO;
}

- (BOOL) outlineView:(NSOutlineView*)outlineView shouldShowDisclosureTriangleForItem:(id)item
{
	NSMutableDictionary *aTreeNode = [item representedObject];
	NSNumber *expandableFlag = [aTreeNode valueForKey:RSSourceListExpandableKey];
	if (expandableFlag && ([expandableFlag boolValue] == NO))
		return NO;
	else
		return YES;
}

- (void) deleteSelectedRowsOfOutlineView:(NSOutlineView *) aOutlineView
{
	NSMutableDictionary *aTreeNode = [mViewSelectionTreeController selection];
	if (aTreeNode && ([aTreeNode valueForKey:RSSourceListDeleteMessageNameKey] != nil))
	{
		// If we have a delete message name then see if we respond to it and call it with the selection
		SEL deleteSelector = NSSelectorFromString([[mViewSelectionTreeController selection] valueForKey:RSSourceListDeleteMessageNameKey]);
		if ([self respondsToSelector:deleteSelector])
			[self performSelector:deleteSelector withObject:aTreeNode];
	}
}

#pragma mark NSOutlineView Delegate messages for Drag and Drop

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard 
{
    mDraggedNodes = items; // Don't retain since this is just holding temporaral drag information, and it is only used during a drag!  We could put this in the pboard actually.
    
    // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:RSSourceListPBoardType, nil] owner:self];

    // the actual data doesn't matter since RSSourceListPasteboardType drags aren't recognized by anyone but us!.
    [pboard setData:[NSData data] forType:RSSourceListPBoardType]; 
    
    return YES;
}

- (BOOL) proposedItemCanAcceptDrop:(id)item
{
	BOOL canAcceptDrop = NO;
	if (item)
	{
		NSMutableDictionary *nodeDictionary = ([[item representedObject] isKindOfClass:[NSMutableDictionary class]] ? [item representedObject] : nil);
		if (nodeDictionary)
		{
			if ([nodeDictionary valueForKey:RSSourceListCanAcceptDropKey] && ([[nodeDictionary valueForKey:RSSourceListCanAcceptDropKey] boolValue] == YES))
				canAcceptDrop = YES;
		}
	}
	return canAcceptDrop;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	if ([self proposedItemCanAcceptDrop:item])
	{
		[outlineView setDropItem:item dropChildIndex:-1];	// Retarget all drops to the 'group' heading.
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index
{
	NSMutableDictionary *nodeDictionary = ([[item representedObject] isKindOfClass:[NSMutableDictionary class]] ? [item representedObject] : nil);
    NSPasteboard *pboard = [info draggingPasteboard];

	if (nodeDictionary && [self proposedItemCanAcceptDrop:item])
	{
		if  (([nodeDictionary valueForKey:RSSourceListTypeKey] == RSSourceListNodeFutureRecordingsType) && ([pboard availableTypeFromArray:[NSArray arrayWithObject:RSSSchedulePBoardType]] != nil))
		{
				NSDictionary *dragInfoDict = [pboard propertyListForType:RSSSchedulePBoardType];
				NSPersistentStoreCoordinator *storeCoordinator = [[NSApp delegate] persistentStoreCoordinator];
				NSManagedObjectContext *MOC = [[NSApp delegate] managedObjectContext];
				
				Z2ITSchedule *aSchedule = (Z2ITSchedule*) [MOC objectWithID:[storeCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:[dragInfoDict valueForKey:@"scheduleObjectURI"]]]];
				[[[NSApp delegate] recServer] addRecordingOfSchedule:[aSchedule objectID]];
				return YES;
		}
		else
		{
				return NO;
		}
	}
	else
		return NO;
}

@end
