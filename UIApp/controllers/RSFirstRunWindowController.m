//
//  RSFirstRunWindowController.m
//  recsched
//
//  Created by Andrew Kimpton on 1/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSFirstRunWindowController.h"
#import "Preferences.h"
#import "PreferenceKeys.h"
#import "RecSchedProtocol.h"
#import "recsched_AppDelegate.h"
#import "HDHomeRunTuner.h"
#import "HDHomeRunMO.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"
#import "Z2ITStation.h"
#import "RSActivityViewController.h"
#import "RSNotifications.h"

const NSInteger kSchedulesDirectTabViewIndex = 0;
const NSInteger kTunerTabViewIndex = 1;
const NSInteger kStartChannelScanTabViewIndex = 2;
const NSInteger kChannelListTabViewIndex = 3;
const NSInteger kFinishedTabViewIndex = 4;

@interface RSFirstRunWindowController(Private) <RSActivityDisplay>

- (void) resetChannelScanControls;
- (void) cancelChannelScan;
- (void) showTuners:(id)sender;
- (void) showStartChannelScan:(id)sender;
- (void) saveSDUsername;
- (void) updateTunerAndStationsForCurrentLineup;
- (void) updateZ2ITStationsForCurrentLineup;
@end

@implementation RSFirstRunWindowController

@synthesize scanLineupSelection;
@synthesize scanningTuner;

#pragma mark Initialization

- (void) awakeFromNib
{
    NSArray *lineups = [mLineupArrayController arrangedObjects];
    if ([lineups count] > 0)
      self.scanLineupSelection = [lineups objectAtIndex:0];
  [self addObserver:self forKeyPath:@"scanLineupSelection" options:0 context:nil];

  // Attempt to retrieve the Username and password fields for the SchedulesDirect site
  NSString* SDUsernameString = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kWebServicesSDUsernameKey];
  if (SDUsernameString)
  {
    [mSDUsernameField setStringValue:SDUsernameString];

    const char *serverNameUTF8 = [kWebServicesSDHostname UTF8String];
    const char *accountNameUTF8 = [SDUsernameString UTF8String];
    const char *pathUTF8 = [kWebServicesSDPath UTF8String];
    UInt32 passwordLength;
    void *passwordData;
    OSStatus status = SecKeychainFindInternetPassword(NULL,strlen(serverNameUTF8),serverNameUTF8, 0, NULL, strlen(accountNameUTF8), accountNameUTF8, strlen(pathUTF8), pathUTF8, 80, kSecProtocolTypeHTTP, kSecAuthenticationTypeDefault, &passwordLength, &passwordData, &mSDKeychainItemRef);
    
    if (status == noErr)
    {
              NSString *passwordString = [NSString stringWithCString:passwordData length:passwordLength];
      [mSDPasswordField setStringValue:passwordString];
      SecKeychainItemFreeContent(NULL, passwordData);
    }
  }
  
  mScanInProgress = NO;
  mShouldCancelChannelScan = NO;
}

 - (void) dealloc
 {
   [super dealloc];
 }

#pragma mark Actions

- (IBAction) continueFromSDAccount:(id)sender
{
  // Save the SchedulesDirect Username and password
  [self saveSDUsername];
  
  // Retrieve a list of lineups from the SD Service, disable the continue buttons whilst this is happening, and update
  // the progress indicator and text labels
  [mSDContinueButton setEnabled:NO];
  [mLineupsRetrievalLabel setHidden:NO];
  [mLineupsRetrievalProgressIndicator setHidden:NO];
  [mLineupsRetrievalProgressIndicator startAnimation:self];

  // We need to know when the lineup retrieval completes.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lineupRetrievalCompleteNotification:) name:RSLineupRetrievalCompleteNotification object:[NSApp delegate]];

  [[[NSApp delegate] recServer] updateLineups];
}

