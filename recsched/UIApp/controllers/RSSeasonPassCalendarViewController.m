//  Copyright (c) 2007, Andrew Kimpton
//  
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following
//  conditions are met:
//  
//  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  The names of its contributors may not be used to endorse or promote products derived from this software without specific prior
//  written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
//  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "RSSeasonPassCalendarViewController.h"
#import "RSCalendarMonthView.h"

@interface RSSeasonPassCalendarViewController (Private)

@end;

enum {
  kPreviousCellTag = 0, 
  kWeekCellTag,
  kMonthCellTag,
  kNextCellTag
};

@implementation RSSeasonPassCalendarViewController

- (id) init
{
  self = [super init];
  if (self != nil) {
      self.selectedDate = [NSCalendarDate calendarDate];
      if (![NSBundle loadNibNamed:@"SeasonPassCalendarView" owner:self])
      {
        NSLog(@"Error loading SeasonPassCalendarView NIB");
        [self release];
        return nil;
      }
  }
  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) awakeFromNib
{
  [mCalendarContainerView addSubview:mMonthView];
  [mCalendarContainerView addSubview:mWeekView];
  
  [mMonthView setFrameSize:[mCalendarContainerView frame].size];
  [mWeekView setFrameSize:[mCalendarContainerView frame].size];
  self.displayingWeeks = YES;
}

#pragma mark View Handling

- (NSView*) view
{
  return mSeasonPassCalendarView;
}

- (BOOL) seasonPassCalendarViewHidden
{
  return seasonPassCalendarViewHidden;
}

- (void) setSeasonPassCalendarViewHidden:(BOOL)isHidden
{
  [mSeasonPassCalendarView setHidden:isHidden];
  seasonPassCalendarViewHidden = isHidden;
}

- (BOOL) displayingMonths
{
  return displayingMonths;
}

- (void) setDisplayingMonths:(BOOL)displayMonths
{
  if (displayMonths == YES)
  {
    self.displayingWeeks = NO;
    self.displayStartDate = [self.selectedDate dateByAddingYears:0 months:0 days:-([self.selectedDate dayOfMonth]-1) hours:0 minutes:0 seconds:0];
    [mViewSegmentedControl selectSegmentWithTag:kMonthCellTag];
  }
  displayingMonths = displayMonths;
  [mMonthView setHidden:!displayMonths];
}

- (BOOL) displayingWeeks
{
  return displayingWeeks;
}

- (void) setDisplayingWeeks:(BOOL)displayWeeks
{
  if (displayWeeks == YES)
  {
    self.displayingMonths = NO;
    self.displayStartDate = [self.selectedDate dateByAddingYears:0 months:0 days:-[self.selectedDate dayOfWeek] hours:0 minutes:0 seconds:0];
  }
  displayingWeeks = displayWeeks;
  [mViewSegmentedControl setSelected:displayWeeks forSegment:kWeekCellTag];
  [mWeekView setHidden:!displayWeeks];
}

#pragma mark Actions

- (IBAction) segmentCellClicked:(id)sender
{
  int clickedSegmentTag = [[sender cell] tagForSegment:[sender selectedSegment]];
  switch (clickedSegmentTag)
  {
    case kPreviousCellTag:
      if (self.displayingMonths)
      {
        [mViewSegmentedControl setSelected:YES forSegment:kMonthCellTag];
        self.displayStartDate = [self.displayStartDate dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0]; 
      }
      else if (self.displayingWeeks)
      {
        [mViewSegmentedControl setSelected:YES forSegment:kWeekCellTag];
        self.displayStartDate = [self.displayStartDate dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0]; 
      }
      break;
    case kNextCellTag:
      if (self.displayingMonths)
      {
        [mViewSegmentedControl setSelected:YES forSegment:kMonthCellTag];
        self.displayStartDate = [self.displayStartDate dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0]; 
      }
      else if (self.displayingWeeks)
      {
        [mViewSegmentedControl setSelected:YES forSegment:kWeekCellTag];
        self.displayStartDate = [self.displayStartDate dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:0]; 
      }
      break;
    case kMonthCellTag:
      self.displayingMonths = YES;
      break;
    case kWeekCellTag:
      self.displayingWeeks = YES;
      break;
    default:
      break;
  }
}

@synthesize displayStartDate;
@synthesize selectedDate;

#pragma mark CalendarView Delegate Methods

- (NSArray*) calendarMonthView:(RSCalendarMonthView*)calendarMonthView eventListForDate:(NSCalendarDate*)date
{
  if ([[NSApp delegate] managedObjectContext] == nil)
  {
    return nil;
  }
  
  NSCalendarDate *beginningOfDay = [date dateByAddingYears:0 months:0 days:0 hours:-[date hourOfDay] minutes:-[date minuteOfHour] seconds:-[date secondOfMinute]];
  NSCalendarDate *endOfDay = [beginningOfDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
  NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Recording" inManagedObjectContext:[[NSApp delegate] managedObjectContext]];
  NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
  [request setEntity:entityDescription];
   
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"schedule.time >= %@ and schedule.time < %@", beginningOfDay, endOfDay];
  [request setPredicate:predicate];
  
  NSError *error = nil;
  NSArray *array = [[[NSApp delegate] managedObjectContext] executeFetchRequest:request error:&error];
  if ([array count] > 0)
  {
    return [array autorelease];
  }
  else
  {
    return nil;
  }
}

@end
