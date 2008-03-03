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

#import "recsched_AppDelegate.h"
#import "Preferences.h"
#import "HDHomeRunMO.h"
#import "HDHomeRunTuner.h"
#import "RecSchedProtocol.h"
#import "MainWindowController.h"
#import "RSActivityViewController.h"
#import "RSFirstRunWindowController.h"
#import "Sparkle/Sparkle.h"

NSString *RSDownloadErrorNotification = @"RSDownloadErrorNotification";
NSString *RSChannelScanCompleteNotification = @"RSChannelScanCompleteNotification";
NSString *RSLineupRetrievalCompleteNotification = @"RSLineupRetrievalCompleteNotification";
NSString *RSScheduleUpdateCompleteNotification = @"RSScheduleUpdateCompleteNotification";

@interface recsched_AppDelegate(private)

- (void) installBackgroundServer;

@end

@interface RSIsOneOrLessNumberValueTransformer : NSValueTransformer
{

}

@end

@implementation RSIsOneOrLessNumberValueTransformer

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

- (id)transformedValue:(id)value {

	if ([value count] <= 1) {
		return [NSNumber numberWithBool:YES];
	} 
	
	return[NSNumber numberWithBool:NO];

}

@end

@implementation recsched_AppDelegate

#pragma mark - Server Communication

- (void) installBackgroundServer
{
#if 0
	OSStatus status;
	AuthorizationRef adminAuthRef;
	
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &adminAuthRef);
	if (status != noErr)
		return;
		
	AuthorizationItem adminAuthRightItem = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights adminRights = {1, &adminAuthRightItem};

	const char *utf8String = [[NSString stringWithString:@"iOnTV needs administrator privileges to install the background recording server. "] UTF8String];
	AuthorizationItem adminAuthEnvItem = {kAuthorizationEnvironmentPrompt, strlen(utf8String), (void*) utf8String, 0};
	AuthorizationEnvironment authEnvironment = {1, &adminAuthEnvItem};
	AuthorizationFlags authFlags = kAuthorizationFlagDefaults |
			kAuthorizationFlagInteractionAllowed |
			kAuthorizationFlagPreAuthorize |
			kAuthorizationFlagExtendRights;
			
	status = AuthorizationCopyRights (adminAuthRef, &adminRights, &authEnvironment, authFlags, NULL );
	if (status != noErr)
		return;
		
	NSString *installBkgdServerAppPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"InstallBkgdServer"];
	
	// Launch the installation tool with the appropriate privileges
	status = AuthorizationExecuteWithPrivileges(adminAuthRef, [installBkgdServerAppPath cStringUsingEncoding:NSASCIIStringEncoding], kAuthorizationFlagDefaults, NULL /*args*/, NULL);
	
	// Free the authorization reference
	//AuthorizationFree(adminAuthRef, kAuthorizationFlagDefaults);
#endif

	// LaunchAgents seem unreliable - if we need a connection to the User Interface then we probably need to create login item, for now we'll just start it manually here using
	// NSTask
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *backgroundServerPath = [bundlePath stringByAppendingPathComponent:@"Contents/Support/recsched_bkgd.app/Contents/MacOS/recsched_bkgd"];
        BOOL launchedBackgroundServer = NO;
//        launchedBackgroundServer = [[NSWorkspace sharedWorkspace] launchApplication:backgroundServerPath];
	if (launchedBackgroundServer == NO)
        {
          NSLog(@"installBackgroundServer - failed to launch background server :%@", backgroundServerPath);
        }
}

- (void) initializeServerConnection
{
  // Connect to server
  mRecServer = [[NSConnection rootProxyForConnectionWithRegisteredName:kRecServerConnectionName  host:nil] retain];
   
  // check if connection worked.
  if (mRecServer == nil) 
  {
    NSLog(@"couldn't connect with server\n");
    [mServerMenuItem setTitle:@"Connect to Server"];
	
	// Attempt to install the background server as a launch agent
	[self installBackgroundServer];
	
	// And try again with the connection - up to 5 times
	int i=0;
	for (i=0; (i < 5) && (mRecServer == nil); i++)
	{
		mRecServer = [[NSConnection rootProxyForConnectionWithRegisteredName:kRecServerConnectionName  host:nil] retain];
		usleep(100000);	// Sleep for one tenth of a second.
	}
  }
  
  if (mRecServer != nil)
  {
    //
    // set protocol for the remote object & then register ourselves with the 
    // messaging server.
    [mRecServer setProtocolForProxy:@protocol(RecSchedServerProto)];
    [mServerMenuItem setTitle:@"Exit Server"];
  }
}

- (id) recServer
{
	return mRecServer;
}

#pragma mark - Initialization

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
  
  // Setup the activity window controller now - this let's it register with the background server and
  // to show info even if it's not visible
  mActivityWindowController = [[RSActivityWindowController alloc] initWithWindowNibName:@"Activity"];
  [mActivityWindowController window];   // This will trigger the Nib to load
}

