//
//  RSSeasonPassCalendarCell.m
//  recsched
//
//  Created by Andrew Kimpton on 5/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RSSeasonPassCalendarCell.h"
#import "RSRecording.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"
#import "AKColorExtensions.h"

@interface RSSeasonPassCalendarCell (Private)

- (void) updateDisplayedList;

@end

@implementation RSSeasonPassCalendarCell

- (id)init {
  self = [super init];
  if (self != nil) {
    [self addObserver:self forKeyPath:@"scheduleList" options:0 context:nil];
  }
  return self;
}

- (void)dealloc {
   [self removeObserver:self forKeyPath:@"scheduleList"];
   [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if ((object == self) && ([keyPath isEqual:@"scheduleList"]))   {
    [self updateDisplayedList];
  }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [super drawInteriorWithFrame:cellFrame inView:controlView];
  cellFrame.size.height -= 12;
  cellFrame = NSInsetRect(cellFrame, 1, 2);
  [mEventString drawInRect:cellFrame];
}

@synthesize scheduleList;

@end

@implementation RSSeasonPassCalendarCell (Private)

- (void)updateDisplayedList {
  [mEventString release];
  mEventString = [[NSMutableAttributedString alloc] init];
  NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:10.0];
  for (RSRecording *aRecording in scheduleList) {
    NSColor *genreColor;
    NSData *genreColorData = [[aRecording.schedule.program genreWithRelevance:0] valueForKeyPath:@"genreClass.color"];
    if (genreColorData) {
      genreColor = [NSUnarchiver unarchiveObjectWithData:genreColorData];
      genreColor = [genreColor darkerColorBy:0.15];
    } else {
      genreColor = [NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    }

    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName,
                                           genreColor, NSForegroundColorAttributeName,
                                           nil];
    NSAttributedString *label = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"•%@\n", aRecording.schedule.program.title] attributes:attrsDictionary];
    [mEventString appendAttributedString:label];
    [label release];
  }
}

@end
