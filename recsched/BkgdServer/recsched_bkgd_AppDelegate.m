//  recsched_bkgd - Background server application retrieves schedule data, performs recordings,
//  transcodes recordings in to H.264 format for iTunes, iPod etc.
//
//  Copyright (C) 2007 Andrew Kimpton
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSNotifications.h"
#import "RSRecording.h"
#import "RecordingThread.h"

#import "PreferenceKeys.h"    // For the key values in the shared preferences

NSString *kRecSchedUIAppBundleID = @"org.awkward.recsched";
NSString *kRecSchedServerBundleID = @"org.awkward.recsched-server";

@implementation recsched_bkgd_AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  // We use the same presets as Handbrake and just read their plist
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
  NSString *presetsPath = [basePath stringByAppendingPathComponent:@"HandBrake/UserPresets.plist"];

  // So we should make sure it's there before we try and use it...
  if ([[NSFileManager defaultManager] fileExistsAtPath:presetsPath] == NO) {
    NSError *error = nil;
    if ([[NSFileManager defaultManager] contentsOfDirectoryAtPath:[basePath stringByAppendingPathComponent:@"HandBrake"] error:&error] == nil) {
      [[NSFileManager defaultManager] createDirectoryAtPath:[basePath stringByAppendingPathComponent:@"HandBrake"] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    // Copy a set of defaults from the resources folder
    NSString *defaultPresetsPath = [[NSBundle mainBundle] pathForResource:@"UserPresets" ofType:@"plist"];
    [[NSFileManager defaultManager] copyItemAtPath:defaultPresetsPath toPath:presetsPath error:&error];
  }

  if ([self storeNeedsMigrating]) {
    [self migrateStore];
  } else {
    [self performSelector:@selector(beginFetchingSchedules:) withObject:nil afterDelay:0];
  }
}

- (void)beginFetchingSchedules:(id)unused {
  // This will update the next 'n' hours worth of schedule data, we don't need to do it 'now' rather we can just schedule a
  // timer for a little ways off (about 1 hour less than the default schedule retrieval duration)
  [NSTimer scheduledTimerWithTimeInterval:(kDefaultUpdateScheduleFetchDurationInHours - 1) * 60 * 60 target:mRecSchedServer selector:@selector(updateScheduleTimer:) userInfo:nil repeats:NO];

  // We also need to the set the ball rolling on fetching all the schedule data for the next 2 weeks
  [mRecSchedServer fetchFutureSchedule:nil];
}

- (void)setupPreferences {
  // Setup the preferences - we share our prefs with those of the main app.
  NSUserDefaults *stdUserDefaults = [NSUserDefaults standardUserDefaults];
  [stdUserDefaults addSuiteNamed:@"org.awkward.iontv"];

  // load the default values for the user defaults
  NSString *userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefaults"
                                                                   ofType:@"plist"];
  NSDictionary *userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];

  // Set up the default location for the recorded (and transcoded) programs location.
  NSString *homeDir = NSHomeDirectory();
  NSString *moviesDir = [homeDir stringByAppendingPathComponent:@"Movies"];
  NSURL *moviesFolderURL = [[[NSURL alloc] initFileURLWithPath:moviesDir isDirectory:YES] autorelease];
  NSString *moviesFolder = [moviesFolderURL absoluteString];
  [userDefaultsValuesDict setValue:moviesFolder forKey:kRecordedProgramsLocationKey];
  [userDefaultsValuesDict setValue:moviesFolder forKey:kTranscodedProgramsLocationKey];

  // set them in the standard user defaults
  [stdUserDefaults registerDefaults:userDefaultsValuesDict];
}

- (id) init {
  self = [super init];
  if (self != nil) {
    // Now register the server
    NSConnection *theConnection;

    theConnection = [[NSConnection new] autorelease];
    mRecSchedServer = [[RecSchedServer alloc] init];
    [theConnection setRootObject:mRecSchedServer];
    if ([theConnection registerName:kRecServerConnectionName] == NO)  {
      /* Handle error. */
      NSLog(@"Error registering connection");
      return nil;
    }
    // Set up the preferences
    [self setupPreferences];
  }
  return self;
}

