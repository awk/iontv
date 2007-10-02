/*
 *  RecSchedProtocol.h
 *  recsched
 *
 *  Created by Andrew Kimpton on 3/6/07.
 *  Copyright 2007 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

extern NSString *kRecServerConnectionName;

@protocol RecSchedServerProto

- (BOOL) addRecordingOfProgram:(NSManagedObject*) aProgram
            withSchedule:(NSManagedObject*)aSchedule;

- (oneway void) quitServer:(id)sender;

- (oneway void) performDownload:(NSDictionary*)callData;
@end
