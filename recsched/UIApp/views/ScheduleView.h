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

#import <Cocoa/Cocoa.h>

@class ScheduleHeaderView;
@class ScheduleStationColumnView;
@class ScheduleGridView;
@class Z2ITSchedule;
@class Z2ITStation;

@interface ScheduleView : NSView {
  IBOutlet ScheduleHeaderView *mHeaderView;
  IBOutlet ScheduleStationColumnView *mStationColumnView;
  IBOutlet ScheduleGridView *mGridView;
  IBOutlet NSScroller *mStationsScroller;

  IBOutlet NSObjectController *mCurrentLineup;
  IBOutlet NSObjectController *mCurrentSchedule;
  NSArray *mSortedStationsArray;
  CFAbsoluteTime mStartTime;
  IBOutlet id delegate;       // Note no 'm' here so that it 'looks like' all the other delegate mechanisms in IB.
}

- (void)setStartTime:(CFAbsoluteTime) inStartTime;
- (void)scrollToStation:(Z2ITStation*) inStation;
- (float)visibleTimeSpan;
- (float)timePerLineIncrement;
- (void)updateStationsScroller;
- (void)sortStationsArray;
- (id)delegate;
- (void)setDelegate:(id)inDelegate;

@property (setter=setStartTime:) CFAbsoluteTime mStartTime;
@end
