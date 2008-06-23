// libRecSchedCommon - Common code shared between UI application and background server
// Copyright (C) 2007 Andrew Kimpton
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "RSError.h"

// Sender for notifications from the Background Server App
NSString *RSErrorDomain = @"com.iontv-app.error";
NSString *kRSErrorConflictingSchedules = @"conflictingSchedules";
NSString *kRSErrorScheduleToBeRecorded = @"scheduleToBeRecorded";

@implementation RSNoConnectionErrorRecovery

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
  if (recoveryOptionIndex == 1)
  {
    NSLog(@"IMPLEMENT - Need to restart the app.");
  }
  return YES;
}

@end
