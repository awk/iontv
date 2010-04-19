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

#import <Cocoa/Cocoa.h>
#import "recsched_bkgd_AppDelegate.h"

int main(int argc, char *argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  [NSApplication sharedApplication];
//  [NSBundle loadNibNamed:@"myMain" owner:NSApp];

  recsched_bkgd_AppDelegate *appDelegate = [[recsched_bkgd_AppDelegate alloc] init];
  [NSApp setDelegate:appDelegate];

  [NSApp run];
//   return NSApplicationMain(argc,  (const char **) argv);

  [appDelegate release];
  [pool release];
  return 0;
}