- (NSURL *)urlForPersistentStore {
  return [NSURL fileURLWithPath: [[self applicationSupportFolder] stringByAppendingPathComponent: @"recsched_bkgd.dat"]];
}

- (RecSchedServer *)recServer {
  return mRecSchedServer;
}

#pragma mark Actions

- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
      [[NSApp delegate] presentError:error];
    }
}

#pragma mark Callbacks and Notifications

- (void)updateForSavedContext:(NSNotification *)notification {
  [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath compare:@"migrationProgress"] == NSOrderedSame) {
    if (mMigrationActivityToken) {
      mMigrationActivityToken = [[[self recServer] uiActivity] setActivity:mMigrationActivityToken progressDoubleValue:[object migrationProgress]];
    } else {
      NSLog(@"Progress is %.2f%", [object migrationProgress] * 100.0);
    }
  }

  if ([keyPath compare:@"currentEntityMapping"] == NSOrderedSame) {
    if (mMigrationActivityToken) {
      mMigrationActivityToken = [[[self recServer] uiActivity] setActivity:mMigrationActivityToken
                                                                infoString:[NSString stringWithFormat:@"Currently Migrating %@ Data",
                                                                            [[object currentEntityMapping] destinationEntityName]]];
    } else {
      NSLog(@"Current Entity is %@ -> %@", [[object currentEntityMapping] sourceEntityName], [[object currentEntityMapping] destinationEntityName]);
    }
  }
}

#pragma mark Migration

- (BOOL) migrateStore
{
  NSArray *bundlesForSourceModel = nil;
  NSURL *url = [self urlForPersistentStore];
  NSError *error = nil;

  mMigrationInProgress = YES;

  NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                            URL:url
                                                                                          error:&error];

  NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundlesForSourceModel
                                                                  forStoreMetadata:sourceMetadata];

  NSPersistentStoreCoordinator *aPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
  NSManagedObjectModel *destinationModel = [aPersistentStoreCoordinator managedObjectModel];
  [aPersistentStoreCoordinator release];
  aPersistentStoreCoordinator = nil;

  if (sourceModel == nil)
  {
    NSLog(@"Unable to find source model for migration");
    return NO;
  }

  NSMigrationManager *migrationManager = [[[NSMigrationManager alloc] initWithSourceModel:sourceModel
                                                                        destinationModel:destinationModel] autorelease];

  NSArray *bundlesForMappingModel = nil;

  NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:bundlesForMappingModel
                                                          forSourceModel:sourceModel
                                                        destinationModel:destinationModel];

  if (mappingModel == nil)
  {
    NSLog(@"Unable to find mapping model for migration");
    return NO;
  }

  // Migrate the store from the original path to a new destination. We'll move the result of the
  // migration back to the real location when it's complete. This allows the UI app to launch after
  // the background app, find that a migration is needed and then wait for it to complete.
  NSURL *sourceURL = [self urlForPersistentStore];
  NSString *destinationPath = [NSString stringWithFormat:@"%@_mig.dat", [[sourceURL path] stringByDeletingPathExtension]];
  NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath isDirectory:NO];

  // Create the activity to notify the UI App
  mMigrationActivityToken = [[[self recServer] uiActivity] createActivity];
  if (mMigrationActivityToken)
  {
    mMigrationActivityToken = [[[self recServer] uiActivity] setActivity:mMigrationActivityToken progressMaxValue:1.0];
  }
  // Watch for changes to the migration progress.
  [migrationManager addObserver:self forKeyPath:@"migrationProgress" options:0 context:(void*)mMigrationActivityToken];
  [migrationManager addObserver:self forKeyPath:@"currentEntityMapping" options:0 context:(void*)mMigrationActivityToken];

  NSDictionary *sourceStoreOptions = nil;
  NSString *destinationStoreType = NSSQLiteStoreType;
  NSString *sourceStoreType = NSSQLiteStoreType;
  NSDictionary *destinationStoreOptions = nil;
  SEL migrateStoreSel = @selector(migrateStoreFromURL:type:options:withMappingModel:toDestinationURL:destinationType:destinationOptions:error:);
  NSMethodSignature *migrateStoreFromURLSignature = [migrationManager methodSignatureForSelector:migrateStoreSel];
  NSInvocation *migrationStoreInvocation = [NSInvocation invocationWithMethodSignature:migrateStoreFromURLSignature];
  NSError **errorPointer = &error;

  [migrationStoreInvocation setSelector:migrateStoreSel];
  [migrationStoreInvocation setTarget:migrationManager];
  [migrationStoreInvocation setArgument:&sourceURL atIndex:2];
  [migrationStoreInvocation setArgument:&sourceStoreType atIndex:3];
  [migrationStoreInvocation setArgument:&sourceStoreOptions atIndex:4];
  [migrationStoreInvocation setArgument:&mappingModel atIndex:5];
  [migrationStoreInvocation setArgument:&destinationURL atIndex:6];
  [migrationStoreInvocation setArgument:&destinationStoreType atIndex:7];
  [migrationStoreInvocation setArgument:&destinationStoreOptions atIndex:8];
  [migrationStoreInvocation setArgument:&errorPointer atIndex:9];

  [migrationStoreInvocation retainArguments];

  [NSThread detachNewThreadSelector:@selector(migrationThread:) toTarget:self withObject:migrationStoreInvocation];
  return YES;
}

