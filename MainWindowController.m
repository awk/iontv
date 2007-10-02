//
//  MainWindowController.m
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AKSourceTableClasses.h"
#import "MainWindowController.h"
#import "ScheduleView.h"
#import "tvDataDelivery.h"
#import "XTVDParser.h"
#import "Preferences.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"
#import "Z2ITStation.h"
#import "recsched_AppDelegate.h"
#import "HDHomeRunTuner.h"

@implementation MainWindowController

const CGFloat kSourceListMaxWidth = 250;
const CGFloat kSourceListMinWidth = 150;

- (void) awakeFromNib
{
  [self showViewForTableSelection:[mViewSelectionTableView selectedRow]];
  mSeparatorCell = [[AKSourceSeparatorCell alloc] init];
  [mViewSelectionArrayController addObject:@"Schedule"];
  [mViewSelectionArrayController addObject:@"Search"];
  [mViewSelectionArrayController addObject:@""];    // Separator at row '2'
  [mViewSelectionArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];		// Watch for changes to view selection
  [mViewSelectionArrayController setSelectionIndex:0];
  
  mDetailViewMinHeight = [mDetailView frame].size.height;
  NSView *bottomContainerView = [[mScheduleSplitView subviews] objectAtIndex:1];
  [bottomContainerView addSubview:mScheduleContainerView];
  [bottomContainerView addSubview:mProgramSearchView];
  
  NSSize scheduleSize = [bottomContainerView frame].size;
  NSRect newFrame = [mScheduleContainerView frame];
  newFrame.size = scheduleSize;
  [mScheduleContainerView setFrame:newFrame];
  [mScheduleContainerView setHidden:NO];
  newFrame = [mProgramSearchView frame];
  newFrame.size = scheduleSize;
  [mProgramSearchView setFrame:newFrame];
  [mProgramSearchView setHidden:YES];
  
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


}

#pragma mark Action Methods

- (IBAction) getScheduleAction:(id)sender
{
  [mParsingProgressIndicator startAnimation:self];
  [mParsingProgressIndicator setHidden:NO];
  [mParsingProgressIndicator setIndeterminate:YES];
  [mParsingProgressInfoField setStringValue:@"Downloading Schedule Data"];
  [mParsingProgressInfoField setHidden:NO];
  [mGetScheduleButton setEnabled:NO];
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  
  // Converting the current time to a Gregorian Date with no timezone gives us a GMT time that
  // Zap2It expects
  CFGregorianDate startDate = CFAbsoluteTimeGetGregorianDate(currentTime,NULL);
  
  // Retrieve 'n' hours of data
  CFGregorianUnits retrieveRange;
  memset(&retrieveRange, 0, sizeof(retrieveRange));
  float hours = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationPrefStr] floatValue];
  retrieveRange.hours = (int) hours;
    
  CFAbsoluteTime endTime = CFAbsoluteTimeAddGregorianUnits(currentTime, NULL, retrieveRange);
  CFGregorianDate endDate = CFAbsoluteTimeGetGregorianDate(endTime,NULL);
  
  NSString *startDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", startDate.year, startDate.month, startDate.day, startDate.hour];
  NSString *endDateStr = [NSString stringWithFormat:@"%d-%d-%dT%d:0:0Z", endDate.year, endDate.month, endDate.day, endDate.hour];
  
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:startDateStr, @"startDateStr", endDateStr, @"endDateStr", self, @"dataRecipient", nil];
  [NSThread detachNewThreadSelector:@selector(performDownload:) toTarget:[xtvdDownloadThread class] withObject:callData];
  [callData release];
}

- (IBAction) cleanupAction:(id)sender
{
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];
  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
  [callData release];
}

- (IBAction) recordShow:(id)sender
{
//  Z2ITSchedule *aSchedule = [mCurrentSchedule content];
//  [aSchedule setToBeRecorded:YES];
//  [mRecServer addRecordingOfProgram:[aSchedule program] withSchedule:aSchedule];
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
	NSEnumerator *anEnumerator = [hdhrStations objectEnumerator];
	HDHomeRunStation *aHDHRStation;
	while ((aHDHRStation = [anEnumerator nextObject]) != nil)
	{
		if (([aHDHRStation Z2ITStation] == aStation) && ([[[aHDHRStation channel] tuner] lineup] == aLineup))
		{
			[[[NSApplication sharedApplication] delegate] launchVLCAction:sender withParentWindow:[self window] startStreaming:aHDHRStation];
			break;
		}
	}
}

