//
//  Preferences.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *kScheduleDownloadDurationPrefStr;
@class DiscreteDurationSlider;

@interface Preferences : NSObject {

    IBOutlet NSTextField *mDurationTextField;
    IBOutlet DiscreteDurationSlider *mDurationSlider;
    IBOutlet id mPanel;
    NSMutableDictionary *mToolbarItems; //The dictionary that holds all our "master" copies of the NSToolbarItems
}

+ (Preferences *)sharedInstance;
+ (void)setupDefaults;

//Required NSToolbar delegate methods
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;


- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */

- (IBAction) durationSliderChanged:(NSSlider *)inSlider;

@end