- (IBAction) cancelAndClose:(id)sender
{
  // Remove ourselves from observing the completion notification
  [[NSNotificationCenter defaultCenter] removeObserver:self name:RSLineupRetrievalCompleteNotification object:[NSApp delegate]];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSDeviceScanCompleteNotification object:RSBackgroundApplication];
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSChannelScanCompleteNotification object:RSBackgroundApplication];

  [[self window] performClose:sender];
}

- (IBAction) previousTab:(id)sender
{
  NSInteger currentTabIndex = [mTabView indexOfTabViewItem:[mTabView selectedTabViewItem]];
  currentTabIndex--;
  if (currentTabIndex < 0)
    currentTabIndex = 0;
  [mTabView selectTabViewItemAtIndex:currentTabIndex];
}

- (IBAction) getSDAccount:(id)sender
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kSchedulesDirectURL]];
}

- (IBAction) continueFromDeviceScan:(id)sender
{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSDeviceScanCompleteNotification object:RSBackgroundApplication];
  [self showStartChannelScan:sender];
}

- (IBAction) beginChannelScan:(id)sender
{
  if (mScanInProgress)
  {
    [self cancelChannelScan];
    return;
  }
  
  if (scanLineupSelection)
  {
    if (!scanningTuner)
      scanningTuner = [scanLineupSelection.tuners anyObject];
  }
  
  if (scanningTuner)
  {
    mScanInProgress = YES;
    mShouldCancelChannelScan = NO;
    [mChannelScanScanButton setTitle:@"Cancel"];
    [mChannelScanGoBackButton setEnabled:NO];
    [mChannelScanActivityContainerView setHidden:NO];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
        selector:@selector(channelScanCompleteNotification:)
        name:RSChannelScanCompleteNotification object:RSBackgroundApplication
        suspensionBehavior:NSNotificationSuspensionBehaviorCoalesce];
  
    [[[NSApp delegate] recServer] activityDisplayUnavailable];
    [[[NSApp delegate] activityWindowController].activityViewController.activityConnection setRootObject:self];
    [[[NSApp delegate] recServer] activityDisplayAvailable];
    
    [[[NSApp delegate] recServer] scanForChannelsOnHDHomeRunDeviceID:scanningTuner.device.deviceID tunerIndex:scanningTuner.index];
  }
  else
  {
    NSAlert *noTunerAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"You have no tuners which use the lineup %@", scanLineupSelection.name] 
            defaultButton:nil /*OK*/ alternateButton:@"Go Back" otherButton:nil
            informativeTextWithFormat:@"There are no tuners which are configured to use this lineup. Perform a scan with a different lineup or go back to the previous section and configure a tuner to use this lineup."];
    [noTunerAlert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(noTunerAlertDidEnd: returnCode: contextInfo:) contextInfo:nil];
  }
}

- (IBAction) viewHDHRStation:(id)sender
{
  HDHomeRunStation *selectedStation = [[mHDHRStationsOnLineupController selectedObjects] objectAtIndex:0];
  [[[NSApplication sharedApplication] delegate] launchVLCAction:sender withParentWindow:[self window] startStreaming:selectedStation];
}

- (IBAction) channelListFinish:(id)sender
{
  if (scanningTuner)
  {
    for (HDHomeRunTuner *aTuner in scanLineupSelection.tuners)
    {
      if (aTuner != scanningTuner)
      {
        [aTuner copyChannelsAndStationsFrom:scanningTuner];
      }
      [aTuner pushHDHomeRunStationsToServer];
    }
    scanningTuner = nil;
  }
  
  // Write the key to the metadata store to show that we're done
  NSError *error = nil;
  NSMutableDictionary *storeMetadata = [NSMutableDictionary dictionaryWithDictionary:[NSPersistentStoreCoordinator metadataForPersistentStoreWithURL:[[NSApp delegate] urlForPersistentStore] error:&error]];
  [storeMetadata setValue:[NSNumber numberWithBool:YES] forKey:kFirstRunAssistantCompletedKey];
  [NSPersistentStoreCoordinator setMetadata:storeMetadata forPersistentStoreOfType:nil URL:[[NSApp delegate] urlForPersistentStore] error:&error];
  
  // Start downloading schedule data
  [[[NSApp delegate] recServer] fetchFutureSchedule:nil];
  
  // Select the next tab with the 'downloading schedule data' message
  [mTabView selectTabViewItemAtIndex:kFinishedTabViewIndex];
}