#pragma mark Callback Methods

- (void) handleDownloadData:(id)inDownloadResult
{
  NSDictionary *downloadResult = (NSDictionary*)inDownloadResult;
  NSDictionary *messages = [downloadResult valueForKey:@"messages"];
  NSDictionary *xtvd = [downloadResult valueForKey:@"xtvd"];
  NSLog(@"getScheduleAction downloadResult messages = %@", messages);
  NSLog(@"getScheduleAction downloadResult xtvd = %@", xtvd);
  [downloadResult release];

  [mParsingProgressIndicator stopAnimation:self];
  [mParsingProgressIndicator setHidden:YES];
  [mParsingProgressIndicator setIndeterminate:NO];
  [mParsingProgressInfoField setHidden:YES];
  if (xtvd != nil)
  {
    NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:[xtvd valueForKey:@"xmlFilePath"], @"xmlFilePath",
        self, @"reportProgressTo", 
        self, @"reportCompletionTo", 
        [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator",
        nil];
    
    // Start our local parsing
    xtvdParseThread *aParseThread = [[xtvdParseThread alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:aParseThread withObject:callData];
    
    [callData release];
  }
  else
    [mGetScheduleButton setEnabled:YES];
}

- (void) setParsingInfoString:(NSString*)inInfoString
{
  [mParsingProgressInfoField setStringValue:inInfoString];
  [mParsingProgressInfoField setHidden:NO];
}

- (void) setParsingProgressMaxValue:(double)inTotal
{
  [mParsingProgressIndicator setMaxValue:inTotal];
  [mParsingProgressIndicator setHidden:NO];
}

- (void) setParsingProgressDoubleValue:(double)inValue
{
  [mParsingProgressIndicator setDoubleValue:inValue];
}

- (void) parsingComplete:(id)info
{
  [mParsingProgressIndicator setHidden:YES];
  [mParsingProgressInfoField setHidden:YES];

  // Clear all old items from the store
//  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
//  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportProgressTo", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];

  [mParsingProgressIndicator startAnimation:self];
  [mParsingProgressIndicator setHidden:NO];
  [mParsingProgressIndicator setIndeterminate:YES];
  [mParsingProgressInfoField setStringValue:@"Cleanup Old Schedule Data"];
  [mParsingProgressInfoField setHidden:NO];
//  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
//  [callData release];

	[self cleanupComplete:nil];
}

- (void) cleanupComplete:(id)info
{
  [mParsingProgressIndicator stopAnimation:self];
  [mParsingProgressIndicator setHidden:YES];
  [mParsingProgressInfoField setHidden:YES];
  [mGetScheduleButton setEnabled:YES];
}

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule
{
  [mCurrentSchedule setContent:inSchedule];
}

- (Z2ITSchedule *)currentSchedule
{
  return [mCurrentSchedule content];
}

- (void) showViewForTableSelection:(int)selectedRow
{
    switch (selectedRow)
    {
      case 0:
        [mScheduleContainerView setHidden:NO];
        [mProgramSearchView setHidden:YES];
        break;
      case 1:
        [mScheduleContainerView setHidden:YES];
        [mProgramSearchView setHidden:NO];
        break;
      default:
        break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
    if ((object == mViewSelectionArrayController) && ([keyPath isEqual:@"selection"]))
	{
		[self showViewForTableSelection:[mViewSelectionArrayController selectionIndex]];
    }
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
	BOOL enableItem = NO;
	
	if ([anItem action] == @selector(watchStation:))
	{
		if ([mCurrentStation content] != nil)
		{
			enableItem = [[mCurrentStation content] hasValidTunerForLineup:[mCurrentLineup content]];
		}
	}
	if (([anItem action] == @selector(recordShow:)) || ([anItem action] == @selector(recordSeasonPass:)))
	{
		enableItem = ([mCurrentSchedule content] != nil);
	}
	return enableItem;
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

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	if (row == 2) { // separator
		return 4;
	}
	
	return [tableView rowHeight];
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
	return row != 2;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ((row == 2)  && (tableColumn == nil))
	{ // separator
		return mSeparatorCell;
	}
	
	return [tableColumn dataCellForRow:row];
}

@end
