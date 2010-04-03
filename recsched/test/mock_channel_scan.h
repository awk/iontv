/*
 *  mock_channel_scan.h
 *  recsched
 *
 *  Created by Andrew Kimpton on 3/31/10.
 *  Copyright 2010 Fellsware. All rights reserved.
 *
 */

#include "hdhomerun.h"

int mock_channelscan_execute_all(struct hdhomerun_device_t *hd, uint32_t channel_map, channelscan_callback_t callback, ...);
