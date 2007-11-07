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
	// We use the same presets as Handbrake and just read their plist
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	NSString *presetsPath = [basePath stringByAppendingPathComponent:@"HandBrake/UserPresets.plist"];

	// So we should make sure it's there before we try and use it...
	if ([[NSFileManager defaultManager] fileExistsAtPath:presetsPath] == NO)
	{
		// Copy a set of defaults from the resources folder
		NSString *defaultPresetsPath = [[NSBundle mainBundle] pathForResource:@"UserPresets" ofType:@"plist"];
		[[NSFileManager defaultManager] copyItemAtPath:defaultPresetsPath toPath:presetsPath error:nil];
	}
	
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

#pragma mark Actions

- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApp delegate] presentError:error];
    }
}

#pragma Callbacks and Notifications

- (void) updateForSavedContext:(NSNotification *)notification
{
	[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
}

@end
