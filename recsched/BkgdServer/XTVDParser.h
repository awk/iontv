//  recsched_bkgd - Background server application retrieves schedule data, performs recordings,
//  transcodes recordings in to H.264 format for iTunes, iPod etc.
//
//  Copyright (C) 2007 Andrew Kimpton
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

#import <Cocoa/Cocoa.h>

extern NSString *kCleanupDateKey;
extern NSString *kPersistentStoreCoordinatorKey;

@interface XTVDParser : NSObject {
  id mReportProgressTo;
  NSManagedObjectContext *mManagedObjectContext;
  size_t mActivityToken;
}

- (void)traverseXMLDocument:(NSXMLDocument *)inXMLDocument lineupsOnly:(BOOL)inLineupsOnly;
- (void)parseXMLFile:(NSString *)filePath lineupsOnly:(BOOL)inLineupsOnly;
- (void)handleError:(NSError *)error;

@end

@interface xtvdParseThread : NSObject {
  NSManagedObjectContext *mManagedObjectContext;
}

- (void)performParse:(id)parseInfo;

@end;

@interface xtvdCleanupThread : NSObject {
}

- (void)performCleanup:(id)cleanupInfo;

@end;

