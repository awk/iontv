//
//  ScheduleViewController.m
//  recsched
//
//  Created by Andrew Kimpton on 2/2/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ScheduleViewController.h"
#import "ScheduleView.h"
#import "Z2ITSchedule.h"
#import "Z2ITStation.h"
#import "Z2ITLineup.h"
#import "Z2ITLineupMap.h"

@class Z2ITSchedule;

enum { kPreviousTimeSegment = 0, kDaySegment, kHourSegment, kNextTimeSegment };

@implementation ScheduleViewController

- (id) init {
  self = [super init];
  if (self != nil) {
    [self addObserver:self forKeyPath:@"startTime" options:0x0 context:nil];
    CFGregorianDate previousHour = CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),CFTimeZoneCopyDefault());
    if (previousHour.minute > 30)
      previousHour.minute = 30;
    else
      previousHour.minute = 0;
    previousHour.second = 0;
    [self setStartTime:CFGregorianDateGetAbsoluteTime(previousHour,CFTimeZoneCopyDefault())];
  }
  return self;
}

- (void) awakeFromNib
{
  [self updateSegmentDisplay];
  [self updateSegmentMenus];
  [mCurrentSchedule addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) goBackwards
{
  CFGregorianUnits increment;
  memset(&increment, 0, sizeof(increment));
  increment.minutes = -30;
  CFAbsoluteTime aStartTime = CFAbsoluteTimeAddGregorianUnits([self startTime],CFTimeZoneCopyDefault(),increment);
  [self setStartTime:aStartTime];
}

- (void) goForwards
{
  CFGregorianUnits increment;
  memset(&increment, 0, sizeof(increment));
  increment.minutes = 30;
  CFAbsoluteTime aStartTime = CFAbsoluteTimeAddGregorianUnits([self startTime],CFTimeZoneCopyDefault(),increment);
  [self setStartTime:aStartTime];
}

- (CFAbsoluteTime) startTime
{
  return mStartTime;
}

- (void) setStartTime:(CFAbsoluteTime)inStartTime
{
  mStartTime = inStartTime;
  [mScheduleView setStartTime:mStartTime];
}

- (void) setCurrentSchedule:(Z2ITSchedule*)inSchedule
{
  [mCurrentSchedule setContent:inSchedule];
}

- (void) setCurrentStation:(Z2ITStation*)inStation
{
  [mCurrentStation setContent:inStation];
}

- (void) updateSegmentDisplay
{
  NSCalendarDate *calendarDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:[self startTime]];
  NSString *calendarString = [calendarDate descriptionWithCalendarFormat:@"%H:%M"];
  [mScheduleTimeSegmentedControl setLabel:calendarString forSegment:kHourSegment];
  
  NSCalendarDate *todaysDate = [NSCalendarDate date];
  int differenceInDays = [calendarDate dayOfYear] - [todaysDate dayOfYear];
  if (differenceInDays == 1)
  {
   [mScheduleTimeSegmentedControl setLabel:@"Tomorrow" forSegment:kDaySegment]; 
  }
  else if (differenceInDays == -1)
  {
   [mScheduleTimeSegmentedControl setLabel:@"Yesterday" forSegment:kDaySegment]; 
  }
  else if (differenceInDays == 0)
  {
   [mScheduleTimeSegmentedControl setLabel:@"Today" forSegment:kDaySegment]; 
  }
  else
  {
    [mScheduleTimeSegmentedControl setLabel:[calendarDate descriptionWithCalendarFormat:@"%A"] forSegment:kDaySegment];
  }
}

- (void) updateSegmentMenus
{
  NSMenu *daysMenu = [[NSMenu alloc] init];
  NSMenu *hoursMenu = [[NSMenu alloc] init];
  
  NSMenuItem *aMenuItem;
  CFGregorianDate aDate = CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),CFTimeZoneCopyDefault());
  CFGregorianDate menuDate = aDate;
  int i=-1;
  for (i=-1; i < 7; i++)
  {
    menuDate.day = aDate.day+i;
    if (i == -1)
    {
      aMenuItem = [daysMenu addItemWithTitle:@"Yesterday" action:@selector(daysMenuItemAction:) keyEquivalent:@""];
    }
    else if (i == 0)
    {
      aMenuItem = [daysMenu addItemWithTitle:@"Today" action:@selector(daysMenuItemAction:) keyEquivalent:@""];
    }
    else if (i == 1)
    {
      aMenuItem = [daysMenu addItemWithTitle:@"Tomorrow" action:@selector(daysMenuItemAction:) keyEquivalent:@""];
    }
    else
    {
      CFAbsoluteTime aTime = CFGregorianDateGetAbsoluteTime(menuDate, CFTimeZoneCopyDefault());
      NSCalendarDate *aCalendarDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate:aTime];
      NSString *menuItemString = [aCalendarDate descriptionWithCalendarFormat:@"%A"];
      aMenuItem = [daysMenu addItemWithTitle:menuItemString action:@selector(daysMenuItemAction:) keyEquivalent:@""];
    }
    [aMenuItem setTarget:self];
