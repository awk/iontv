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

@class Z2ITSchedule;
@class RecordingThreadController;
@class HDHomeRunTuner;
@class RSRecordingQueue;
@class RSRecordingOptions;

enum {
	RSRecordingNotYetStartedStatus = 0,
	RSRecordingInProgressStatus = 1,
	RSRecordingFinishedStatus = 2,
	RSRecordingErrorStatus = 3,
};

@interface RSRecording : NSManagedObject {
  RecordingThreadController *recordingThreadController;
  RSRecordingQueue *recordingQueue;
}

@property (retain) NSString * mediaFile;
@property (retain) NSNumber * status;
@property (retain) Z2ITSchedule * schedule;
@property (retain) HDHomeRunTuner * tuner;
@property (retain) RecordingThreadController * recordingThreadController;
@property (retain) RSRecordingQueue *recordingQueue;
@property (retain) RSRecordingOptions *recordingOptions;

+ (RSRecording*) insertRecordingOfSchedule:(Z2ITSchedule*)aSchedule;
+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC afterDate:(NSDate*)date withStatus:(int)status; 
+ (NSArray*) fetchRecordingsInManagedObjectContext:(NSManagedObjectContext*)inMOC beforeDate:(NSDate*)date; 

@end

// coalesce these into one @interface RSRecording (CoreDataGeneratedAccessors) section
@interface RSRecording (CoreDataGeneratedAccessors)
@end
