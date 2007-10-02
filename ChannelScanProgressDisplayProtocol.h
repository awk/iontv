//
//  ChannelScanProgressDisplayProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//


@protocol ChannelScanProgressDisplay
- (void) incrementChannelScanProgress;
- (BOOL) abortChannelScan;
- (void) scanCompleted;
@end

