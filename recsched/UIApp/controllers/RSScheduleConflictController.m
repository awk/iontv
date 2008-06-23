//
//  RSScheduleConflictController.m
//  recsched
//
//  Created by Andrew Kimpton on 6/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSScheduleConflictController.h"
#import "recsched_AppDelegate.h"
#import "RecSchedProtocol.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"

@implementation RSScheduleConflictController

- (void) dealloc
{
  [mConflictsArrayController removeObserver:self forKeyPath:@"selectedObjects"];
  [mScheduleToBeRecorded release];
  [super dealloc];
}

- (IBAction) okAction:(id)sender
{
  [[self window] orderOut:sender];
  [[NSApplication sharedApplication] stopModalWithCode:NSOKButton];
  if ([mResolutionRadioMatrix selectedRow] == 0)
  {
    // Cancel the selected recording and reschedule the new one
    NSError *error = nil;
    Z2ITSchedule *aSchedule = [[mConflictsArrayController selectedObjects] objectAtIndex:0];
    [[[NSApp delegate] recServer] cancelRecordingWithObjectID:[aSchedule.recording objectID] error:&error];
    
    [[[NSApp delegate] recServer] addRecordingOfScheduleWithObjectID:[mScheduleToBeRecorded objectID] error:&error];
  }
}

- (IBAction) cancelAction:(id)sender
{
  [[self window] orderOut:sender];
  [[NSApplication sharedApplication] stopModalWithCode:NSCancelButton];
}

- (void) awakeFromNib
{
  [mConflictsArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
}

- (void) setScheduleToBeRecordedObjectID:(NSManagedObjectID*)aScheduleID
{
  NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
  [mScheduleToBeRecorded autorelease];
  Z2ITSchedule *aSchedule = (Z2ITSchedule *) [moc objectWithID:aScheduleID];
  mScheduleToBeRecorded = [aSchedule retain];
  
  // Update the message text for this schedule
  NSString *message = [NSString localizedStringWithFormat:@"The program %@ at %@ on %@ cannot be recorded because it conflicts with the following programs which are to be recorded at the same time.",
                        mScheduleToBeRecorded.program.title,
                        [mScheduleToBeRecorded.time descriptionWithCalendarFormat:@"%H:%M" timeZone:nil locale:nil], 
                        [mScheduleToBeRecorded.time descriptionWithCalendarFormat:@"%x" timeZone:nil locale:nil]];
  [mConflictMessageField setStringValue:message];
}

- (void) setConflictingSchedulesObjectIDs:(NSArray*)conflicts
{
  NSMutableArray *localConflicts = [NSMutableArray arrayWithCapacity:[conflicts count]];
  NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
  for (NSManagedObjectID *objectId in conflicts)
  {
    [localConflicts addObject:[moc objectWithID:objectId]];
  }
  
  [mConflictsArrayController setContent:localConflicts];
  [mConflictsArrayController setSelectedObjects:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ((object == mConflictsArrayController) && ([keyPath compare:@"selectedObjects"] == NSOrderedSame))
  {
    // if empty selection disable and select 'do not record'
    if ([mConflictsArrayController.selectedObjects count] > 0)
    {
      [mResolutionRadioMatrix setEnabled:YES];
    }
    else
    {
      [mResolutionRadioMatrix setEnabled:NO];
      [mResolutionRadioMatrix setState:1 atRow:1 column:0];
    }
  }
}

@end
