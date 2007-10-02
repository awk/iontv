//
//  Preferences.m
//  recsched
//
//  Created by Andrew Kimpton on 1/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Preferences.h"

const float kDurationSliderMinValue = 1.0;
const float kDurationSliderMaxValue = 772.0;
const int k1HourTick = 0;   // Tick mark indices are zero based
const int k3HourTick = 2;
const int k12HoursTick = 5;
const int k24HoursTick   = 9;   // 1 day
const int k168HoursTick = 15;   // 1 week
const int k336HoursTick = 17;   // 2 weeks

struct discreteSliderMarks
{
  int tickMark;
  float timeValue;
};

const int kNumberDurationSliderTicks = 6;
struct discreteSliderMarks kDownloadDurationSliderMarks[] = { {0, 1.0}, {2, 3.0}, {5, 12.0}, {9, 24.0}, {15, 168.0}, {17, 336} };


@implementation Preferences

static Preferences *sSharedInstance = nil;

+ (Preferences *)sharedInstance {
    return sSharedInstance ? sSharedInstance : [[self alloc] init];
}

+ (void)setupDefaults
{
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    NSDictionary *initialValuesDict;
    NSArray *resettableUserDefaultsKeys;
    
    // load the default values for the user defaults
    userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefaults" 
                               ofType:@"plist"];
    userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    
    // if your application supports resetting a subset of the defaults to 
    // factory values, you should set those values 
    // in the shared user defaults controller
    resettableUserDefaultsKeys=[NSArray arrayWithObjects:kScheduleDownloadDurationPrefStr,nil];
    initialValuesDict=[userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller 
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

- (id)init
{
    if (sSharedInstance)
    {		// We just have one instance of the Preferences class, return that one instead
        [self release];
    }
    else if (self = [super init])
    {
        sSharedInstance = self;
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.scheduleDownloadDuration" options:NSKeyValueObservingOptionNew context:nil];
    }
    return sSharedInstance;
}

- (void)dealloc
{
    if (self != sSharedInstance)
      [super dealloc];	// Don't free the shared instance
}

- (void)showPanel:(id)sender
{
    if (!mPanel) {
        if (![NSBundle loadNibNamed:@"Preferences" owner:self]) 
        {
            NSLog(@"Failed to load Preferences.nib");
            NSBeep();
            return;
        }
	[mPanel setHidesOnDeactivate:NO];
	[mPanel setExcludedFromWindowsMenu:YES];
	[mPanel setMenu:nil];
        [self updateUI];
        [mPanel center];
    }
    [mPanel makeKeyAndOrderFront:nil];
}

- (void)updateUI
{
  [mDurationTextField setHidden:YES];
        
        // Now update the slider position for the default value
        float currDuration = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationPrefStr] floatValue];
        float newSliderValue = 0.0;
        int i=0;
        for (i=1; i < kNumberDurationSliderTicks; i++)
        {
          if (currDuration <= kDownloadDurationSliderMarks[i].timeValue)
          {
            newSliderValue = (currDuration - kDownloadDurationSliderMarks[i-1].timeValue)  / 
              ( kDownloadDurationSliderMarks[i].timeValue - kDownloadDurationSliderMarks[i-1].timeValue) 
              * ([mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark] - [mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark])
                + [mDurationSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark];
            break;
          }
        }
        if (newSliderValue >= 0.0)
          [mDurationSlider setDoubleValue:newSliderValue];
}

- (void) updateDurationLabel
{
  float newDuration = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:kScheduleDownloadDurationPrefStr] floatValue];
  if (newDuration < 24.0)
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%d Hours", (int)(newDuration + 0.5f)]];
  else if (newDuration < 169)
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%d Days", (int)((newDuration / 24.0f) + 0.5f)]];
  else
    [mDurationTextField setStringValue:[NSString stringWithFormat:@"%.1f Weeks", (newDuration / 168.0f)]];
}

- (IBAction) durationSliderChanged:(NSSlider *)inSlider
{
  float newSliderValue = [inSlider floatValue];
  float newDuration = 1.0f;
  int i=0;
  
  // Run through the list of tick marks and time values scale the duration between the nearest two tick marks.
  for (i=1; i < kNumberDurationSliderTicks; i++)
  {
    if (newSliderValue <= [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark])
    {
        newDuration = kDownloadDurationSliderMarks[i-1].timeValue + (newSliderValue - [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark]) / ([inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i].tickMark] - [inSlider tickMarkValueAtIndex:kDownloadDurationSliderMarks[i-1].tickMark]) * (kDownloadDurationSliderMarks[i].timeValue - kDownloadDurationSliderMarks[i-1].timeValue);
        break;
    }
  }
  
  NSUserDefaultsController *theController = [NSUserDefaultsController sharedUserDefaultsController];
  [[theController values] setValue:[NSNumber numberWithFloat:newDuration] forKey:kScheduleDownloadDurationPrefStr];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == [NSUserDefaultsController sharedUserDefaultsController]) && ([keyPath isEqual:@"values.scheduleDownloadDuration"]))
    {
      [self updateDurationLabel];
    }
}
@end
