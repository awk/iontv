//
//  recsched_AppDelegate.m
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import "recsched_AppDelegate.h"
#import "RecSchedNotifications.h"
#import "Preferences.h"
#import "HDHomeRunMO.h"
#import "HDHomeRunTuner.h"
#import "RecSchedProtocol.h"

NSString *kRecServerConnectionName = @"recsched_bkgd_server";

@implementation recsched_AppDelegate

- (void) initializeServerConnection
{
  // Connect to server
  mRecServer = [[NSConnection rootProxyForConnectionWithRegisteredName:kRecServerConnectionName  host:nil] retain];
   
  // check if connection worked.
  if (mRecServer == nil) 
  {
    NSLog(@"couldn't connect with server\n");
    [mServerMenuItem setTitle:@"Connect to Server"];
  }
  else
  {
    //
    // set protocol for the remote object & then register ourselves with the 
    // messaging server.
    [mRecServer setProtocolForProxy:@protocol(RecSchedServerProto)];
    [mServerMenuItem setTitle:@"Exit Server"];
  }
}

- (void) awakeFromNib
{
  if (mRecServer)
  {
    [mServerMenuItem setTitle:@"Exit Server"];
  }
  else
  {
    [mServerMenuItem setTitle:@"Connect to Server"];
  }
  
}

- (id) init {
  self = [super init];
  if (self != nil) {
    [Preferences setupDefaults];
    [self initializeServerConnection];
  }
  return self;
}

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
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"recsched.dat"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
    if (store != nil)
	{
		NSURL *fastSyncDetailURL;
        fastSyncDetailURL = [NSURL fileURLWithPath:[applicationSupportFolder stringByAppendingPathComponent:@"org.awkward.recsched.fastsyncstore"]];
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
        
        // We may change the store in a seperate thread (when fetching for instance) in which case
        // the store should overwrite any changes made locally within the receivers context
        [managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
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

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
    [[self syncClient] setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
    [self syncAction:nil];
}

#pragma mark Sync

- (ISyncClient *)syncClient
{
    NSString *clientIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *reason = @"unknown error";
    ISyncClient *client;

    @try {
        client = [[ISyncManager sharedManager] clientWithIdentifier:clientIdentifier];
        if (nil == client) {
            if (![[ISyncManager sharedManager] registerSchemaWithBundlePath:[[NSBundle mainBundle] pathForResource:@"recsched" ofType:@"syncschema"]]) {
                reason = @"error registering the recsched sync schema";
            } else {
                client = [[ISyncManager sharedManager] registerClientWithIdentifier:clientIdentifier descriptionFilePath:[[NSBundle mainBundle] pathForResource:@"ClientDescription" ofType:@"plist"]];
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

	NSLog(@"syncing with client %@ for entityNames %@", client, entityNames);
	NSError *error;
	[[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:YES handler:self error:&error];
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
//    NSLog(@"push %@ = %@", [managedObject objectID], [record description]);
    return record;
}

- (ISyncChange *)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator willApplyChange:(ISyncChange *)change toManagedObject:(NSManagedObject *)managedObject inSyncSession:(ISyncSession *)session
{
//    NSLog(@"pull %@", [change description]);
    return change;
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didCancelSyncSession:(ISyncSession *)session error:(NSError *)error
{
	NSLog(@"didCancelSyncSession - error = %@", error);
}

- (void)persistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator didFinishSyncSession:(ISyncSession *)session
{
	NSLog(@"didFinishSyncSession");
}

#pragma mark - Actions

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
	else
	{
        [self syncAction:sender];
    }
}

- (void)syncAction:(id)sender
{
    NSError *error = nil;
    ISyncClient *client = [self syncClient];
    if (nil != client) {
        [[[self managedObjectContext] persistentStoreCoordinator] syncWithClient:client inBackground:YES handler:self error:&error];
    }
    if (nil != error) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)showCoreDataProgramWindow:(id)sender
{
	[mCoreDataProgramWindow makeKeyAndOrderFront:sender];
}

- (IBAction) launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow
{
  if (mVLCTask && [mVLCTask isRunning])
  {
    // VLC Already seems to be running (from a prior launch) - we can ignore this request to launch.
    // It would be nice if there was a way to just switch the data in the stream and have VLC resync etc.
    // however that doesn't appear to be possible so instead we must quit and relaunch VLC :-(
    [mVLCTask terminate];
    return;
  }
  
  @try
  {
    NSString *vlcPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"VLCAppPath"];
    if (!vlcPath)
      vlcPath = [NSString stringWithString:@"/Applications/VLC.app/Contents/MacOS/VLC"];
    mVLCTask = [[NSTask launchedTaskWithLaunchPath:vlcPath arguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"udp://@:%d", kDefaultPortNumber], nil]] retain];
    if (mVLCTask)
    {
      // Launch successful - store the default path
      [[NSUserDefaults standardUserDefaults] setObject:vlcPath forKey:@"VLCAppPath"];
      [[NSUserDefaults standardUserDefaults] synchronize];

      // Register to watch for the termination notice
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vlcTaskDidTerminate:) name:NSTaskDidTerminateNotification object:mVLCTask];

      sleep(2);   // Wait for things to settle
    }
  }
  @catch (NSException *exception)
  {
    if ([exception name] == NSInvalidArgumentException)
    {
      NSArray *appPaths;
      
      appPaths = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,NSSystemDomainMask,true);
      
      if ([appPaths count] > 0)
      {
        [[NSOpenPanel openPanel]  // Get the shared open panel
          beginSheetForDirectory:[appPaths objectAtIndex:0]  // Point it at the apps directory
          file:nil
          types:[NSArray arrayWithObjects:@"app", nil]
          modalForWindow:inParentWindow  // This makes it show up as a sheet, attached to window
          modalDelegate:self    // Tell me when you're done.
          didEndSelector:@selector(findVLCPanelDidEnd:returnCode:contextInfo:)  // Call this method when you're done..
          contextInfo:sender];  
      }
    }
  }
}

