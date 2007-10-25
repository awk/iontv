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
#import "PreferenceKeys.h"

@class DiscreteDurationSlider;

@interface Preferences : NSObject <XMLParsingProgressDisplay, ChannelScanProgressDisplay> {

    IBOutlet NSTextField *mDurationTextField;
    IBOutlet DiscreteDurationSlider *mDurationSlider;
    IBOutlet id mPanel;
    IBOutlet NSView* mPrefsContainerView;
    IBOutlet NSView* mSDPrefsView;
    IBOutlet NSView* mTunerPrefsView;
    IBOutlet NSView* mChannelPrefsView;
	IBOutlet NSView* mColorPrefsView;
	IBOutlet NSView* mStorageTranscodingPrefsView;
	IBOutlet NSView* mAdvancedPrefsView;
    IBOutlet NSTextField *mSDUsernameField;
    IBOutlet NSTextField *mSDPasswordField;
    IBOutlet NSProgressIndicator *mParsingProgressIndicator;
    IBOutlet NSTextField *mParsingProgressInfoField;
    IBOutlet NSButton *mRetrieveLineupsButton;
    IBOutlet NSProgressIndicator *mTunerScanProgressIndicator;
    IBOutlet NSButton *mScanTunersButton;
    IBOutlet NSProgressIndicator *mChannelScanProgressIndicator;
    IBOutlet NSButton *mScanChannelsButton;
    IBOutlet NSTableView *mColorsTable;
	
    IBOutlet NSArrayController *mHDHomeRunDevicesArrayController;
    IBOutlet NSArrayController *mHDHomeRunTunersArrayController;
    IBOutlet NSArrayController *mGenreArrayController;
    IBOutlet NSArrayController *mVisibleStationsArrayController;    // This is the subset of station entities that correspond to the selected HDHR Device/Tuner combo.
    
	IBOutlet NSView *mExportChannelTunerSelectionView;
	
	NSView* mCurrentPrefsView;			// Currently display preferences subview
	
    NSMutableDictionary *mToolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
    SecKeychainItemRef mSDKeychainItemRef;

	NSURL *recordedProgramsLocation;
	NSURL *transcodedProgramsLocation;
	NSArrayController *handbrakePresetsArrayController;
	
    BOOL mAbortChannelScan;
    BOOL mChannelScanInProgress;
}

@property (retain) NSURL *recordedProgramsLocation;
@property (retain) NSURL *transcodedProgramsLocation;
@property (retain) NSArrayController *handbrakePresetsArrayController;

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
- (IBAction) importHDHomeRunChannelMap:(id)sender;
- (IBAction)setPathAction:(id)sender;
@end
