//
//  HDHomeRunTuner.m
//  recsched
//
//  Created by Andrew Kimpton on 5/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HDHomeRunTuner.h"
#import "HDHomeRunMO.h"
#import "CoreData_Macros.h"
#import "hdhomerun_channelscan.h"
#import "ChannelScanProgressDisplayProtocol.h"

@interface HDHomeRunTunerChannelScanThread : NSObject

+ (void) performScan:(HDHomeRunTuner*)aTuner;

@end;

@implementation HDHomeRunTuner

- (NSNumber *) index;
{
COREDATA_ACCESSOR(NSNumber*, @"index")
}

- (void) setIndex:(NSNumber*)value;
{
COREDATA_MUTATOR(NSNumber*, @"index")
}

- (HDHomeRun*) device
{
COREDATA_ACCESSOR(HDHomeRun*, @"device")
}

- (void) setDevice:(HDHomeRun *)value
{
COREDATA_MUTATOR(HDHomeRun*, @"device")
}

- (Z2ITLineup*)lineup
{
COREDATA_ACCESSOR(Z2ITLineup*, @"lineup");
}

- (void) setLineup:(Z2ITLineup*)value
{
COREDATA_MUTATOR(Z2ITLineup*, @"lineup");
}

- (NSString*) longName
{
  NSString *name = [NSString stringWithFormat:@"%@ - %d - %@", [[self device] name], [[self index] intValue]+1, [[self lineup] name]];
  return name;
}

#pragma Actions

- (void) scanActionReportingProgressTo:(id)progressDisplay
{
  mCurrentProgressDisplay = [progressDisplay retain];
    [NSThread detachNewThreadSelector:@selector(performScan:) toTarget:[HDHomeRunTunerChannelScanThread class] withObject:self];
}

#pragma Thread Functions

- (int) scanCallBackForType:(NSString *)type andData:(NSString *) data
{
  int continueScan = 1;
  
  NSLog(@"%@ %@", type, data);
  
  if (mCurrentProgressDisplay && [mCurrentProgressDisplay conformsToProtocol:@protocol(ChannelScanProgressDisplay)])
  {
      if ([type compare:@"SCANNING"] == NSOrderedSame)
        [mCurrentProgressDisplay incrementChannelScanProgress];
      if ([mCurrentProgressDisplay abortChannelScan])
      {
        NSLog(@"Abort Channel Scan");
        continueScan = 0;
      }
  }
  return continueScan;
}

static int cmd_scan_callback(va_list ap, const char *type, const char *str)
{
	HDHomeRunTuner *theTuner = va_arg(ap, HDHomeRunTuner *);
        return [theTuner scanCallBackForType:[NSString stringWithCString:type] andData:[NSString stringWithCString:str]];
}

// Typically called from a seperate thread to carry out the scanning
- (void) performScan
{
  @synchronized(self)
  
  {
    NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);

    channelscan_execute_all(mHDHomeRunDevice, HDHOMERUN_CHANNELSCAN_MODE_SCAN, cmd_scan_callback, self);
  }
  
  [mCurrentProgressDisplay scanCompleted];
  
  [mCurrentProgressDisplay release];
  mCurrentProgressDisplay = nil;
}

#pragma Initialization

- (void) createHDHRDevice
{
  uint32_t deviceID = [[[self device] deviceID] intValue];
  if ((deviceID != 0) && (mHDHomeRunDevice == nil))
  {
    mHDHomeRunDevice = hdhomerun_device_create(deviceID, 0, [[self index] intValue]);
  }
}

- (void) awakeFromFetch
{
  [super awakeFromFetch];
  [self createHDHRDevice];
}

- (void) awakeFromInsert
{
  [super awakeFromInsert];
  [self createHDHRDevice];
  NSLog(@"HDHomeRunMO - awakeFromInsert");
}

#pragma Uninitialization

- (void) releaseHDHRDevice
{
  if (mHDHomeRunDevice)
    hdhomerun_device_destroy(mHDHomeRunDevice);
  mHDHomeRunDevice = nil;
}

- (void) didTurnIntoFault
{
  [self releaseHDHRDevice];
  
  [super didTurnIntoFault];
}


@end

@implementation HDHomeRunTunerChannelScanThread

+ (void) performScan:(HDHomeRunTuner*)aTuner
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [aTuner performScan];
  
  [pool release];
}

@end;

