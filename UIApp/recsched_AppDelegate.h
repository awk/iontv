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

#import "RSCommonAppDelegate.h"
#import "RSStoreUpdateProtocol.h"

extern NSString *RSDownloadErrorNotification;
extern NSString *RSChannelScanCompleteNotification;
extern NSString *RSLineupRetrievalCompleteNotification;
extern NSString *RSScheduleUpdateCompleteNotification;

@class HDHomeRunStation;
@class RSFirstRunWindowController;
@class RSActivityWindowController;

@interface recsched_AppDelegate : RSCommonAppDelegate <RSStoreUpdate>
{
    IBOutlet NSWindow *window;
    
    IBOutlet NSMenuItem *mServerMenuItem;
    
    NSTask      *mVLCTask;
    NSTimer     *mVLCTerminateTimer;

    id mRecServer;
	
	RSActivityWindowController *mActivityWindowController;
        RSFirstRunWindowController *mFirstRunWindowController;
}

- (id) recServer;

- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow;
- (IBAction)launchVLCAction:(id)sender withParentWindow:(NSWindow*)inParentWindow startStreaming:(HDHomeRunStation*)inStation;
- (IBAction)showActivityWindow:(id)sender;
- (IBAction)launchFirstRunWizard:(id)sender;
- (IBAction) quitServer:(id)sender;

- (RSActivityWindowController*) activityWindowController;

@property (retain,getter=recServer) id mRecServer;
@end
