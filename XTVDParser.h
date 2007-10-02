//
//  XTVDParser.h
//  recsched
//
//  Created by Andrew Kimpton on 1/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XTVDParser : NSObject {
  id	mReportProgressTo;
  NSManagedObjectContext *mManagedObjectContext;
  size_t	mActivityToken;
}

- (void) traverseXMLDocument:(NSXMLDocument*) inXMLDocument lineupsOnly:(BOOL)inLineupsOnly;
- (void) parseXMLFile:(NSString *)filePath lineupsOnly:(BOOL)inLineupsOnly;
- (void) handleError:(NSError*) error;

@end

@interface xtvdParseThread : NSObject
{
  NSManagedObjectContext *mManagedObjectContext;
}

- (void) performParse:(id)parseInfo;

@end;

@interface xtvdCleanupThread : NSObject
{
}

+ (void) performCleanup:(id)cleanupInfo;

@end;

