//  Copyright (c) 2007, Andrew Kimpton
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "RSCommonAppDelegate.h"
#import "PreferenceKeys.h"

NSString *kRecServerConnectionName = @"recsched_bkgd_server";
NSString *kRecUIActivityConnectionName = @"recsched_ui_activity";
NSString *kRSStoreUpdateConnectionName = @"resched_store_update";

@implementation RSCommonAppDelegate

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

- (NSURL *)urlForPersistentStore {
	return nil;
}

- (NSURL*)urlForFastSyncStore {
	return nil;
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
	// Sometimes when running from debugging tools main bundle will not be the 'right thing', rather
	// our bundle will be present in the system independantly - so add it here (if it's known).
	if ([NSBundle bundleWithIdentifier:@"org.awkward.recsched-server"])
		[allBundles addObject: [NSBundle bundleWithIdentifier:@"org.awkward.recsched-server"]];
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
    
    url = [self urlForPersistentStore]; //[NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"recsched_bkgd.dat"]];
  
    // Do we need to migrate the store to a new model version ?
    if ([self storeNeedsMigrating])
    {
      NSLog(@"persistentStoreCoordinator - store needs migrating !");
      return nil;
    }
    else
    {
      // no need to migrate
      persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
      persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
      if (persistentStore == nil)
      {
          [[NSApplication sharedApplication] presentError:error];
      }    
      return persistentStoreCoordinator;
    }
}

- (NSPersistentStore*) persistentStore
{
	if (persistentStore != nil)
	{
		return persistentStore;
	}
	[self persistentStoreCoordinator];
	if (persistentStore)
		return persistentStore;
	else
		NSLog(@"ERROR - No Persistent Store after initializing coordinator !");
	return nil;
}


- (NSDictionary *) persistentStoreMetadata
{
   return [[self persistentStoreCoordinator] metadataForPersistentStore:[self persistentStore]];
}

- (BOOL) storeNeedsMigrating
{
  NSURL *url = [self urlForPersistentStore];
  NSError *error = nil;
  
  // Do we need to migrate the store to a new model version ?
  NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                            URL:url
                                                                                          error:&error];
   
  if (sourceMetadata == nil) {
      // Having no source metadata isn't a fatal error it just means that the source didn't exist
      // no need to migrate - nothing to migrate from !
      return NO;
  }
   
  NSPersistentStoreCoordinator *aPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
  NSManagedObjectModel *destinationModel = [aPersistentStoreCoordinator managedObjectModel];
  BOOL pscCompatibile = [destinationModel isConfiguration:nil
                              compatibleWithStoreMetadata:sourceMetadata];
  [aPersistentStoreCoordinator release];                                
  return !pscCompatibile;
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

- (NSString *) SDPasswordForUsername:(NSString *)username
{
   const char *serverNameUTF8 = [kWebServicesSDHostname UTF8String];
   const char *accountNameUTF8 = [username UTF8String];
   const char *pathUTF8 = [kWebServicesSDPath UTF8String];
   UInt32 passwordLength;
   void *passwordData;
   SecKeychainItemRef SDKeychainItemRef;
   OSStatus status = SecKeychainFindInternetPassword(NULL,
                                                     strlen(serverNameUTF8),
                                                     serverNameUTF8,
                                                     0, NULL,
                                                     strlen(accountNameUTF8), accountNameUTF8,
                                                     strlen(pathUTF8), pathUTF8,
                                                     80, kSecProtocolTypeHTTP,
                                                     kSecAuthenticationTypeDefault,
                                                     &passwordLength, &passwordData,
                                                     &SDKeychainItemRef);
   NSString *passwordString = nil;
   
   if (status == noErr)
   {
      char *utf8String = malloc(passwordLength+1);
      memset(utf8String, 0, passwordLength+1);
      memcpy(utf8String, passwordData, passwordLength);
		passwordString = [NSString stringWithUTF8String:utf8String];
      free(utf8String);
      SecKeychainItemFreeContent(NULL, passwordData);
   }
   return passwordString;
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
