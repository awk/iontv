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

#import "RSSeasonPass.h"
#import "RSRecordingOptions.h"
#import "Z2ITProgram.h"
#import "Z2ITStation.h"

@implementation RSSeasonPass

@dynamic series;
@dynamic options;
@dynamic station;

+ (RSSeasonPass*) insertSeasonPassForProgram:(Z2ITProgram*)aProgram onStation:(Z2ITStation*)aStation
{
	RSSeasonPass *aSeasonPass = [NSEntityDescription insertNewObjectForEntityForName:@"SeasonPass" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	[aSeasonPass setStation:aStation];
	[aSeasonPass setSeries:aProgram.series];
	
	RSSeasonPassOptions *options = [NSEntityDescription insertNewObjectForEntityForName:@"SeasonPassOptions" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
	options.keepUntil = kRSRecordingOptionsKeepUntilSpaceNeeded;
	options.showType = kRSSeasonPassOptionsShowTypeRepeatsAndFirstRuns;
	[aSeasonPass setOptions:options];
	
	return aSeasonPass;
}

- (NSArray *)fetchFutureSchedules
{
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:[self managedObjectContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
	
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(program.series == %@) AND (station == %@)", self.series, self.station];
  [request setPredicate:predicate];
	
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
  [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  [sortDescriptor release];
	
  NSError *error = nil;
  NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
  if (array == nil)
  {
		NSLog(@"Error executing fetch request to find schedules for series ID %@", self.series);
		return nil;
  }
  else
  {
		return array;
  }
}

@end
