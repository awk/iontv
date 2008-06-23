//
//  RSScheduleConflictController.h
//  recsched
//
//  Created by Andrew Kimpton on 6/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITSchedule;

@interface RSScheduleConflictController : NSWindowController {

  IBOutlet NSArrayController *mConflictsArrayController;
  IBOutlet NSMatrix *mResolutionRadioMatrix;
  IBOutlet NSTextField *mConflictMessageField;
  
  Z2ITSchedule *mScheduleToBeRecorded;
}

- (IBAction) okAction:(id)sender;
- (IBAction) cancelAction:(id)sender;
- (void) setScheduleToBeRecordedObjectID:(NSManagedObjectID*)aScheduleID;
- (void) setConflictingSchedulesObjectIDs:(NSArray*)conflicts;

@end