- (void)findVLCPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
  if (returnCode == NSOKButton)
  {
    NSString *vlcPath = [NSString stringWithFormat:@"%@/Contents/MacOS/VLC", [panel filename]];
    mVLCTask = [[NSTask launchedTaskWithLaunchPath:vlcPath arguments:[NSArray arrayWithObjects:@"udp://@:1234", nil]] retain];
    if (mVLCTask)
    {
      // Launch successful - store the default path
      [[NSUserDefaults standardUserDefaults] setObject:vlcPath forKey:@"VLCAppPath"];
      [[NSUserDefaults standardUserDefaults] synchronize];

      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vlcTaskDidTerminate:) name:NSTaskDidTerminateNotification object:mVLCTask];

      sleep(2);   // Wait for things to settle
    }
  }
}

- (IBAction) launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow startStreaming:(HDHomeRunStation*)inStation
{
  if (mVLCTask && [mVLCTask isRunning])
  {    
    // VLC Already seems to be running (from a prior launch) - we can ignore this request to launch.
    // It would be nice if there was a way to just switch the data in the stream and have VLC resync etc.
    // however that doesn't appear to be possible so instead we must quit and relaunch VLC :-(
    [mVLCTask terminate];
  
    // Set up a timer to fire in 5 seconds (or sooner !) to either start streaming or to give up because
    // VLC hasn't terminated
    mVLCTerminateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(vlcTerminationTimer:) userInfo:[inStation retain] repeats:NO];
    return;
  }

  mVLCTerminateTimer = nil;
  [self launchVLCAction:sender withParentWindow:inParentWindow];
  
  if (mVLCTask)
    [inStation startStreaming];
}

- (IBAction) quitServer:(id)sender
{
  if (mRecServer)
  {
    [mRecServer quitServer:sender];
    mRecServer = nil;
    [mServerMenuItem setTitle:@"Connect to Server"];
  }
  else
  {
    [self initializeServerConnection];
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
                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}

- (void) updateForSavedContext:(NSSet *)updatedObjects
{
    // enumerate the list
    NSEnumerator *enumerator = [updatedObjects objectEnumerator];
    NSManagedObject *updatedObject, *staleObject;
	NSManagedObjectID *updatedObjectID;
    while ((updatedObjectID = [enumerator nextObject]) != nil) {

        // if the object that was updated (in the recipe context) also has been fetched into the app delegate 
        // context, we want to refresh the object merging in the changes from the persistent store. Otherwise
        // the information will look out of date.
        staleObject = [[self managedObjectContext] objectRegisteredForID:updatedObjectID/*[updatedObject objectID]*/];
        if (staleObject != nil) 
        {
            [[self managedObjectContext] refreshObject:staleObject mergeChanges:NO];   
        }
        else
        {
          staleObject = [[self managedObjectContext] objectWithID:updatedObjectID/*[updatedObject objectID]*/];
        }
//		NSLog(@"updateForSavedContext - staleObject = %@", staleObject);
    }    
    
    // Lastly do a 'performPendingChanges' to make sure everything is picked up correctly - in particular that
    // any new data added in the save (which doesn't appear in the updatedObjects set - it's NEW after all) is
    // reflected in the UI.
    [[self managedObjectContext] processPendingChanges];
    
    // And notifiy everyone else a save just occured - which probably means new objects were added to this context
    [[NSNotificationCenter defaultCenter] postNotificationName:RSNotificationManagedObjectContextUpdated object:[self managedObjectContext]];
	
	[self syncAction:self];
}

#pragma mark - Notifications

- (void)vlcTerminationTimer:(NSTimer*)theTimer
{
  HDHomeRunStation *theStation = [theTimer userInfo];
  
  if (mVLCTask == nil)
  {
    [self launchVLCAction:self withParentWindow:nil];
    [theStation startStreaming];
  }
  
  [theStation release];
  mVLCTerminateTimer  = nil;
}

/**
    Notification sent out when the VLC task terminates (either from quit being sent a terminate message).
*/

- (void)vlcTaskDidTerminate:(NSNotification *)notification
{
  // Remove ourselves - this only happens once
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:mVLCTask];
  
  mVLCTask = nil;
  
  if (mVLCTerminateTimer)
  {
    [mVLCTerminateTimer fire];    // fire the terminate timer earlier (since we know it's definately done)
  }
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

@end
