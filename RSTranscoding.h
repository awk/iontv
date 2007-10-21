//
//  RSTranscoding.h
//  recsched
//
//  Created by Andrew Kimpton on 10/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Z2ITSchedule;
@class RSTranscodingImp;

@interface RSTranscoding : NSManagedObject {
	RSTranscodingImp *transcodingImp;
}

@property (retain) NSString * mediaFile;
@property (retain) NSNumber * status;
@property (retain) Z2ITSchedule * schedule;
@property (retain) RSTranscodingImp * transcodingImp;

- (void) finishedTranscode;

@end

// coalesce these into one @interface RSTranscoding (CoreDataGeneratedAccessors) section
@interface RSTranscoding (CoreDataGeneratedAccessors)
@end
