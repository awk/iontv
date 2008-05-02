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
#import "RecSchedProtocol.h"
#import "RSActivityViewController.h"
#import "RSMigrationSheetController.h"
#import "RSNotifications.h"

@interface RSMigrationSheetController(Private) <RSActivityDisplay>
@end

@implementation RSMigrationSheetController

- (id) initWithWindow:(NSWindow*)aWindow
{
  self = [super init];
  if (self != nil) {
    mParentWindow = [aWindow retain];
  }
  return self;
}

- (void) dealloc
{
  [mParentWindow release];
  [super dealloc];
}

- (void) showMigrationSheet
{
  mMigrationAlert = [[NSAlert alloc] init];
  
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(migrationCompleteNotification:) name:RSMigrationCompleteNotification object:RSBackgroundApplication];            
  [mMigrationAlert setMessageText:@"Database Upgrade Required"];
  [mMigrationAlert addButtonWithTitle:@"Cancel"];
  [mMigrationAlert setInformativeText:@"The iOnTV Database is being upgraded. Clicking Cancel will exit this application but the database upgrade will continue in the background."];
  [mMigrationAlert setAlertStyle:NSWarningAlertStyle];


  // Create the new Aggregate view controller
  mAggregateViewController = [[RSActivityAggregateViewController alloc] init];
  if (![NSBundle loadNibNamed:@"ActivityAggregateView" owner:mAggregateViewController])
  {
    NSLog(@"Error loading aggregate activity view NIB");
  }
  else
  {
    NSSize viewSize = [[mAggregateViewController aggregateView] frame].size;
    viewSize.width = 350;
    [[mAggregateViewController aggregateView] setFrameSize:viewSize];
    
    // Since we don't know anything about the current state of the migration (other than it's probably started)
    // we set the progress to indeterminate and the label to something useful until we get an update
    [self setActivity:(size_t)mAggregateViewController progressIndeterminate:YES];
    [self setActivity:(size_t)mAggregateViewController infoString:@"Currently Migrating Data"];
    [mMigrationAlert setAccessoryView:[mAggregateViewController aggregateView]];
  }
  
  [mMigrationAlert layout];

  // Specify ourselves as the activity view controller so that we can catch the migration activity updates
  [[[NSApp delegate] recServer] activityDisplayUnavailable];
  [[[NSApp delegate] activityWindowController].activityViewController.activityConnection setRootObject:self];
  [[[NSApp delegate] recServer] activityDisplayAvailable];
  
  [mMigrationAlert beginSheetModalForWindow:mParentWindow modalDelegate:self didEndSelector:@selector(migrationSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void) migrationCompleteNotification:(NSNotification*)aNotification
{
  [[[NSApp delegate] recServer] activityDisplayUnavailable];
  [[[NSApp delegate] activityWindowController].activityViewController.activityConnection setRootObject:[[NSApp delegate] activityWindowController].activityViewController];
  [[[NSApp delegate] recServer] activityDisplayAvailable];

  [NSApp endSheet:[mMigrationAlert window] returnCode:NSAlertSecondButtonReturn];
}

- (void)migrationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
  [[mMigrationAlert window] orderOut:self];
  if (returnCode == NSAlertFirstButtonReturn)
  {
    [NSApp terminate:self];
  }
}

@end

@implementation RSMigrationSheetController (Private)

- (size_t) createActivity
{
  return (size_t)mAggregateViewController;
}

- (void) endActivity:(size_t)activityToken
{
  [(RSActivityAggregateViewController*) activityToken release];
}

- (size_t) setActivity:(size_t)activityToken infoString:(NSString*)inInfoString
{
  [(RSActivityAggregateViewController*) activityToken setInfoString:inInfoString];
  return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressIndeterminate:(BOOL)isIndeterminate
{
  [(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:isIndeterminate];
  return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressMaxValue:(double)inTotal
{
  [(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:NO];
  [(RSActivityAggregateViewController*) activityToken setProgressMaxValue:inTotal];
  return activityToken;
}

- (size_t) setActivity:(size_t)activityToken progressDoubleValue:(double)inValue
{
  [(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:NO];
  [(RSActivityAggregateViewController*) activityToken setProgressDoubleValue:inValue];
  return activityToken;
}

- (size_t) setActivity:(size_t)activityToken incrementBy:(double)delta
{
  [(RSActivityAggregateViewController*) activityToken setProgressIndeterminate:NO];
  [(RSActivityAggregateViewController*) activityToken incrementProgressBy:delta];
  return activityToken;
}

- (size_t) shouldCancelActivity:(size_t)activityToken cancel:(BOOL*)cancel;
{
  if (cancel)
  {
    *cancel = NO;
  }
  return activityToken;
}

@end
