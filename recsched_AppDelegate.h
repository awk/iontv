//
//  recsched_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "RSCommonAppDelegate.h"
#import "RSStoreUpdateProtocol.h"

@class HDHomeRunStation;

@interface recsched_AppDelegate : RSCommonAppDelegate <RSStoreUpdate>
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *mCoreDataProgramWindow;
    
    IBOutlet NSMenuItem *mServerMenuItem;
    
    NSTask      *mVLCTask;
    NSTimer     *mVLCTerminateTimer;

    id mRecServer;
	
	NSWindowController *mActivityWindowController;
}

#if USE_SYNCSERVICES
- (ISyncClient *)syncClient;
#endif // USE_SYNCSERVICES
- (id) recServer;

#if USE_SYNCSERVICES
- (IBAction)saveAction:sender;
- (void)syncAction:(id)sender;
#endif // USE_SYNCSERVICES
- (IBAction)showCoreDataProgramWindow:(id)sender;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow startStreaming:(HDHomeRunStation*)inStation;
- (IBAction)showActivityWindow:(id)sender;

- (IBAction) quitServer:(id)sender;

@property (retain,getter=recServer) id mRecServer;
@end
