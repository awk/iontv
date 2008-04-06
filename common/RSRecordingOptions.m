// libRecSchedCommon - Common code shared between UI application and background server
// Copyright (C) 2007 Andrew Kimpton
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import "RSRecordingOptions.h"

NSString *kRSRecordingOptionsKeepUntilSpaceNeeded = @"RSRecordingOptionsKeepUntilSpaceNeeded";
NSString *kRSRecordingOptionsKeepUntilIDelete = @"RSRecordingOptionsKeepUntilIDelete";
NSString *kRSSeasonPassOptionsShowTypeRepeatsAndFirstRuns = @"RSSeasonPassOptionsShowTypeRepeatsAndFirstRuns";
NSString *kRSSeasonPassOptionsShowTypeFirstRunOnly = @"RSSeasonPassOptionsShowTypeFirstRunOnly";
NSString *kRSSeasonPassOptionsShowTypeAllWithDuplicates = @"RSSeasonPassOptionsShowTypeAllWithDuplicates";

@implementation RSRecordingOptions

@dynamic keepUntil;
@dynamic startRecording;
@dynamic stopRecording;
@dynamic recording;

@end

@implementation RSSeasonPassOptions

@dynamic keepAtMost;
@dynamic showType;
@dynamic seasonPass;
@end
