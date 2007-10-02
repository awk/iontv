//
//  MainWindowController.m
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKSeparatorCell.h"
#import "JKImageTextCell.h"
#import "MainWindowController.h"
#import "ScheduleView.h"
#import "tvDataDelivery.h"
#import "XTVDParser.h"
#import "Preferences.h"
#import "RecSchedProtocol.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"

const float kViewSelectionListMaxWidth = 200.0;
NSString *kRecServerConnectionName = @"recsched_bkgd_server";

@implementation MainWindowController

- (void) awakeFromNib
{
  [mTopLevelSplitView setVertical:YES];
  [mTopLevelSplitView setDelegate:self];
  
  [mViewSelectionTableView selectRow:0 byExtendingSelection:NO];
  [self showViewForTableSelection:[mViewSelectionTableView selectedRow]];
  mSeparatorCell = [[JKSeparatorCell alloc] init];
  mDefaultCell = [[JKImageTextCell alloc] initTextCell:@"Default title"];
  [mViewSelectionArrayController addObject:@"Schedule"];
  [mViewSelectionArrayController addObject:@"Search"];
  [mViewSelectionArrayController addObject:@""];    // Separator at row '2'
  
  mDetailViewMinHeight = [mDetailView frame].size.height;
  NSView *bottomContainerView = [[NSView alloc] initWithFrame:[mScheduleContainerView frame]];
  [bottomContainerView setAutoresizesSubviews:YES];
  [bottomContainerView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
  [bottomContainerView addSubview:mScheduleContainerView];
  [bottomContainerView addSubview:mProgramSearchView];
  [mScheduleContainerView setHidden:NO];
  [mProgramSearchView setHidden:YES];
  
  [mScheduleSplitView addSubview:mDetailView];
  [mScheduleSplitView addSubview:bottomContainerView];
  [bottomContainerView release];
  
  [mScheduleSplitView setIsPaneSplitter:NO];
  [mScheduleSplitView setDelegate:self];
  [mScheduleSplitView adjustSubviews];
  
  [mCurrentSchedule setContent:nil];

  // Connect to server
  mRecServer = [[NSConnection rootProxyForConnectionWithRegisteredName:kRecServerConnectionName  host:nil] retain];
   
  // check if connection worked.
  if (mRecServer == nil) 
  {
    NSLog(@"couldn't connect with server\n");
  }
  else
  {
    //
    // set protocol for the remote object & then register ourselves with the 
    // messaging server.
    [mRecServer setProtocolForProxy:@protocol(RecSchedServerProto)];
  }

}

#pragma mark Splitview delegate methods

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
  if (sender == mScheduleSplitView)
    return proposedMax < mDetailViewMinHeight ? proposedMax : mDetailViewMinHeight;
  else if (sender == mTopLevelSplitView)
    return proposedMax < kViewSelectionListMaxWidth ? proposedMax : kViewSelectionListMaxWidth;
  else
    return proposedMax;
    
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
  Z2ITSchedule *aSchedule = [mCurrentSchedule content];
//  [aSchedule setToBeRecorded:YES];
  [mRecServer addRecordingOfProgram:[aSchedule program] withSchedule:aSchedule];
}

- (IBAction) recordSeasonPass:(id)sender
{
	NSLog(@"Create a season pass");
}

- (IBAction) quitServer:(id)sender
{
  if (mRecServer)
    [mRecServer quitServer:sender];
  mRecServer = nil;
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
    NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:[xtvd valueForKey:@"xmlFilePath"], @"xmlFilePath", self, @"reportProgressTo", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];
    
    // Start our local parsing
    [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:[xtvdParseThread class] withObject:callData];
    
    // And tell the bkgd server to parse the same data too
    [mRecServer performParse:callData];
    
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
  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportProgressTo", self, @"reportCompletionTo", [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator], @"persistentStoreCoordinator", nil];

  [mParsingProgressIndicator startAnimation:self];
  [mParsingProgressIndicator setHidden:NO];
  [mParsingProgressIndicator setIndeterminate:YES];
  [mParsingProgressInfoField setStringValue:@"Cleanup Old Schedule Data"];
  [mParsingProgressInfoField setHidden:NO];
  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
//  [callData release];
}

- (void) cleanupComplete:(id)info
{
  [mParsingProgressIndicator stopAnimation:self];
  [mParsingProgressIndicator setHidden:YES];
  [mParsingProgressInfoField setHidden:YES];
  [mGetScheduleButton setEnabled:YES];

  // Update the schedule grid
  [mScheduleView sortStationsArray];
  [mScheduleView updateStationsScroller];
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

#pragma mark View Selection Table DataSource Methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return 2;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  NSString *aString = nil;
  
  // The Table only has one column
  switch (rowIndex)
  {
    case 0:
      aString = [NSString stringWithString:@"Schedule"];
      break;
    case 1:
      aString = [NSString stringWithString:@"Search"];
      break;
  }
  return aString;
}

#pragma mark View Selection Table Delegate Methods

- (float) heightFor:(NSTableView *)tableView row:(int)row {
	if (row == 2) { // separator
		return 4;
	}
	
	return [tableView rowHeight];
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
	return row != 2;
}

- (id) tableColumn:(NSTableColumn *)column inTableView:(NSTableView *)tableView dataCellForRow:(int)row {
//	if (row == 0) {
//		[defaultCell setImage:libraryImage];
//	} else {
//		[defaultCell setImage:playlistImage];
//	}
	
	if (row == 2) { // separator
		return mSeparatorCell;
	}
	
	return mDefaultCell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  if ([aNotification object] == mViewSelectionTableView)
  {
    [self showViewForTableSelection:[mViewSelectionTableView selectedRow]];
  }
}

@end
