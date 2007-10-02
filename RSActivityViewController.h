//
//  ActivityViewController.h
//  recsched
//
//  Created by Andrew Kimpton on 9/25/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSActivityDisplayProtocol.h"

@interface RSActivityViewController : NSObject <RSActivityDisplay> {
  IBOutlet NSProgressIndicator *mParsingProgressIndicator;
  IBOutlet NSTextField *mParsingProgressInfoField;
}

@end
