//
//  recsched_bkgd_AppDeleggate.m
//  recsched
//
//  Created by Andrew Kimpton on 6/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"

NSString *kRecSchedUIAppBundleID = @"org.awkward.recsched";
NSString *kRecSchedServerBundleID = @"org.awkward.recsched-server";
NSString *kRecServerConnectionName = @"recsched_bkgd_server";

NSString *kWebServicesZap2ItUsernamePrefStr = @"zap2itUsername";			// Here because we don't link Preferences.m into the server

@implementation recsched_bkgd_AppDelegate

/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "recsched" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"recsched"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
	NSLog(@"recsched_bkgd_AppDelegate - applicationDidFinishLaunching");
	[[self syncClient] setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
	
	[mRecSchedServer updateSchedule];
	
	[self syncAction:nil];
}

- (id) init {
  self = [super init];
  if (self != nil) 
  {
	// Now register the server
    NSConnection *theConnection;

    theConnection = [NSConnection defaultConnection];
    mRecSchedServer = [[RecSchedServer alloc] init];
    [theConnection setRootObject:mRecSchedServer];
    if ([theConnection registerName:kRecServerConnectionName] == NO) 
    {
            /* Handle error. */
            NSLog(@"Error registering connection");
            return nil;
    }
  }
  return self;
}

#pragma mark - CoreData Methods

/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle and all of the 
    framework bundles.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    NSMutableSet *allBundles = [[NSMutableSet alloc] init];
    [allBundles addObject: [NSBundle mainBundle]];
    [allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"recsched_bkgd.dat"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
    if (store != nil)
	{
		NSURL *fastSyncDetailURL;
        fastSyncDetailURL = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"org.awkward.recsched-server.fastsyncstore"]];
        [persistentStoreCoordinator setStoresFastSyncDetailsAtURL:fastSyncDetailURL forPersistentStore:store];
	}
	else
	{
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  
//                NSArray *detailedErrors = [[error userInfo] valueForKey:@"NSDetailedErrors"];

                NSLog(@"applicationShouldTerminate - errors in Managed Object Context - %@", error);
                reply = NSTerminateNow;
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}


/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {

    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
    [super dealloc];
}

#pragma mark Sync

- (ISyncClient *)syncClient
{
    NSString *clientIdentifier = kRecSchedServerBundleID;
    NSString *reason = @"unknown error";
    ISyncClient *client;

    @try {
        client = [[ISyncManager sharedManager] clientWithIdentifier:clientIdentifier];
        if (nil == client) {
//            if (![[ISyncManager sharedManager] registerSchemaWithBundlePath:[[NSBundle mainBundle] pathForResource:@"recsched" ofType:@"syncschema"]]) {
//                reason = @"error registering the recsched sync schema";
//            } 
//			else 
			{
                client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientIdentifier descriptionFilePath:[[NSBundle mainBundle] pathForResource:@"ClientDescription_Server" ofType:@"plist"]];
                [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeApplication];
                [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeDevice];
                [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeServer];
                [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypePeer];
            }
        }
    }
    @catch (id exception) {
        client = nil;
        reason = [exception reason];
    }

    if (nil == client) {
        NSRunAlertPanel(@"You can not sync your recsched data.", [NSString stringWithFormat:@"Failed to register the sync client: %@", reason], @"OK", nil, nil);
    }
    
    return client;
}

- (void)client:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames
{
	// Since we save the store after each significant update (after downloading new schedule data for example)
	// the store on disk is always as up to date as we can make it and there's no need to sync it here.
	NSLog(@"syncing with client %@", [client displayName]);
	NSError *error;
	[[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:NO handler:self error:&error];
    if (nil != error) {
        NSLog(@"client: mightWantToSyncEntityNames: - error occured - %@", error);
    }
}

- (NSArray *)managedObjectContextsToMonitorWhenSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *aContext = [self managedObjectContext];
    return [NSArray arrayWithObject:aContext];
}

- (NSArray *)managedObjectContextsToReloadAfterSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	NSManagedObjectContext *aContext = [self managedObjectContext];
    return [NSArray arrayWithObject:aContext];
}

- (NSDictionary *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willPushRecord:(NSDictionary *)record forManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
//		NSLog(@"push %@ = %@", [managedObject objectID], [record description]);
    return record;
}

- (ISyncChange *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willApplyChange:(ISyncChange *)change toManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
//		NSLog(@"pull %@", [change description]);
    return change;
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willPushChangesInSyncSession:(ISyncSession *)session
{
	NSLog(@"willPushChangesInSyncSession - session = %@", session);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didPushChangesInSyncSession:(ISyncSession *)session
{
	NSLog(@"didPushChangesInSyncSession - session = %@", session);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willPullChangesInSyncSession:(ISyncSession *)session
{
	NSLog(@"willPullChangesInSyncSession - session = %@", session);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didPullChangesInSyncSession:(ISyncSession *)session
{
	NSLog(@"didPullChangesInSyncSession - session = %@", session);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didCancelSyncSession:(ISyncSession *)session error:(NSError *)error
{
	NSLog(@"didCancelSyncSession - error = %@", error);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didFinishSyncSession:(ISyncSession *)session
{
	NSLog(@"didFinishSyncSession - session = %@", session);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didCommitChanges:(NSDictionary *)changes inSyncSession:(ISyncSession *)session
{
	NSLog(@"didCommitChanges - session = %@", session);
}

#pragma mark Notifications

- (void) updateForSavedContext:(NSNotification *)notification
{
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];

//	[self syncAction:self];
}


#pragma mark Actions

- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)syncAction:(id)sender
{
    NSError *error = nil;
    ISyncClient *client = [self syncClient];
    if (nil != client) {
        [[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:NO handler:self error:&error];
    }
    if (nil != error) {
        NSLog(@"syncAction - error occured - %@", error);
    }
}

@end
