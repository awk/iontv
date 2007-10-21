//
//  RecSchedServer.h
//  recsched
//
//  Created by Andrew Kimpton on 3/5/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RecSchedProtocol.h"
#import "RSActivityDisplayProtocol.h"
#import "RSStoreUpdateProtocol.h"

extern NSString *RSNotificationUIActivityAvailable;

@interface RecSchedServer : NSObject <RecSchedServerProto, RSActivityDisplay, RSStoreUpdate> {
    BOOL mExitServer;
	
	id mUIActivity;
	id mStoreUpdate;
}

- (bool) shouldExit;
- (void) updateSchedule;
- (id) uiActivity;
- (id) storeUpdate;
@property BOOL mExitServer;
@property (retain,getter=storeUpdate) id mStoreUpdate;
@property (retain,getter=uiActivity) id mUIActivity;
@end
