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

- (ISyncClient *)syncClient;
- (void)syncAction:(id)sender;
- (IBAction) saveAction:(id)sender;

@end