- (IBAction) firstRunWindowFinished:(id) sender
{
  // All done - close the window and go away
  [[self window] performClose:sender];
}

#pragma mark Observation

- (void)observeValueForKeyPath:(NSString *)keyPath
			ofObject:(id)object 
			change:(NSDictionary *)change
			context:(void *)context
{
  if ((object == self) && ([keyPath compare:@"scanLineupSelection"] == NSOrderedSame))
  {
      // Update the tuner and stations on that tuner
      [self updateTunerAndStationsForCurrentLineup];
      
      // Update the list of Z2ITStations this lineup contains
      [self updateZ2ITStationsForCurrentLineup];
  }
}

#pragma mark CoreData

- (NSManagedObjectContext *)managedObjectContext
{
	return [[NSApp delegate] managedObjectContext];
}

#pragma mark Notifications

- (void) lineupRetrievalCompleteNotification:(NSNotification*)aNotification
{
  // Remove ourselves from observing the completion notification
  [[NSNotificationCenter defaultCenter] removeObserver:self name:RSLineupRetrievalCompleteNotification object:[NSApp delegate]];
  
//  NSError *error = nil;
//  [mLineupArrayController fetchWithRequest:[mLineupArrayController defaultFetchRequest] merge:NO error:&error];
  NSError *error = nil;

  NSTimeInterval currentStalenessInterval = [[mLineupArrayController managedObjectContext] stalenessInterval];
  [[mLineupArrayController managedObjectContext] setStalenessInterval:0];
  NSFetchRequest *aFetchRequest = [mLineupArrayController defaultFetchRequest];
  [aFetchRequest setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"lineupMaps.station"]];
  NSArray *array = [[mLineupArrayController managedObjectContext] executeFetchRequest:aFetchRequest error:&error];
  for (Z2ITLineup *aLineup in array)
  {
    [[mLineupArrayController managedObjectContext] refreshObject:aLineup mergeChanges:YES];
  }

  array = [[mAllStationsArrayController managedObjectContext] executeFetchRequest:[mAllStationsArrayController defaultFetchRequest] error:&error];
  for (Z2ITStation *aStation in array)
  {
    [[mAllStationsArrayController managedObjectContext] refreshObject:aStation mergeChanges:NO];
  }
  [[mLineupArrayController managedObjectContext] setStalenessInterval:currentStalenessInterval];
  
  // Got all the lineups - hide the progress/info text and move on to the next tab
  [mSDContinueButton setEnabled:YES];
  [mLineupsRetrievalLabel setHidden:YES];
  [mLineupsRetrievalProgressIndicator stopAnimation:self];
  [mLineupsRetrievalProgressIndicator setHidden:YES];
  
  [self showTuners:self];
}

