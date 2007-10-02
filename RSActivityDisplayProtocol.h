//
//  RSActivityDisplayProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

extern NSString *kRecUIActivityConnectionName;

@protocol RSActivityDisplay
- (void) beginActivity;
- (void) endActivity;

- (void) setActivityInfoString:(NSString*)inInfoString;
- (void) setActivityProgressIndeterminate:(BOOL)isIndeterminate;
- (void) setActivityProgressMaxValue:(double)inTotal;
- (void) setActivityProgressDoubleValue:(double)inValue;
@end

