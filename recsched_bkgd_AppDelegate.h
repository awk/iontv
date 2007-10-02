//
//  recsched_bkgd_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 6/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>

@class RecSchedServer;

@interface recsched_bkgd_AppDelegate : NSObject<NSPersistentStoreCoordinatorSyncing> 
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;

	RecSchedServer *mRecSchedServer;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (ISyncClient *)syncClient;
- (void)syncAction:(id)sender;
- (IBAction) saveAction:(id)sender;

@end
