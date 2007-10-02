//
//  recsched_bkgd_main.m
//  recsched
//
//  Created by Andrew Kimpton on 1/12/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "recsched_bkgd_AppDelegate.h"

int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    [NSApplication sharedApplication];
//    [NSBundle loadNibNamed:@"myMain" owner:NSApp];

	recsched_bkgd_AppDelegate *appDelegate = [[recsched_bkgd_AppDelegate alloc] init];
	[NSApp setDelegate:appDelegate];
	
    [NSApp run];
//	    return NSApplicationMain(argc,  (const char **) argv);

    [pool release];
	return 0;
}
