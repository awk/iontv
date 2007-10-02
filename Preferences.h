//
//  Preferences.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ChannelScanProgressDisplayProtocol.h"
#import "XMLParsingProgressDisplayProtocol.h"

extern NSString *kScheduleDownloadDurationPrefStr;
extern NSString *kWebServicesZap2ItUsernamePrefStr;

@class DiscreteDurationSlider;

@interface Preferences : NSObject <XMLParsingProgressDisplay, ChannelScanProgressDisplay> {

    IBOutlet NSTextField *mDurationTextField;
    IBOutlet DiscreteDurationSlider *mDurationSlider;
    IBOutlet id mPanel;
    IBOutlet NSView* mPrefsContainerView;
    IBOutlet NSView* mZap2ItPrefsView;
    IBOutlet NSView* mTunerPrefsView;
    IBOutlet NSView* mChannelPrefsView;
    IBOutlet NSTextField *mZap2ItUsernameField;
    IBOutlet NSTextField *mZap2ItPasswordField;
    IBOutlet NSProgressIndicator *mParsingProgressIndicator;
    IBOutlet NSTextField *mParsingProgressInfoField;
    IBOutlet NSButton *mRetrieveLineupsButton;
    IBOutlet NSProgressIndicator *mTunerScanProgressIndicator;
    IBOutlet NSButton *mScanTunersButton;
    IBOutlet NSProgressIndicator *mChannelScanProgressIndicator;
    IBOutlet NSButton *mScanChannelsButton;
    
    IBOutlet NSArrayController *mHDHomeRunTunersArrayController;
    IBOutlet NSArrayController *mLineupArrayController;
    IBOutlet NSArrayController *mStationsArrayController;           // This is all the station entitiies in the MOC
    IBOutlet NSArrayController *mVisibleStationsArrayController;    // This is the subset of station entities that correspond to the selected HDHR Device/Tuner combo.
    
	IBOutlet NSView *mExportChannelTunerSelectionView;
	
    NSMutableDictionary *mToolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
    SecKeychainItemRef mZap2ItKeychainItemRef;

    BOOL mAbortChannelScan;
    BOOL mChannelScanInProgress;
}

+ (Preferences *)sharedInstance;
+ (void)setupDefaults;

- (NSManagedObjectContext *)managedObjectContext;

//Required NSToolbar delegate methods
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;


- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */

- (IBAction) durationSliderChanged:(NSSlider *)inSlider;
- (IBAction) okButtonAction:(id)sender;
- (IBAction) cancelButtonAction:(id)sender;
- (IBAction) getAccountButtonAction:(id)sender;
- (IBAction) retrieveLineupsButtonAction:(id)sender;
- (IBAction) scanDevicesButtonAction:(id)sender;
- (IBAction) scanChannelsButtonAction:(id)sender;
- (IBAction) viewHDHRStation:(id)sender;
- (IBAction) exportHDHomeRunChannelMap:(id)sender;
@end
