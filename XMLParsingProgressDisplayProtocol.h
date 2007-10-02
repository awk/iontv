//
//  XMLParsingProgressDisplayProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

extern NSString *kRecUserInterfaceConnectionName;

@protocol XMLParsingProgressDisplay
- (void) setParsingInfoString:(NSString*)inInfoString;
- (void) setParsingProgressMaxValue:(double)inTotal;
- (void) setParsingProgressDoubleValue:(double)inValue;

- (void) parsingComplete:(id)info;
- (void) cleanupComplete:(id)info;
@end

