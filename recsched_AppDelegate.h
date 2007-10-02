//
//  recsched_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>

@class HDHomeRunStation;

@interface recsched_AppDelegate : NSObject <NSPersistentStoreCoordinatorSyncing>
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *mCoreDataProgramWindow;
    
    IBOutlet NSMenuItem *mServerMenuItem;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    
    NSTask      *mVLCTask;
    NSTimer     *mVLCTerminateTimer;

    id mRecServer;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (ISyncClient *)syncClient;

- (IBAction)saveAction:sender;
- (void)syncAction:(id)sender;
- (IBAction)showCoreDataProgramWindow:(id)sender;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow startStreaming:(HDHomeRunStation*)inStation;

- (IBAction) quitServer:(id)sender;
@end