- (void) deviceScanCompleteNotification:(NSNotification*)aNotification
{
  NSTimeInterval currentStalenessInterval = [[mLineupArrayController managedObjectContext] stalenessInterval];
  [[mLineupArrayController managedObjectContext] setStalenessInterval:0];

  // We should update (re-fetch) the NSArrayController with the list of HDHomeRunTuners in the system to update ui
  NSError *error = nil;
  [mDevicesArrayController fetchWithRequest:[mDevicesArrayController defaultFetchRequest] merge:NO error:&error];
  
  // We also need to update the array controller for the lineups - adding new tuners will potentially have added tuners
  // to the tuners relationship on the lineups. Refetching here makes sure that the lineups are up to date.
  // Reissuing the fetch alone isn't enough though - we also need to adjust the staleness interval (and restore it)
  // to make sure that we don't just reuse cached data.

  [mLineupArrayController fetchWithRequest:[mLineupArrayController defaultFetchRequest] merge:NO error:&error];
  for (Z2ITLineup *aLineup in [mLineupArrayController arrangedObjects])
  {
    [[mLineupArrayController managedObjectContext] refreshObject:aLineup mergeChanges:NO];
  }
  
  [[mLineupArrayController managedObjectContext] setStalenessInterval:currentStalenessInterval];

  // Scan again in another 5 seconds
  [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(scanForHDHomeRunDevicesTimerFired:) userInfo:nil repeats:NO];
}

- (void) channelScanCompleteNotification:(NSNotification*)aNotification
{
  int scanResult = 0;
  if ([[aNotification userInfo] valueForKey:@"scanResult"])
    scanResult = [[[aNotification userInfo] valueForKey:@"scanResult"] intValue];
    
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSChannelScanCompleteNotification object:RSBackgroundApplication];
  
  [[[NSApp delegate] recServer] activityDisplayUnavailable];
  [[[NSApp delegate] activityWindowController].activityViewController.activityConnection setRootObject:[[NSApp delegate] activityWindowController].activityViewController];
  [[[NSApp delegate] recServer] activityDisplayAvailable];
  mShouldCancelChannelScan = NO;
  
  if (scanResult > 0)
  {
    NSManagedObjectContext *moc = [self.scanLineupSelection managedObjectContext];
    NSTimeInterval currentStalenessInterval = [moc stalenessInterval];
    [moc setStalenessInterval:0];

    // Refresh the local tuners list channels and stations from the store
    [[scanningTuner managedObjectContext] refreshObject:scanningTuner mergeChanges:NO];
    
    NSMutableArray *stationsOnTuner = [NSMutableArray arrayWithCapacity:[[scanningTuner channels] count] * 3];   // Start with 3 stations per channel
    for (HDHomeRunChannel *aChannel in [scanningTuner channels])
    {
      [stationsOnTuner addObjectsFromArray:[[aChannel stations] allObjects]];
    }
    [mHDHRStationsOnLineupController setContent:stationsOnTuner];

    [moc setStalenessInterval:currentStalenessInterval];
    
    [self resetChannelScanControls];
    [mTabView selectTabViewItemAtIndex:kChannelListTabViewIndex];
  }

  // Reset the scanning tuner - we're not scanning any more.
  self.scanningTuner = nil;
}

@end

@implementation RSFirstRunWindowController(Private)

- (void) resetChannelScanControls
{
    mScanInProgress = NO;
    [mChannelScanScanButton setTitle:@"Scan"];
    [mChannelScanGoBackButton setEnabled:YES];
    [mChannelScanActivityContainerView setHidden:YES];
}

- (void) cancelChannelScan
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:RSChannelScanCompleteNotification object:RSBackgroundApplication];
    mShouldCancelChannelScan = YES;
    [self resetChannelScanControls];
}

#pragma mark Bound Properties

- (NSArray *) z2itStationSortDescriptors
{
  NSSortDescriptor* callSignDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"callSign" ascending:YES] autorelease];
  NSArray* sortDescriptors = [NSArray arrayWithObject:callSignDescriptor];

  return sortDescriptors;
}


#pragma mark Sheet Methods

- (void) noTunerAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertAlternateReturn)
    {
      [mTabView selectTabViewItemAtIndex:kTunerTabViewIndex]; 
    }
}

#pragma mark Activity Display

