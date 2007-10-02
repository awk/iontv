//
//  RSStoreUpdateProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

extern NSString *kRSStoreUpdateConnectionName;

@protocol RSStoreUpdate

- (void) parsingComplete:(id)info;
- (void) cleanupComplete:(id)info;

@end

