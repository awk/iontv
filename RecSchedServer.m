//
//  RecSchedServer.m
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RecSchedServer.h"

#import "HDHomeRunMO.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "XTVDParser.h"
#import "RecordingThread.h"

NSString *kRecSchedUIAppBundleID = @"org.awkward.recsched";
NSString *kRecSchedServerBundleID = @"org.awkward.recsched-server";

@implementation RecSchedServer

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

- (id) init {
  self = [super init];
  if (self != nil) {
    mExitServer = NO;
	
	[[self syncClient] setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
	[self syncAction:nil];
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
	
	managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle bundleWithIdentifier:kRecSchedUIAppBundleID]]] retain];

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
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
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
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
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
            if (![[ISyncManager sharedManager] registerSchemaWithBundlePath:[[NSBundle bundleWithIdentifier:kRecSchedUIAppBundleID] pathForResource:@"recsched" ofType:@"syncschema"]]) {
                reason = @"error registering the recsched sync schema";
            } else {
                client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientIdentifier descriptionFilePath:[[NSBundle bundleWithIdentifier:kRecSchedUIAppBundleID] pathForResource:@"ClientDescription" ofType:@"plist"]];
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
    NSLog(@"Saving for alert to sync...");
	[self saveAction:self];
}

- (NSArray *)managedObjectContextsToMonitorWhenSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [NSArray arrayWithObject:[self managedObjectContext]];
}

- (NSArray *)managedObjectContextsToReloadWhenSyncingPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    return [NSArray arrayWithObject:[self managedObjectContext]];
}

- (NSDictionary *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willPushRecord:(NSDictionary *)record forManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
    NSLog(@"push %@ = %@", [managedObject objectID], [record description]);
    return record;
}

- (ISyncChange *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willApplyChange:(ISyncChange *)change toManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
    NSLog(@"pull %@", [change description]);
    return change;
}


#pragma mark - Server Methods

- (bool) shouldExit
{
	return mExitServer;
}

- (void)syncAction:(id)sender
{
    NSError *error = nil;
    ISyncClient *client = [self syncClient];
    if (nil != client) {
        [[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:YES handler:self error:&error];
    }
    if (nil != error) {
        NSLog(@"syncAction - error occured - %@", error);
    }
}

- (BOOL) addRecordingOfProgram:(NSManagedObject*) aProgram
            withSchedule:(NSManagedObject*)aSchedule
{
  Z2ITStation *aStation = [(Z2ITSchedule *)aSchedule station];
  Z2ITProgram *myProgram = [Z2ITProgram fetchProgramWithID:[(Z2ITProgram *)(aProgram) programID] inManagedObjectContext:[self managedObjectContext]];
  NSSet *mySchedules = [myProgram schedules];
  NSEnumerator *anEnumerator = [mySchedules objectEnumerator];
  Z2ITSchedule *mySchedule = nil;
  BOOL foundMatch = NO;
  while (mySchedule = [anEnumerator nextObject])
  {
    // Compare with time intervals since that will take into account any timezone discrepancies
    if (([[aStation stationID] intValue] == [[[mySchedule station] stationID] intValue]) && ([[mySchedule time] timeIntervalSinceDate:[(Z2ITSchedule*)aSchedule time]] == 0))
    {
      foundMatch = YES;
      break;
    }
  }
  if (foundMatch)
  {
    [[RecordingThreadController alloc]initWithProgram:myProgram andSchedule:mySchedule];
    return YES;
  }
  else
  {
    NSLog(@"Could not find matching local schedule for the program");
    return NO;
  }
}

- (BOOL) addRecordingWithName:(NSString*) name
{
	NSLog(@"addRecordingWithName - name  = %@", name);
	return YES;
}

- (void) performParse:(NSDictionary *)parseInfo
{
  NSDictionary *newParseInfo = [NSDictionary dictionaryWithObjectsAndKeys:[parseInfo objectForKey:@"xmlFilePath"], @"xmlFilePath", self, @"reportCompletionTo", [self persistentStoreCoordinator], @"persistentStoreCoordinator", NULL];
  
  NSLog(@"performParse - newParseInfo = %@", newParseInfo);
//  [NSThread detachNewThreadSelector:@selector(performParse:) toTarget:[xtvdParseThread class] withObject:newParseInfo];
}

- (void) quitServer:(id)sender
{
  if ([self applicationShouldTerminate:[NSApplication sharedApplication]])
  {
    NSLog(@"Server shutting down");
    mExitServer = YES;
  }
}

#pragma Callback Methods

- (void) parsingComplete:(id)info
{
  NSLog(@"parsingComplete");
  // Clear all old items from the store
//  CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//  NSDate *currentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:currentTime];
//  NSDictionary *callData = [[NSDictionary alloc] initWithObjectsAndKeys:currentDate, @"currentDate", self, @"reportCompletionTo", [self persistentStoreCoordinator], @"persistentStoreCoordinator", nil];

//  [NSThread detachNewThreadSelector:@selector(performCleanup:) toTarget:[xtvdCleanupThread class] withObject:callData];
}

- (void) cleanupComplete:(id)info
{
  NSLog(@"cleanupComplete");
}

@end
