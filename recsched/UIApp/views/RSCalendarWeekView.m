//
//  RSCalendarWeekView.m
//  recsched
//
//  Created by Andrew Kimpton on 5/8/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSCalendarWeekView.h"
#import "RSSeasonPassCalendarViewController.h"
#import "RSRecording.h"
#import "RSScheduleCell.h"
#import "Z2ITProgram.h"
#import "Z2ITSchedule.h"

const float kHoursColumnWidth = 50.0;
const float kHeaderHeight = 24.0;
const float kHoursPerPage = 6.0;
const float kHoursPerDay = 24.0;
const float kSegmentsPerHour = 4.0;

@interface RSCalendarWeekView(Private)

- (void)updateDrawingStartDate;
- (void)updateTabStopPositions;
- (void)updateRecordingEvents;
- (void)frameDidChangeNotification:(NSNotification *)aNotification;
- (void)scrollerChanged:(id)sender;

- (void)drawHourRowsInRect:(NSRect) rect;
- (void)drawEventsInRect:(NSRect) rect;
@end

NSString *kEventsArrayRecordingsKey = @"eventsArrayRecordingsKey";
NSString *kEventsArrayCellsKey = @"eventsArrayCellsKey";

@implementation RSCalendarWeekView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
    [self setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChangeNotification:) name:NSViewFrameDidChangeNotification object:self];

    // Add the scrollbar on the right side
    NSRect scrollerFrame = frame;
    scrollerFrame.size.width = [NSScroller scrollerWidth];
    scrollerFrame.size.height -= kHeaderHeight;
    scrollerFrame.origin.x = NSMaxX(frame) - scrollerFrame.size.width;
    mVertScroller = [[NSScroller alloc] initWithFrame:scrollerFrame];
    [self addSubview:mVertScroller];
    [mVertScroller setFloatValue:0.0 knobProportion:kHoursPerPage / kHoursPerDay];
    [mVertScroller setAutoresizingMask:NSViewMinXMargin | NSViewHeightSizable];
    [mVertScroller setEnabled:YES];
    [mVertScroller setAction:@selector(scrollerChanged:)];
    [mVertScroller setTarget:self];
  }

  return self;
}

- (void) awakeFromNib {
  [mCalendarController addObserver:self forKeyPath:@"displayStartDate" options:0 context:nil];
  [mCalendarController addObserver:self forKeyPath:@"selectedDate" options:0 context:nil];
}

- (void)drawRect:(NSRect)rect {
  // Fill with white background
  [[NSColor whiteColor] setFill];
  [NSBezierPath fillRect:rect];


  NSRect headerFrame = [self frame];
  headerFrame.size.height = kHeaderHeight;
  headerFrame.origin.y = NSMaxY([self frame]) - headerFrame.size.height;

  // Draw the dividing line across the top
  [[NSColor colorWithDeviceHue:0 saturation:0 brightness:204.0/255.0 alpha:1.0] setStroke];
  NSPoint leftEdge = headerFrame.origin;
  NSPoint rightEdge = NSMakePoint(NSMaxX(headerFrame), headerFrame.origin.y);
  leftEdge.y += 0.5;
  rightEdge.y += 0.5;
  NSBezierPath *aPath = [[[NSBezierPath alloc] init] autorelease];
  [aPath moveToPoint:leftEdge];
  [aPath lineToPoint:rightEdge];
  [aPath setLineWidth:1.0];
  [aPath stroke];

  // Draw the hour column boundary
  [aPath removeAllPoints];
  NSPoint top, bottom;
  top.y = headerFrame.origin.y;
  bottom.y = NSMinY([self frame]);
  top.x = bottom.x = kHoursColumnWidth;
  [aPath moveToPoint:bottom];
  [aPath lineToPoint:top];
  [aPath setLineWidth:1.0];
  [aPath stroke];

  // Draw the day column boundaries
  [aPath removeAllPoints];
  int i = 0;
  for (i = 1; i < 7; i++) {
    NSPoint top, bottom;
    top.y = headerFrame.origin.y;
    bottom.y = NSMinY([self frame]);
    top.x = bottom.x = floor(i * (([self frame].size.width - kHoursColumnWidth - [NSScroller scrollerWidth]) / 7.0)) + 0.5 + kHoursColumnWidth;
    [aPath moveToPoint:bottom];
    [aPath lineToPoint:top];
  }
  [aPath setLineWidth:1.0];
  [aPath stroke];

  NSRect textFrame = headerFrame;
  NSSize textSize = [mDaysHeaderString size];
  textFrame.size.height = textSize.height;
  textFrame.origin.y += 3;
  [mDaysHeaderString drawInRect:textFrame];

  [self drawHourRowsInRect:rect];
  [self drawEventsInRect:rect];
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if ((object == mCalendarController) && ([keyPath isEqual:@"displayStartDate"]))   {
    [self updateRecordingEvents];
    [self updateDrawingStartDate];
    [self updateTabStopPositions];
  }
  if ((object == mCalendarController) && ([keyPath isEqual:@"selectedDate"])) {
    [self setNeedsDisplay:YES];
  }
}


