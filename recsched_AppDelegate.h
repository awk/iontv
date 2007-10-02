//
//  recsched_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "RSCommonAppDelegate.h"

@class HDHomeRunStation;

@interface recsched_AppDelegate : RSCommonAppDelegate
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *mCoreDataProgramWindow;
    
    IBOutlet NSMenuItem *mServerMenuItem;
    
    NSTask      *mVLCTask;
    NSTimer     *mVLCTerminateTimer;

    id mRecServer;
}

- (ISyncClient *)syncClient;
- (id) recServer;

- (IBAction)saveAction:sender;
- (void)syncAction:(id)sender;
- (IBAction)showCoreDataProgramWindow:(id)sender;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow startStreaming:(HDHomeRunStation*)inStation;

- (IBAction) quitServer:(id)sender;

- (void) addSourceListNodes;
@end
