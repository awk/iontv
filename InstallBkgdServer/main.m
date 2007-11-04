//
//  main.m
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Security/Security.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AuthorizationRef adminAuthRef;
	OSStatus status = noErr;
	status = AuthorizationCopyPrivilegedReference(&adminAuthRef, kAuthorizationFlagDefaults);
	if (status != noErr)
	{
		NSLog(@"InstallBkgdServer not launched with admin privileges, status = %d - exiting", status);
		[pool release];
		return -1;
	}
	
	// Find the path to the /Library/LaunchDaemons folder
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

	if (!basePath)
	{
		NSLog(@"InstallBkgdServer could not fine Library path");
		[pool release];
		return -1;
	}
	
	NSString *launchDaemonPath = [basePath stringByAppendingPathComponent:@"LaunchDaemons/com.iontv-app.recsched-bkgd.plist"];
	
	// We need to build a dictionary that looks like this :
//	<dict>
//	<key>Label</key>
//	<string>com.iontv-app.recsched-bkgd</string>
//	<key>ProgramArguments</key>
//	<array>
//		<string><<Path to background server inside bundle>></string>
//	</array>
//	<key>RunAtLoad</key>
//	<true/>
//	</dict>
	NSString *installAppPath = [NSString stringWithCString:argv[0]];
	NSMutableString *recschedBkgdRelativePath = [[NSMutableString alloc] initWithString:installAppPath];
	[recschedBkgdRelativePath appendString:@"/../../Support/recsched_bkgd.app/Contents/MacOS/recsched_bkgd"];
	NSURL *recschedBkgdURL = [[NSURL alloc] initFileURLWithPath:recschedBkgdRelativePath];
	[recschedBkgdRelativePath release];
	NSString *recschedBkgdPath = [[recschedBkgdURL standardizedURL] path];
	NSArray *arguments = [NSArray arrayWithObject:recschedBkgdPath];
	NSDictionary *plist = [NSDictionary dictionaryWithObjectsAndKeys:@"com.iontv-app.recsched-bkgd", @"Label", arguments, @"ProgramArguments", [NSNumber numberWithBool:YES], @"RunAtLoad", nil];
	BOOL writeOK = [plist writeToFile:launchDaemonPath atomically:YES];

	if (!writeOK)
	{
		NSLog(@"InstallBkgdServer could not write launchd plist to %@", launchDaemonPath);
		[pool release];
		return -1;
	}
	
	// Now we build an NSTask to install the launch item
	NSTask *launchCtlTask = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:[NSArray arrayWithObjects:@"load", launchDaemonPath, nil]];
	[launchCtlTask waitUntilExit];
	int launchCtlStatus = [launchCtlTask terminationStatus];
	
	NSLog(@"Application - launchCtlStatus = %d", launchCtlStatus);
	[pool release];
	return launchCtlStatus;
}
