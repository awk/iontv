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


#import <Cocoa/Cocoa.h>

// Sender for notifications from the background server app
extern NSString *RSBackgroundApplication;

// Distributed Notifications sent by the background server to the UI App
extern NSString *RSDeviceScanCompleteNotification;
extern NSString *RSChannelScanCompleteNotification;
extern NSString *RSLineupRetrievalCompleteNotification;
extern NSString *RSScheduleUpdateCompleteNotification;
extern NSString *RSCleanupCompleteNotification;
extern NSString *RSDownloadErrorNotification;

extern NSString *RSRecordingAddedNotification;
extern NSString *RSRecordingRemovedNotification;

extern NSString *RSRecordingAddedRecordingURIKey;
extern NSString *RSRecordingRemovedRecordingOfScheduleURIKey;

extern NSString *RSMigrationCompleteNotification;
