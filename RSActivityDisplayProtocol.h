//
//  RSActivityDisplayProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

extern NSString *kRecUIActivityConnectionName;

@protocol RSActivityDisplay
- (size_t) createActivity;
- (void) endActivity:(size_t)activityToken;

- (void) setActivity:(size_t)activityToken infoString:(NSString*)inInfoString;
- (void) setActivity:(size_t)activityToken progressIndeterminate:(BOOL)isIndeterminate;
- (void) setActivity:(size_t)activityToken progressMaxValue:(double)inTotal;
- (void) setActivity:(size_t)activityToken incrementBy:(double)delta;
- (BOOL) shouldCancelActivity:(size_t)activityToken;
@end

