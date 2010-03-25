//
//  RSFirstRunWindowController.h
//  recsched
//
//  Created by Andrew Kimpton on 1/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITLineup;
@class HDHomeRunTuner;

@interface RSFirstRunWindowController : NSWindowController {

  // Outlets for the window/nib
  IBOutlet NSTabView *mTabView;
  IBOutlet NSArrayController *mLineupArrayController;
  IBOutlet NSArrayController *mHDHRStationsOnLineupController;
  IBOutlet NSArrayController *mDevicesArrayController;
  IBOutlet NSArrayController *mAllStationsArrayController;
  IBOutlet NSArrayController *mZ2ITStationsOnLineupController;

  // Outlets for the SchedulesDirect tab
  IBOutlet NSTextField *mSDUsernameField;
  IBOutlet NSSecureTextField *mSDPasswordField;
  IBOutlet NSProgressIndicator *mLineupsRetrievalProgressIndicator;
  IBOutlet NSTextField *mLineupsRetrievalLabel;
  IBOutlet NSButton *mSDContinueButton;

  SecKeychainItemRef mSDKeychainItemRef;

  // Outlets for the Tuners tab

  // Outlets for the Start Scan Tab
  IBOutlet NSPopUpButton *mChannelScanLineupSelectionPopupButton;
  IBOutlet NSView *mChannelScanActivityContainerView;
  IBOutlet NSButton *mChannelScanGoBackButton;
  IBOutlet NSButton *mChannelScanScanButton;

  // Outlets for the Station mapping tab
  IBOutlet NSPopUpButton *mStationMappingLineupSelectionPopupButton;

  // Property instance variables
  Z2ITLineup *scanLineupSelection;
  HDHomeRunTuner *scanningTuner;

  Boolean mScanInProgress;
  NSConnection *mConnection;
  Boolean mShouldCancelChannelScan;
}

@property (retain) Z2ITLineup *scanLineupSelection;
@property (retain) HDHomeRunTuner *scanningTuner;

- (IBAction)continueFromSDAccount:(id)sender;
- (IBAction)continueFromDeviceScan:(id)sender;
- (IBAction)beginChannelScan:(id)sender;
- (IBAction)viewHDHRStation:(id)sender;
- (IBAction)channelListFinish:(id)sender;
- (IBAction)firstRunWindowFinished:(id) sender;

- (IBAction)cancelAndClose:(id)sender;
- (IBAction)previousTab:(id)sender;

- (IBAction)getSDAccount:(id)sender;
@end
