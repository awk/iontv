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

#import <Cocoa/Cocoa.h>
#import "PreferenceKeys.h"

@class DiscreteDurationSlider;

extern NSString *kSchedulesDirectURL;

@interface Preferences : NSObject {

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
    IBOutlet NSButton *mRetrieveLineupsButton;
    IBOutlet NSButton *mScanTunersButton;
    IBOutlet NSButton *mScanChannelsButton;
    IBOutlet NSTableView *mColorsTable;
	
    IBOutlet NSArrayController *mHDHomeRunDevicesArrayController;
    IBOutlet NSArrayController *mHDHomeRunTunersArrayController;
	IBOutlet NSArrayController *mLineupsArrayController;
    IBOutlet NSArrayController *mGenreArrayController;
    IBOutlet NSArrayController *mVisibleStationsArrayController;    // This is the subset of station entities that correspond to the selected HDHR Device/Tuner combo.
	
	IBOutlet NSView *mExportChannelTunerSelectionView;
	
	NSView* mCurrentPrefsView;			// Currently display preferences subview
	
    NSMutableDictionary *mToolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
    SecKeychainItemRef mSDKeychainItemRef;

	NSURL *recordedProgramsLocation;
	NSURL *transcodedProgramsLocation;
	NSArrayController *handbrakePresetsArrayController;
	
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
