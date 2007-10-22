//
//  recsched_bkgd_AppDeleggate.m
//  recsched
//
//  Created by Andrew Kimpton on 6/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "recsched_bkgd_AppDelegate.h"
#import "RecSchedServer.h"
#import "RSRecording.h"
#import "RecordingThread.h"
#import "RSTranscodeController.h"

#import "PreferenceKeys.h"		// For the key values in the shared preferences

NSString *kRecSchedUIAppBundleID = @"org.awkward.recsched";
NSString *kRecSchedServerBundleID = @"org.awkward.recsched-server";

@implementation recsched_bkgd_AppDelegate

- (void) startTimersForRecordings
{
	NSArray *futureRecordings = [RSRecording fetchRecordingsInManagedObjectContext:[[NSApp delegate] managedObjectContext] afterDate:[NSDate date] withStatus:RSRecordingNotYetStartedStatus];
	for (RSRecording *aRecording in futureRecordings)
	{
		[[RecordingThreadController alloc] initWithRecording:aRecording recordingServer:mRecSchedServer];
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
	NSLog(@"recsched_bkgd_AppDelegate - applicationDidFinishLaunching");
#if USE_SYNCSERVICES
	[[self syncClient] setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
#endif // USE_SYNCSERVICES

	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kTranscodeProgramsKey] boolValue] == YES)
		mTranscodeController = [[RSTranscodeController alloc] init];
	
	[mRecSchedServer updateSchedule];
	[self startTimersForRecordings];
}

- (void) setupPreferences
{
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
	NSURL *moviesFolderURL = [[NSURL alloc] initFileURLWithPath:moviesDir isDirectory:YES];
	NSString *moviesFolder = [moviesFolderURL absoluteString];
	[userDefaultsValuesDict setValue:moviesFolder forKey:kRecordedProgramsLocationKey];
	[userDefaultsValuesDict setValue:moviesFolder forKey:kTranscodedProgramsLocationKey];

	// set them in the standard user defaults
	[stdUserDefaults registerDefaults:userDefaultsValuesDict];
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
	// Set up the preferences
	[self setupPreferences];
  }
  return self;
}

- (NSURL *)urlForPersistentStore {
	return [NSURL fileURLWithPath: [[self applicationSupportFolder] stringByAppendingPathComponent: @"recsched_bkgd.dat"]];
}

- (RecSchedServer*) recServer
{
	return mRecSchedServer;
}

#if USE_SYNCSERVICES
- (NSURL*)urlForFastSyncStore {
	return [NSURL fileURLWithPath:[[self applicationSupportFolder] stringByAppendingPathComponent:@"org.awkward.recsched-server.fastsyncstore"]];
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
#endif // USE_SYNCSERVICES

#pragma mark Actions

- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApp delegate] presentError:error];
    }
}

#if USE_SYNCSERVICES
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
#endif // USE_SYNCSERVICES

#pragma Callbacks and Notifications

- (void) updateForSavedContext:(NSNotification *)notification
{
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

@end
