//
//  RecSchedServer.h
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>

#import "RecSchedProtocol.h"

@interface RecSchedServer : NSObject <RecSchedServerProto, NSPersistentStoreCoordinatorSyncing> {
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    
    BOOL mExitServer;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (bool) shouldExit;

- (ISyncClient *)syncClient;
- (void)syncAction:(id)sender;

@end