+ (void) initialize
{
	// Register our positive number to bool transformer
	RSIsOneOrLessNumberValueTransformer *numberTransformer = [[[RSIsOneOrLessNumberValueTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:numberTransformer forName:@"RSIsOneOrLessNumberValueTransformer"];
}

- (id) init {
  self = [super init];
  if (self != nil) {
    [Preferences setupDefaults];

    [self initializeServerConnection];

	// Register ourselves for the display/feedback methods called by the server
    NSConnection *theConnection;

    theConnection = [[NSConnection alloc] init];
    [theConnection setRootObject:self];
    if ([theConnection registerName:kRSStoreUpdateConnectionName] == NO) 
    {
            /* Handle error. */
            NSLog(@"Error registering connection");
    }
	else
	{
		[[self recServer] storeUpdateAvailable];
	}
  }
  return self;
}

- (void) dealloc
{
  [mFirstRunWindowController release];
  [mActivityWindowController release];
  [super dealloc];
}

- (NSURL *)urlForPersistentStore {
	return [NSURL fileURLWithPath: [[self applicationSupportFolder] stringByAppendingPathComponent: @"recsched_bkgd.dat"]];
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
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
	// Open the store read only
	NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSReadOnlyPersistentStoreOption];

	persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:optionsDictionary error:&error];

    return persistentStoreCoordinator;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
	// Register to be notified when an update through sparkle completes - we use this to restart the background
	// server which may also have just been updated.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sparkleWillRestart:) name:SUUpdaterWillRestartNotification object:nil];
        
        // Launch the first run assistant if the key is not present in the prefs file
        BOOL firstRunAlreadyCompleted = [[NSUserDefaults standardUserDefaults] boolForKey:kFirstRunAssistantCompletedKey];
        if (firstRunAlreadyCompleted == NO)
        {
          [self performSelector:@selector(launchFirstRunWizard:) withObject:nil afterDelay:0];
        }
}

#pragma mark - Actions

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
    [inStation startStreamingToPort:1234];		// VLC Listens on Port 1234 by default
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

- (IBAction)showActivityWindow:(id)sender
{
	if (!mActivityWindowController)
	{
		mActivityWindowController = [[RSActivityWindowController alloc] initWithWindowNibName:@"Activity"];
	}
	[mActivityWindowController showWindow:self];
}

- (IBAction) launchFirstRunWizard:(id)sender
{
  if (mFirstRunWindowController == nil)
  {
    mFirstRunWindowController = [[RSFirstRunWindowController alloc] initWithWindowNibName:@"FirstRun"];
  }
  if (mFirstRunWindowController)
  {
    [mFirstRunWindowController showWindow:sender];
  }
}

#pragma mark - Delegate Messages

/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    int reply = NSTerminateNow;

    [[self recServer] storeUpdateUnavailable];
    return reply;
}

#pragma mark - Notifications

- (void)vlcTerminationTimer:(NSTimer*)theTimer
{
  HDHomeRunStation *theStation = [theTimer userInfo];
  
  if (mVLCTask == nil)
  {
    [self launchVLCAction:self withParentWindow:nil];
    [theStation startStreamingToPort:1234];
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

- (void) sparkleWillRestart:(NSNotification*)notification
{
	// Sparkle is restarting us after an update - if we have a connection to the server we should restart
	// it too.
	if (mRecServer != nil)
	{
		[mRecServer quitServer:self];
	}
}

#pragma mark - Store Update Protocol

- (void) parsingComplete:(id)info
{
	NSDictionary *infoDict = nil;
	if (info)
		infoDict = [NSDictionary dictionaryWithObject:info forKey:@"parsingCompleteInfo"];

        if ([info valueForKey:@"lineupsOnly"] && [[info valueForKey:@"lineupsOnly"] boolValue] == YES)
        {
          [[NSNotificationCenter defaultCenter] postNotificationName:RSLineupRetrievalCompleteNotification object:self userInfo:infoDict];
        }
        else
        {
          [[NSNotificationCenter defaultCenter] postNotificationName:RSScheduleUpdateCompleteNotification object:self userInfo:infoDict];
          [[window delegate] setGetScheduleButtonEnabled:YES];
        }
        
	NSLog(@"Parsing Complete");
}

- (void) cleanupComplete:(id)info
{
	NSLog(@"Cleanup Complete");
}

- (void) downloadError:(id)info
{
	NSDictionary *infoDict = nil;
	if (info)
		infoDict = [NSDictionary dictionaryWithObject:info forKey:@"downloadErrorInfo"];

	[[NSNotificationCenter defaultCenter] postNotificationName:RSDownloadErrorNotification object:self userInfo:infoDict];
}

- (void) channelScanComplete:(id)info
{
	NSDictionary *infoDict = nil;
	if (info)
		infoDict = [NSDictionary dictionaryWithObject:info forKey:@"channelScanCompleteInfo"];

	[[NSNotificationCenter defaultCenter] postNotificationName:RSChannelScanCompleteNotification object:self userInfo:infoDict];

	NSLog(@"Channel Scan Complete");
}

#pragma mark Properties

- (RSActivityWindowController*) activityWindowController
{
  return mActivityWindowController;
}

@synthesize mRecServer;
@end
