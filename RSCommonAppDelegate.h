//
//  RSCommonAppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 8/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#define USE_SYNCSERVICES 0

#import <Cocoa/Cocoa.h>
#if USE_SYNCSERVICES
#import <SyncServices/SyncServices.h>
#endif // USE_SYNCSERVICES

#if USE_SYNCSERVICES
@interface RSCommonAppDelegate : NSObject <NSPersistentStoreCoordinatorSyncing>
#else
@interface RSCommonAppDelegate : NSObject
#endif // USE_SYNCSERVICES
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