- (size_t) createActivity
{
	// Create the new Aggregate view controller
	RSActivityAggregateViewController *anAggregateViewController = [[RSActivityAggregateViewController alloc] init];
	if (![NSBundle loadNibNamed:@"ActivityAggregateView" owner:anAggregateViewController])
	{
		NSLog(@"Error loading aggregate activity view NIB");
		return 0;
	}
	
	// Add the aggregate view to the space in the scanning tab
        [[anAggregateViewController aggregateView] setFrameSize:[mChannelScanActivityContainerView frame].size];
        [mChannelScanActivityContainerView addSubview:[anAggregateViewController aggregateView]];
        [[anAggregateViewController aggregateView] setNeedsDisplay:YES];
	return (size_t)anAggregateViewController;
}

- (void) endActivity:(size_t)activityToken
{
	[(RSActivityAggregateViewController*) activityToken release];
}

- (size_t) setActivity:(size_t)activityToken infoString:(NSString*)inInfoString
{
	[(RSActivityAggregateViewController*) activityToken setInfoString:inInfoString];
        return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressIndeterminate:(BOOL)isIndeterminate
{
	[(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:isIndeterminate];
        return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressMaxValue:(double)inTotal
{
	[(RSActivityAggregateViewController*) activityToken setProgressMaxValue:inTotal];
        return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressDoubleValue:(double)inValue
{
	[(RSActivityAggregateViewController*) activityToken setProgressDoubleValue:inValue];
        return activityToken;
}

- (size_t) setActivity:(size_t)activityToken incrementBy:(double)delta
{
	[(RSActivityAggregateViewController*) activityToken incrementProgressBy:delta];
        return activityToken;
}

- (size_t) shouldCancelActivity:(size_t)activityToken cancel:(BOOL*)cancel;
{
  if (cancel && mShouldCancelChannelScan)
  {
	*cancel = /*[(RSActivityAggregateViewController*) activityToken shouldCancel] | */ mShouldCancelChannelScan;
  }
  return activityToken;
}

#pragma mark Switching Tabs

- (void) showTuners:(id)sender
{
  [mTabView selectTabViewItemAtIndex:kTunerTabViewIndex];
  
  // Once every 5 seconds we'll send a 'scan for devices' message to the server and then update the results from
  // the completion notification
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self
      selector:@selector(deviceScanCompleteNotification:)
      name:RSDeviceScanCompleteNotification object:RSBackgroundApplication
      suspensionBehavior:NSNotificationSuspensionBehaviorCoalesce];

  [[[NSApp delegate] recServer] scanForHDHomeRunDevices:self];
}

- (void) scanForHDHomeRunDevicesTimerFired:(NSTimer*)aTimer
{
  [[[NSApp delegate] recServer] scanForHDHomeRunDevices:self];
}

- (void) showStartChannelScan:(id)sender
{
  [mTabView selectTabViewItemAtIndex:kStartChannelScanTabViewIndex];
  
  // Count the number of lineups in use
  NSMutableArray *lineupsInUseArray = [NSMutableArray arrayWithCapacity:5];
  for (HDHomeRun *aHDHomeRun in [mDevicesArrayController arrangedObjects])
  {
    for (HDHomeRunTuner *aTuner in aHDHomeRun.tuners)
    {
      if (![lineupsInUseArray containsObject:aTuner.lineup])
      {
        [lineupsInUseArray addObject:aTuner.lineup];
      }
    }
  }
  self.scanLineupSelection = [lineupsInUseArray objectAtIndex:0];
  if ([lineupsInUseArray count] == 1)
  {
    [mChannelScanLineupSelectionPopupButton setEnabled:NO];
  }
  else
  {
    [mChannelScanLineupSelectionPopupButton setEnabled:YES];
  }
}


#pragma mark Preferences Updating

- (void) saveSDUsername
{
  NSUserDefaultsController *theDefaultsController  = [NSUserDefaultsController sharedUserDefaultsController];
  if ([mSDUsernameField stringValue])
  {
	NSUserDefaultsController *theDefaultsController  = [NSUserDefaultsController sharedUserDefaultsController];
	[[theDefaultsController values] setValue:[mSDUsernameField stringValue] forKey:kWebServicesSDUsernameKey];
    const char *serverNameUTF8 = [kWebServicesSDHostname UTF8String];
    const char *accountNameUTF8 = [[mSDUsernameField stringValue] UTF8String];
    const char *pathUTF8 = [kWebServicesSDPath UTF8String];
    UInt32 passwordLength;
    const void *passwordData;

	NSString *passwordString = [mSDPasswordField stringValue];
	passwordData = [passwordString UTF8String];
	passwordLength = strlen(passwordData);
    
    // Call AddInternetPassword - if it's already in the keychain then update it
    OSStatus status;
    if (mSDKeychainItemRef == nil)
    {
      status = SecKeychainAddInternetPassword(NULL, strlen(serverNameUTF8), serverNameUTF8,0 , NULL, strlen(accountNameUTF8), accountNameUTF8, strlen(pathUTF8), pathUTF8, 80, kSecProtocolTypeHTTP, kSecAuthenticationTypeDefault, passwordLength, passwordData, &mSDKeychainItemRef);
    }
    else
    {
      // The item already exists - we just need to change the password.
      // And the Account name
      void *accountNameAttributeData = malloc(strlen([[mSDUsernameField stringValue] UTF8String]));
      memcpy(accountNameAttributeData, [[mSDUsernameField stringValue] UTF8String], strlen([[mSDUsernameField stringValue] UTF8String]));
      
      SecKeychainAttribute accountNameAttribute;
      accountNameAttribute.tag = kSecAccountItemAttr;
      accountNameAttribute.data = accountNameAttributeData;
      accountNameAttribute.length = strlen([[mSDUsernameField stringValue] UTF8String]);
      SecKeychainAttributeList attrList;
      attrList.count = 1;
      attrList.attr = &accountNameAttribute;
      status = SecKeychainItemModifyAttributesAndData(mSDKeychainItemRef, &attrList, passwordLength, passwordData);
      free(accountNameAttributeData);
	}
  }
  [theDefaultsController save:self];
  
  // Tell the background server to reload it's preferences
  [[[NSApp delegate] recServer] reloadPreferences:self];
}

- (void) updateTunerAndStationsForCurrentLineup
{
    HDHomeRunTuner *candidateTuner = nil;
    for (HDHomeRunTuner *aTuner in self.scanLineupSelection.tuners)
    {
      // Find the tuner with the most channels (it'll be the one we scanned with last)
      int numChannelsFound = 0;
      if ([[aTuner channels] count] > numChannelsFound)
      {
        numChannelsFound = [[aTuner channels] count];
        candidateTuner = aTuner;
      }
    }
    if (candidateTuner == nil)
      candidateTuner = [scanLineupSelection.tuners anyObject];
    
    if (candidateTuner != scanningTuner)
      self.scanningTuner = candidateTuner;
      
    if (scanningTuner)
    {
      NSMutableArray *stationsOnTuner = [NSMutableArray arrayWithCapacity:[[scanningTuner channels] count] * 3];   // Start with 3 stations per channel
      for (HDHomeRunChannel *aChannel in [scanningTuner channels])
      {
        [stationsOnTuner addObjectsFromArray:[[aChannel stations] allObjects]];
      }
      [mHDHRStationsOnLineupController setContent:stationsOnTuner];
    }
    else
      [mHDHRStationsOnLineupController setContent:nil];
}

- (void) updateZ2ITStationsForCurrentLineup
{
  NSMutableArray *stationsOnLineup = [NSMutableArray arrayWithCapacity:[self.scanLineupSelection.lineupMaps count]];
  for (Z2ITLineupMap *aLineupMap in self.scanLineupSelection.lineupMaps)
  {
    [stationsOnLineup addObject:aLineupMap.station];
  }
  [mZ2ITStationsOnLineupController setContent:stationsOnLineup];
}

@end
