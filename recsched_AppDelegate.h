//
//  recsched_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface recsched_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    IBOutlet NSWindow *mCoreDataProgramWindow;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)showCoreDataProgramWindow:(id)sender;

@end