//    [aMenuItem setEnabled:YES];
    [aMenuItem setTag:i];
  }
  [mScheduleTimeSegmentedControl setMenu:daysMenu forSegment:kDaySegment];
  
  for (i=0; i < 24 * 60; i += [mScheduleView visibleTimeSpan])
  {
    NSString *menuString = [NSString stringWithFormat:@"%02d:00", (i / 60)];
    aMenuItem = [hoursMenu addItemWithTitle:menuString action:@selector(hoursMenuItemAction:) keyEquivalent:@""];
    [aMenuItem setTarget:self];
//    [aMenuItem setEnabled:YES];
    [aMenuItem setTag:i];
  }
  [mScheduleTimeSegmentedControl setMenu:hoursMenu forSegment:kHourSegment];
  [daysMenu release];
  [hoursMenu release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self) && ([keyPath isEqual:@"startTime"]))
    {
      // Update the segment display for the new time
      [self updateSegmentDisplay];
    }
    if ((object == mCurrentSchedule) && ([keyPath isEqual:@"content"]))
    {
      // Set the time (if we have to change it)
      CFAbsoluteTime startTime = [[[mCurrentSchedule content] time] timeIntervalSinceReferenceDate];
      CFAbsoluteTime endTime = [[[mCurrentSchedule content] endTime] timeIntervalSinceReferenceDate];
      if ((endTime < mStartTime)
          || (startTime > mStartTime + ([mScheduleView visibleTimeSpan] * 60)))
      {
        // We need to set the view to the nearest 30 minutes prior to the selected item
        startTime = startTime - (30*60);
        startTime = floor(startTime / (30*60)) * (30*60);
        [self setStartTime:startTime];
      }
      
      // Change the lineup ?
      NSSet *lineupMaps = [[[mCurrentSchedule content] station] lineupMaps];
      NSEnumerator *mapEnumerator = [lineupMaps objectEnumerator];
      Z2ITLineupMap *aLineupMap;
      bool changeLineup = YES;
      while ((aLineupMap = [mapEnumerator nextObject]) != nil)
      {
        if ([aLineupMap lineup] == [mCurrentLineup content])
        {
          changeLineup = NO;
          break;
        }
      }
      if (changeLineup)
      {
        // We can just change the current lineup to any object referenced in the lineups map set since we know that the current
        // lineup does not include the selected program.
        [mCurrentLineup setContent:[[lineupMaps anyObject] lineup]];
      }
    }
 }

- (IBAction) daysMenuItemAction:(NSMenuItem *)sender
{
  CFGregorianDate newDate = CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),CFTimeZoneCopyDefault());
  CFGregorianDate currentDate = CFAbsoluteTimeGetGregorianDate([self startTime],CFTimeZoneCopyDefault());
  newDate.hour = currentDate.hour;
  newDate.minute = currentDate.minute;
  newDate.second = currentDate.second;
  newDate.day += [sender tag];
  [self setStartTime:CFGregorianDateGetAbsoluteTime(newDate,CFTimeZoneCopyDefault())];
}

- (IBAction) hoursMenuItemAction:(NSMenuItem *)sender
{
  CFGregorianDate newDate = CFAbsoluteTimeGetGregorianDate([self startTime],CFTimeZoneCopyDefault());
  newDate.hour = [sender tag] / 60;
  newDate.minute = [sender tag] % 60;
  [self setStartTime:CFGregorianDateGetAbsoluteTime(newDate,CFTimeZoneCopyDefault())];
}

- (IBAction) scheduleControlClicked:(id)sender
{
  int clickedSegment = [sender selectedSegment];
  switch (clickedSegment)
  {
    case kPreviousTimeSegment:
      [self goBackwards];
      break;
    case kNextTimeSegment:
      [self goForwards];
      break;
    case kHourSegment:
    case kDaySegment:
      {
        CFGregorianDate previousHour = CFAbsoluteTimeGetGregorianDate(CFAbsoluteTimeGetCurrent(),CFTimeZoneCopyDefault());
        if (previousHour.minute > 30)
          previousHour.minute = 30;
        else
          previousHour.minute = 0;
        previousHour.second = 0;
        [self setStartTime:CFGregorianDateGetAbsoluteTime(previousHour,CFTimeZoneCopyDefault())];
      }
      break;
    default:
      break;
  }
}

@end