@end

@implementation RSCalendarWeekView (Private)

- (void)frameDidChangeNotification:(NSNotification *)aNotification {
  // Make sure the column headings all fit
  [self updateDrawingStartDate];

  [self updateTabStopPositions];
}

- (void)updateTabStopPositions {
  // Create the tab stop list for the days of the week headings
  NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
  [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
  NSMutableArray *tabStopArray = [NSMutableArray arrayWithCapacity:8];

  // A 'fixed' tab stop on the left where the year value goes (above the hours column)
  NSTextTab *aTab = [[[NSTextTab alloc] initWithType:NSCenterTabStopType location:kHoursColumnWidth / 2.0] autorelease];
  [tabStopArray addObject:aTab];

  float daysWidth = [self frame].size.width - kHoursColumnWidth - [NSScroller scrollerWidth];
  int i = 0;
  for (i = 0; i < 7; i++) {
    NSPoint tabPoint;
    tabPoint.x = kHoursColumnWidth + ((daysWidth/7.0) * i) + (0.5 * daysWidth / 7.0);
    NSTextTab *aTab = [[[NSTextTab alloc] initWithType:NSCenterTabStopType location:tabPoint.x] autorelease];
    [tabStopArray addObject:aTab];
  }

  [paragraphStyle setTabStops:tabStopArray];
  NSRange entireStringRange = NSMakeRange(0, [mDaysHeaderString length]);
  [mDaysHeaderString beginEditing];
  [mDaysHeaderString removeAttribute:NSParagraphStyleAttributeName range:entireStringRange];
  [mDaysHeaderString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:entireStringRange];
  [mDaysHeaderString endEditing];
}

- (void)updateDrawingStartDate {
  // The drawing start date is the date of the first sunday preceeding the displayStart date, eg.
  // if the display start date is 05-01-08 (a Thursday) then the drawingStartDate is 04-27-08
  [mDaysHeaderString release];
  mDaysHeaderString = [[NSMutableAttributedString alloc] init];

  int dayOffset = [mCalendarController.displayStartDate dayOfWeek];
  mDrawingStartDate = [mCalendarController.displayStartDate dateByAddingYears:0 months:0 days:-dayOffset hours:0 minutes:0 seconds:0];

  NSColor *headerTextColor = [NSColor colorWithDeviceHue:0 saturation:0 brightness:0 alpha:1.0];
  NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:11.0];
  NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:headerTextColor, NSForegroundColorAttributeName,
                                                                                           font, NSFontAttributeName,
                                                                                           nil];
  NSAttributedString *tabSeperatorString = [[[NSAttributedString alloc] initWithString:@"\t"] autorelease];

  // Add the column heading for the year (above the hours column)
  NSString *dateString = [NSString stringWithFormat:@"\t%@", [mDrawingStartDate descriptionWithCalendarFormat:@"%Y"]];
  NSAttributedString *columnHeaderText;
  columnHeaderText = [[[NSAttributedString alloc] initWithString:dateString attributes:attrsDictionary] autorelease];
  [mDaysHeaderString appendAttributedString:columnHeaderText];

  enum { kLongDateFormat = 0, kMediumDateFormat, kShortDateFormat } dateFormat = kLongDateFormat;
  int i = 0;
  float columnWidth = (([self frame].size.width - kHoursColumnWidth - [NSScroller scrollerWidth]) / 7.0) - 6.0;
  for (i = 0; i < 7; i++) {
    NSCalendarDate *columnDate = [mDrawingStartDate dateByAddingYears:0 months:0 days:i hours:0 minutes:0 seconds:0];
    NSCalendarDate *todaysDate = [NSCalendarDate calendarDate];
    NSString *dateString;
    BOOL resetDateFormat = NO;

    switch (dateFormat) {
      case kLongDateFormat:
        dateString = [NSString stringWithFormat:@"%@", [columnDate descriptionWithCalendarFormat:@"%A, %b %e"]];
        break;
      case kMediumDateFormat:
        dateString = [NSString stringWithFormat:@"%@", [columnDate descriptionWithCalendarFormat:@"%a, %b %e"]];
        break;
      case kShortDateFormat:
        dateString = [NSString stringWithFormat:@"%@", [columnDate descriptionWithCalendarFormat:@"%a %e"]];
        break;
    }

    if (([columnDate yearOfCommonEra] == [todaysDate yearOfCommonEra]) &&
        ([columnDate dayOfYear] == [todaysDate dayOfYear])) {
      NSFont *font = [NSFont fontWithName:@"Helvetica Neue Bold" size:11.0];
      [attrsDictionary setValue:font forKey:NSFontAttributeName];
    } else {
      NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:11.0];
      [attrsDictionary setValue:font forKey:NSFontAttributeName];
    }
    columnHeaderText = [[[NSAttributedString alloc] initWithString:dateString attributes:attrsDictionary] autorelease];
    if ([columnHeaderText size].width > columnWidth) {
      switch (dateFormat) {
        case kLongDateFormat:
          dateFormat = kMediumDateFormat;
          resetDateFormat = YES;
          break;
        case kMediumDateFormat:
          dateFormat = kShortDateFormat;
          resetDateFormat = YES;
          break;
        case kShortDateFormat:
          // Put the string in anyway and just draw it truncated.
          [mDaysHeaderString appendAttributedString:tabSeperatorString];
          [mDaysHeaderString appendAttributedString:columnHeaderText];
          break;
      }
    } else {
      [mDaysHeaderString appendAttributedString:tabSeperatorString];
      [mDaysHeaderString appendAttributedString:columnHeaderText];
    }

    if (resetDateFormat) {
      // Restart the string generation
      i = -1;
      [mDaysHeaderString release];
      mDaysHeaderString = [[NSMutableAttributedString alloc] init];
      NSString *dateString = [NSString stringWithFormat:@"\t%@", [columnDate descriptionWithCalendarFormat:@"%Y"]];
      columnHeaderText = [[[NSAttributedString alloc] initWithString:dateString attributes:attrsDictionary] autorelease];
      [mDaysHeaderString appendAttributedString:columnHeaderText];
    }
  }
  [self setNeedsDisplay:YES];
}

