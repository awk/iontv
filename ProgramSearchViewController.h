//
//  ProgramSearchViewController.h
//  recsched
//
//  Created by Andrew Kimpton on 2/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProgramSearchViewController : NSObject {
  IBOutlet NSObjectController *mCurrentSchedule;
  IBOutlet NSArrayController *mProgramsArrayController;
}

@end
