//
//  XTVDParser.h
//  recsched
//
//  Created by Andrew Kimpton on 1/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface XTVDParser : NSObject {

}

+ (void) traverseXMLDocument:(NSXMLDocument*) inXMLDocument reportTo:(MainWindowController*)inMainWindowController;
+ (void) parseXMLFile:(NSString *)filePath reportTo:(MainWindowController*)inMainWindowController;
+ (void) handleError:(NSError*) error;

@end

@interface xtvdParseThread : NSObject

+ (void) performParse:(id)parseInfo;

@end;

@interface xtvdCleanupThread : NSObject

+ (void) performCleanup:(id)cleanupInfo;

@end;

