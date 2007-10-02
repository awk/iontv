//
//  RecSchedServer.h
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RecSchedProtocol.h"
#import "XMLParsingProgressDisplayProtocol.h"

@interface RecSchedServer : NSObject <RecSchedServerProto, XMLParsingProgressDisplay> {
    BOOL mExitServer;
}

- (bool) shouldExit;
- (void) updateSchedule;

@end
