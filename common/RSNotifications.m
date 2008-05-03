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

#import "RSNotifications.h"

// Sender for notifications from the Background Server App
NSString *RSBackgroundApplication = @"RSBackgroundApplication";


NSString *RSDeviceScanCompleteNotification = @"RSDeviceScanCompleteNotification";
NSString *RSChannelScanCompleteNotification = @"RSChannelScanCompleteNotification";
NSString *RSLineupRetrievalCompleteNotification = @"RSLineupRetrievalCompleteNotification";
NSString *RSScheduleUpdateCompleteNotification = @"RSScheduleUpdateCompleteNotification";
NSString *RSCleanupCompleteNotification = @"RSCleanupCompleteNotification";
NSString *RSDownloadErrorNotification = @"RSDownloadErrorNotification";

NSString *RSRecordingAddedNotification = @"RSRecordingAddedNotification";
NSString *RSRecordingRemovedNotification = @"RSRecordingRemovedNotification";

NSString *RSRecordingAddedRecordingURIKey =  @"recordingURI";
NSString *RSRecordingRemovedRecordingOfScheduleURIKey = @"scheduleURI";

NSString *RSMigrationCompleteNotification = @"RSMigrationCompleteNotification";

NSString *RSSeasonPassAddedNotification = @"RSSeasonPassAddedNotification";
NSString *RSSeasonPassRemovedNotification = @"RSSeasonPassRemovedNotification";

NSString *RSSeasonPassAddedSeasonPassURIKey = @"RSSeasonPassAddedSeasonPassURIKey";
NSString *RSSeasonPassRemovedSeasonPassURIKey = @"RSSeasonPassRemovedSeasonPassURIKey";
