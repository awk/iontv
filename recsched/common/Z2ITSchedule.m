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

#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"

#import <AppKit/NSImage.h>

@implementation Z2ITSchedule

+ (void)clearAllSchedulesInManagedObjectContext:(NSManagedObjectContext *)inMOC {
  NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [fetchRequest setEntity:
    [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:inMOC]];

  // Execute the fetch
  NSError *error;
  NSArray *allSchedules = [inMOC executeFetchRequest:fetchRequest error:&error];
  Z2ITSchedule *aSchedule;
  for (aSchedule in allSchedules) {
    [inMOC deleteObject:aSchedule];
  }
}

+ (Z2ITSchedule *)fetchScheduleWithLatestStartDateInMOC:(NSManagedObjectContext *)inMOC {
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:inMOC];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
  [request setFetchLimit:1];

  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:NO];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
  [request setFetchLimit:1];    // Only need the single last item

  NSError *error = nil;
  NSArray *array = [inMOC executeFetchRequest:request error:&error];
  if (array == nil) {
    NSLog(@"Error executing fetch request to find schedule with latest start date");
    return nil;
  }
  if ([array count] == 0) {
    return nil;
  } else {
    return [array objectAtIndex:0];
  }
}

- (BOOL)overlapsWith:(Z2ITSchedule *)anotherSchedule {
  // This schedule ends before anotherSchedule starts or this schedule ends exactly as the other schedule starts - no overlap
  if (([[self endTime] compare:anotherSchedule.time] == NSOrderedAscending) || ([[self endTime] compare:anotherSchedule.time] == NSOrderedSame)) {
    return NO;
  } else if ([[self time] compare:anotherSchedule.endTime] == NSOrderedDescending) {
    // This schedule starts after anotherSchedule ends - no overlap
    return NO;
  } else {
    // If none of the above are true - there's some amount of overlap
    return YES;
  }
}

- (void)setDurationHours:(int)inHours minutes:(int)inMinutes {
  NSDate *startDate = [self time];
  if (startDate == nil) {
    NSLog(@"setDuration - no valid start time for program %@", [[self program] title]);
  }
  NSDate *endDate = [self endTime];
  if (endDate != nil) {
    NSLog(@"setDuration - program %@ already has an end time", [[self program] title]);
  }

  endDate = [startDate dateByAddingTimeInterval:(inHours * 60 * 60) + (inMinutes * 60)];
  [self setEndTime:endDate];
}

- (NSString *)partNumberString {
  if (([self partNumber] == nil) || ([self totalNumberParts] == nil)) {
    return nil;
  }
  if (([[self partNumber] intValue] == 0) || ([[self totalNumberParts] intValue] == 0)) {
    return nil;
  }

  return [NSString stringWithFormat:@"Part %@ of %@", [self partNumber], [self totalNumberParts]];
}

- (NSString *)programDetailsStr {
  NSString *aString = nil;
  if ([[self program] descriptionStr] != nil) {
    NSMutableString *detailsString = [[NSMutableString alloc] initWithString:[[self program] descriptionStr]];
    NSNumber *isNewProgram = [[self newProgram] autorelease];
    if (![isNewProgram boolValue]) {
      [detailsString appendString:@" Repeat."];
    }
    if ([self dolby] != nil) {
      [detailsString appendFormat:@" %@.", [self dolby]];
    }
    if ([self subtitled]) {
      [detailsString appendFormat:@" Subtitled."];
    }
    aString = [NSString stringWithString:detailsString];
    [detailsString release];
  }
  return aString;
}

- (NSNumber *) newProgram {
  [self willAccessValueForKey:@"new"];
  NSNumber *newProg = [self primitiveValueForKey:@"new"];
  [self didAccessValueForKey:@"new"];
  return [newProg retain];
}

- (void) setNewProgram:(NSNumber *) newProg {
  [self willChangeValueForKey:@"new"];
  [self setPrimitiveValue:newProg forKey:@"new"];
  [self didChangeValueForKey:@"new"];
}

@dynamic closeCaptioned;
@dynamic dolby;
@dynamic endTime;
@dynamic hdtv;
@dynamic partNumber;
@dynamic recordedMediaPath;
@dynamic recordingStatus;
@dynamic stereo;
@dynamic subtitled;
@dynamic time;
@dynamic totalNumberParts;
@dynamic tvRating;
@dynamic program;
@dynamic station;
@dynamic recording;
@dynamic transcoding;

- (NSString *)tvRatingImageName {
  if ([self tvRating] == nil) {
    return nil;
  } else {
    return [NSString stringWithFormat:@"%@.png", [self tvRating]];
  }
}

- (NSString *)tvRatingImagePath {
  if ([self tvRatingImageName] == nil) {
    return nil;
  }
  NSString *imagePath = [[NSBundle mainBundle] pathForImageResource:[self tvRatingImageName]];
  return imagePath;
}

@end