- (void) migrationThread:(id)migrationInfo
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSInvocation *invocation = (NSInvocation*)migrationInfo;

  [invocation invoke];

  unsigned int length = [[invocation methodSignature] methodReturnLength];
  void *buffer = (void *)malloc(length);
  [invocation getReturnValue:buffer];

  BOOL ok = *((BOOL*)buffer);
  free(buffer);

  [self performSelectorOnMainThread:@selector(migrationComplete:) withObject:[NSNumber numberWithBool:ok] waitUntilDone:NO];

  [pool release];
}

- (BOOL)migrationInProgress {
  return mMigrationInProgress;
}

- (void)migrationComplete:(NSNumber *)status {
  NSError *error = nil;
  NSString *originalPath = [[self urlForPersistentStore] path];
  NSString *legacyPath = [NSString stringWithFormat:@"%@~", originalPath];
  NSString *migrationPath = [NSString stringWithFormat:@"%@_mig.dat", [[[self urlForPersistentStore] path] stringByDeletingPathExtension]];
  BOOL success = NO;

  // Remove any old backup file if present
  if ([[NSFileManager defaultManager] isDeletableFileAtPath:legacyPath]) {
    [[NSFileManager defaultManager] removeItemAtPath:legacyPath error:&error];
  }

  // Move the original source datastore to the backup location
  success = [[NSFileManager defaultManager] moveItemAtPath:originalPath toPath:legacyPath error:&error];

  if (!success) {
    NSLog(@"Unable to move CoreData Store to backup location after migration - error = %@", error);
  }

  // Move the migrated datastore to the original location
  success = [[NSFileManager defaultManager] moveItemAtPath:migrationPath toPath:originalPath error:&error];
  if (!success) {
    NSLog(@"Unable to move CoreData Store from migration location after migration, restoring backup - error = %@", error);
    [[NSFileManager defaultManager] moveItemAtPath:legacyPath toPath:originalPath error:&error];
    return;
  }


  mMigrationInProgress = NO;

  if (mMigrationActivityToken) {
    [[[self recServer] uiActivity] endActivity:mMigrationActivityToken];
    mMigrationActivityToken = 0;
  }

  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:RSMigrationCompleteNotification object:RSBackgroundApplication];

  [self beginFetchingSchedules:nil];
}

@end
