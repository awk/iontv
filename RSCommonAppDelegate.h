//
//  RSCommonAppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 8/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>

@interface RSCommonAppDelegate : NSObject <NSPersistentStoreCoordinatorSyncing>
{
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStore *persistentStore;
}

- (NSString *)applicationSupportFolder;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSPersistentStore *)persistentStore;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

@end
