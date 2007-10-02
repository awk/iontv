//
//  recsched_bkgd_AppDelegate.h
//  recsched
//
//  Created by Andrew Kimpton on 6/18/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "RSCommonAppDelegate.h"

@class RecSchedServer;

@interface recsched_bkgd_AppDelegate : RSCommonAppDelegate
{
	RecSchedServer *mRecSchedServer;
}

- (NSURL *)urlForPersistentStore;

#if USE_SYNCSERVICES
- (ISyncClient *)syncClient;
- (void)syncAction:(id)sender;
#endif // USE_SYNCSERVICES
- (IBAction) saveAction:(id)sender;

@end
