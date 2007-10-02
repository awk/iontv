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

- (void) addChannel:(HDHomeRunChannel*)aChannel
{
  NSMutableSet *channels = [self mutableSetValueForKey:@"channels"];
  [aChannel setTuner:self];
  [channels addObject:aChannel];
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

- (int) scanCallBackForType:(NSString *)type andData:(NSString *) data withMOC:(NSManagedObjectContext *)inMOC
{
  int continueScan = 1;
  
  NSLog(@"%@ %@", type, data);
  
  if (mCurrentProgressDisplay && [mCurrentProgressDisplay conformsToProtocol:@protocol(ChannelScanProgressDisplay)])
  {
      if ([type compare:@"SCANNING"] == NSOrderedSame)
      {
        [mCurrentProgressDisplay incrementChannelScanProgress];
        
        if (mCurrentHDHomeRunChannel)
        {
          // We have a current channel - does it have any stations ?
          if ([[mCurrentHDHomeRunChannel stations] count] == 0)
          {
            // No - so delete it
            [inMOC deleteObject:mCurrentHDHomeRunChannel];
          }
        }
        
        // Parse the channel type and number details from the data string
        NSString *channelTypeStr;
        NSNumber *channelNumber;
        
        // Channel scanning data has the form : 489000000 (us-cable:68, us-irc:68)  -OR- 485000000 (us-bcast:16)
        // We need to take the data after the opening bracket and use it to create the channel type and number
        NSRange openingBracket = [data rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"("]];
        NSString *typeNumberStr = [data substringFromIndex:openingBracket.location+1];
        NSRange colon = [typeNumberStr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        channelTypeStr = [typeNumberStr substringToIndex:colon.location];
        NSString *channelNumberStr = [typeNumberStr substringFromIndex:colon.location+1];
        NSRange endOfNumber = [channelNumberStr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@",)"]];
        channelNumber = [NSNumber numberWithInt:[[channelNumberStr substringToIndex:endOfNumber.location] intValue]];
        
        // Create a HDHomeRunChannel to match
        mCurrentHDHomeRunChannel = [HDHomeRunChannel createChannelWithType:channelTypeStr andNumber:channelNumber inManagedObjectContext:inMOC];
        
        // Set the 'current' scanning channel to the one we just created - if there's no lock or programs on this channel we'll delete
        // it later.
      }
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
        NSManagedObjectContext *theMOC = va_arg(ap, NSManagedObjectContext*);
        
        return [theTuner scanCallBackForType:[NSString stringWithCString:type] andData:[NSString stringWithCString:str] withMOC:theMOC];
}

// Typically called from a seperate thread to carry out the scanning
- (void) performScan
{
    NSPersistentStoreCoordinator *psc = [[[NSApplication sharedApplication] delegate] persistentStoreCoordinator];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: psc];

    mCurrentHDHomeRunChannel = nil;
    
    [psc lock];
    
  @synchronized(self)
  
  {
    NSLog(@"HDHomeRunTuner - scanAction for %@", [self longName]);

    channelscan_execute_all(mHDHomeRunDevice, HDHOMERUN_CHANNELSCAN_MODE_SCAN, cmd_scan_callback, self, managedObjectContext);
  }
  
  [mCurrentProgressDisplay scanCompleted];
  
  if (mCurrentHDHomeRunChannel && [[mCurrentHDHomeRunChannel stations] count] == 0)
  {
    // Destroy the current and channel and make sure it's not in the database
    [managedObjectContext deleteObject:mCurrentHDHomeRunChannel];
  }
  
  mCurrentHDHomeRunChannel = nil;
  
  [psc unlock];
  [managedObjectContext release];
  
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

@end

@implementation HDHomeRunChannel

+ createChannelWithType:(NSString*)inChannelType andNumber:(NSNumber*)inChannelNumber inManagedObjectContext:(NSManagedObjectContext*) inMOC
{
  HDHomeRunChannel *anHDHomeRunChannel = [NSEntityDescription insertNewObjectForEntityForName:@"HDHomeRunChannel" inManagedObjectContext:inMOC];
  [anHDHomeRunChannel setChannelType:inChannelType];
  [anHDHomeRunChannel setChannelNumber:inChannelNumber];
  return anHDHomeRunChannel;
}

- (NSString*) channelType
{
  COREDATA_ACCESSOR(NSString*, @"channelType")
}

- (void) setChannelType:(NSString*)value
{
  COREDATA_MUTATOR(NSString*, @"channelType");
}

- (NSNumber*) channelNumber
{
  COREDATA_ACCESSOR(NSNumber*, @"channelNumber")
}

- (void) setChannelNumber:(NSNumber*)value
{
  COREDATA_MUTATOR(NSNumber*, @"channelNumber");
}

- (NSString*) tuningType;
{
  COREDATA_ACCESSOR(NSString*, @"tuningType")
}

- (void) setTuningType:(NSString*)value
{
  COREDATA_MUTATOR(NSString*, @"tuningType");
}

- (HDHomeRunTuner*)tuner
{
  COREDATA_ACCESSOR(HDHomeRunTuner*, @"tuner")
}

- (void)setTuner:(HDHomeRunTuner*)value
{
  COREDATA_MUTATOR(HDHomeRunTuner*, @"tuner");
}


- (NSMutableSet *)stations;
{
  NSMutableSet *stations = [self mutableSetValueForKey:@"stations"];
  return stations;
}


@end
