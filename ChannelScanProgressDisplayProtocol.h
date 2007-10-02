//
//  ChannelScanProgressDisplayProtocol.h
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

@class HDHomeRunTuner;

@protocol ChannelScanProgressDisplay
- (void) incrementChannelScanProgress;
- (BOOL) abortChannelScan;
- (void) scanCompletedOnTuner:(HDHomeRunTuner*)inTuner;
@end

