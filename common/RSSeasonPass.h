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

#import <Cocoa/Cocoa.h>

@class Z2ITStation;
@class RSSeasonPassOptions;
@class Z2ITProgram;
@class RSRecording;

@interface RSSeasonPass : NSManagedObject {

}

@property (retain) NSString * series;
@property (retain) RSSeasonPassOptions * options;
@property (retain) Z2ITStation * station;
@property (retain) NSString * title;
@property (retain) NSSet* recordings;

+ (RSSeasonPass*) insertSeasonPassForProgram:(Z2ITProgram*)aProgram onStation:(Z2ITStation*)aStation;

- (NSArray *)fetchFutureSchedules;

@end

// coalesce these into one @interface RSSeasonPass (CoreDataGeneratedAccessors) section
@interface RSSeasonPass (CoreDataGeneratedAccessors)
- (void)addRecordingsObject:(RSRecording *)value;
- (void)removeRecordingsObject:(RSRecording *)value;
- (void)addRecordings:(NSSet *)value;
- (void)removeRecordings:(NSSet *)value;

@end