- (void)scrollerChanged:(id)sender {
  float scrollerValue = [sender floatValue];
  switch ([sender hitPart]) {
    case NSScrollerIncrementLine:
      scrollerValue += 1.0 / ((kHoursPerDay - kHoursPerPage) * kSegmentsPerHour);
      break;
    case NSScrollerDecrementLine:
      scrollerValue -= 1.0 / ((kHoursPerDay - kHoursPerPage) * kSegmentsPerHour);
      break;
    case NSScrollerIncrementPage:
      scrollerValue += kHoursPerPage / (kHoursPerDay - kHoursPerPage);
      break;
    case NSScrollerDecrementPage:
      scrollerValue -= kHoursPerPage / (kHoursPerDay - kHoursPerPage);
      break;
    default:
      break;
  }
  [sender setFloatValue:scrollerValue];
  [self setNeedsDisplay:YES];
}

- (void)updateRecordingEvents {
  if ([[NSApp delegate] managedObjectContext] == nil) {
    return; // No Moc to get events from
  }

  [mEventsPerDay release];
  mEventsPerDay = [[NSMutableArray alloc] initWithCapacity:7];

  NSCalendarDate *aDay = [mCalendarController.displayStartDate dateByAddingYears:0
                                                                          months:0
                                                                            days:-[mCalendarController.displayStartDate dayOfWeek]
                                                                           hours:-[mCalendarController.displayStartDate hourOfDay]
                                                                         minutes:-[mCalendarController.displayStartDate minuteOfHour]
                                                                         seconds:-[mCalendarController.displayStartDate secondOfMinute]];
  int i=0;
  for (i = 0; i < 7; i++) {
    NSCalendarDate *endOfDay = [aDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
    NSArray *recordings = [RSRecording fetchRecordingsInManagedObjectContext:[[NSApp delegate] managedObjectContext] afterDate:aDay beforeDate:endOfDay];
    NSMutableArray *scheduleCells = [NSMutableArray arrayWithCapacity:[recordings count]];
    for (RSRecording *aRecording in recordings) {
      RSScheduleCalendarCell *aScheduleCell = [[RSScheduleCalendarCell alloc] initTextCell:@"--"];
      [aScheduleCell setBordered:YES];
      [aScheduleCell setRepresentedObject:aRecording.schedule];
      [aScheduleCell setStringValue:aRecording.schedule.program.title];
      [aScheduleCell setFont:[NSFont fontWithName:@"Helvetica Neue" size:11.0]];
      [scheduleCells addObject:aScheduleCell];
      [aScheduleCell release];
    }
    NSDictionary *cellsAndRecordingsDict = [NSDictionary dictionaryWithObjectsAndKeys:recordings, kEventsArrayRecordingsKey, scheduleCells, kEventsArrayCellsKey, nil];
    [mEventsPerDay addObject:cellsAndRecordingsDict];
    aDay = [aDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
  }
  [self setNeedsDisplay:YES];
}

#pragma mark Drawing Methods

- (void)drawHourRowsInRect:(NSRect)rect {
  NSBezierPath *aPath = [[[NSBezierPath alloc] init] autorelease];
  int i = 0;

  int hoursValue = floor([mVertScroller floatValue] * (kHoursPerDay - kHoursPerPage)) + kHoursPerPage;
  NSColor *headerTextColor = [NSColor colorWithDeviceHue:0 saturation:0 brightness:0 alpha:1.0];
  NSFont *font = [NSFont fontWithName:@"Helvetica Neue" size:11.0];
  NSColor *textColor = [NSColor colorWithDeviceHue:0 saturation:0 brightness:132.0/255.0 alpha:1.0];
  NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:headerTextColor, NSForegroundColorAttributeName,
                                                                                           font, NSFontAttributeName,
                                                                                           textColor, NSForegroundColorAttributeName,
                                                                                           nil];

  // We need to calculate the offset of the horizontal lines due to the position of the scroll bar
  // The scroll bar increments so that each 'line' (in NSScrollbar terms) is 1/kSegmentsPerHour of an hours.
  // So the initial offset of the first line is a portion of the height of 1 hour.
  float hourHeight = (NSMaxY([self frame]) - kHeaderHeight) / kHoursPerPage;
  float unused;
  float vertMotionOffset = modff([mVertScroller floatValue] * (kHoursPerDay - kHoursPerPage), &unused) * hourHeight;
  // Draw kHoursPerPage horizontal lines down the page (one for each hour)
  [aPath removeAllPoints];
  for (i=0; i < kHoursPerPage; i++) {
    NSPoint left, right;
    left.y = right.y = floor((i * hourHeight) + vertMotionOffset) + 0.5;
    left.x = NSMinX([self frame]) + kHoursColumnWidth;
    right.x = NSMaxX([self frame]);
    if (left.y < (NSMaxY([self frame]) - kHeaderHeight)) {
      [aPath moveToPoint:left];
      [aPath lineToPoint:right];
    }
    NSString *timeString = nil;
    if (hoursValue == 12) {
      timeString = [NSString stringWithFormat:@"NOON"];
    } else if (hoursValue < 12) {
      timeString = [NSString stringWithFormat:@"%d AM", hoursValue];
    } else if (hoursValue > 12) {
      timeString = [NSString stringWithFormat:@"%d PM", hoursValue - 12];
    }
    if (timeString) {
      NSPoint textOrigin = NSMakePoint(NSMinX([self frame]), left.y);
      NSRect textRect = [timeString boundingRectWithSize:NSMakeSize(kHoursColumnWidth, [self frame].size.height)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesDeviceMetrics
                                              attributes:attrsDictionary];
      textRect.origin.y = textOrigin.y - textRect.size.height / 2.0;
      textRect.origin.x = kHoursColumnWidth - textRect.size.width - 8;
      if ((NSMinY(textRect) > NSMinY([self frame])) && (NSMaxY(textRect) < NSMaxY([self frame]) - kHeaderHeight)) {
        [timeString drawInRect:textRect withAttributes:attrsDictionary];
      }
    }
    hoursValue--;
  }
  [[NSColor colorWithDeviceHue:0 saturation:0 brightness:204.0/255.0 alpha:1.0] setStroke];
  [aPath setLineWidth:1.0];
  [aPath stroke];


  // Draw kHoursPerPage horizontal lines down the page (one for each  1/2 hour)
  [aPath removeAllPoints];
  for (i=0; i < kHoursPerPage; i++) {
    NSPoint left, right;
    left.y = right.y = floor((i * hourHeight) + (0.5 * hourHeight) + vertMotionOffset) + 0.5;
    left.x = NSMinX([self frame]) + kHoursColumnWidth;
    right.x = NSMaxX([self frame]);
    if (left.y < (NSMaxY([self frame]) - kHeaderHeight)) {
      [aPath moveToPoint:left];
      [aPath lineToPoint:right];
    }
  }
  [[NSColor colorWithDeviceHue:0 saturation:0 brightness:229.0/255.0 alpha:1.0] setStroke];
  [aPath setLineWidth:1.0];
  [aPath stroke];
}

- (void)drawEventsInRect:(NSRect)rect {
  int dayIndex=0;
  NSCalendarDate *aDay = [mCalendarController.displayStartDate dateByAddingYears:0
                                                                          months:0
                                                                            days:-[mCalendarController.displayStartDate dayOfWeek]
                                                                           hours:-[mCalendarController.displayStartDate hourOfDay]
                                                                         minutes:-[mCalendarController.displayStartDate minuteOfHour]
                                                                         seconds:-[mCalendarController.displayStartDate secondOfMinute]];

  [[NSGraphicsContext currentContext] saveGraphicsState];
  [NSBezierPath clipRect:NSMakeRect(NSMinX([self frame]) + kHoursColumnWidth, NSMinY([self frame]), [self frame].size.width - [NSScroller scrollerWidth], [self frame].size.height - kHeaderHeight)];
  for (dayIndex = 0; dayIndex < 7; dayIndex++) {
    NSCalendarDate *endOfDay = [aDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
    NSArray *recordings = [[mEventsPerDay objectAtIndex:dayIndex] valueForKey:kEventsArrayRecordingsKey];
    NSArray *cells = [[mEventsPerDay objectAtIndex:dayIndex] valueForKey:kEventsArrayCellsKey];
    int recordingIndex;
    for (recordingIndex=0; recordingIndex < [recordings count]; recordingIndex++) {
      RSRecording *aRecording = [recordings objectAtIndex:recordingIndex];
      RSScheduleCalendarCell *aScheduleCell = [cells objectAtIndex:recordingIndex];
      NSDate *eventStartTime = aRecording.schedule.time;
      NSDate *eventEndTime = aRecording.schedule.endTime;

      // Clamp events to be within the days time boundaries
      if ([eventStartTime laterDate:aDay] == aDay) {
        eventStartTime = aDay;
      }
      if ([eventEndTime laterDate:endOfDay] == eventEndTime) {
        eventEndTime = endOfDay;
      }

      // Calculate the display rect size and position for the event
      NSRect scheduleFrameRect;
      NSTimeInterval eventDurationInSeconds = [eventEndTime timeIntervalSinceDate:eventStartTime];
      scheduleFrameRect.size.height = (([self frame].size.height - kHeaderHeight) / (kHoursPerPage * 60.0 * 60.0) * eventDurationInSeconds);
      scheduleFrameRect.size.width = ([self frame].size.width - kHoursColumnWidth - [NSScroller scrollerWidth]) / 7;
      scheduleFrameRect.origin.x = kHoursColumnWidth + dayIndex * (([self frame].size.width - kHoursColumnWidth - [NSScroller scrollerWidth]) / 7);

      // We draw 'up' from the events end time. We must also take into account the height of the page and the offset for the bottom of the page.
      NSDate *timeAtBottomOfPage = [aDay addTimeInterval:(kHoursPerPage * 60.0 * 60.0) + ((kHoursPerDay - kHoursPerPage) * 60.0 * 60.0 * [mVertScroller floatValue])];
      NSTimeInterval timeIntervalFromBottomOfPage = [timeAtBottomOfPage timeIntervalSinceDate:eventEndTime];

      scheduleFrameRect.origin.y = ([self frame].size.height - kHeaderHeight) / (kHoursPerPage * 60.0 * 60.0) * timeIntervalFromBottomOfPage;

      [aScheduleCell drawWithFrame:scheduleFrameRect inView:self];
    }
    aDay = [aDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
  }
  [[NSGraphicsContext currentContext] restoreGraphicsState];
}
@end
