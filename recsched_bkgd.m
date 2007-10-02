#import <Foundation/Foundation.h>

#import "RecSchedServer.h"

NSString *kRecServerConnectionName = @"recsched_bkgd_server";

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"recsched_bkgd STARTING");
    NSConnection *theConnection;

    theConnection = [NSConnection defaultConnection];
    RecSchedServer *serverObject = [[RecSchedServer alloc] init];
    [theConnection setRootObject:serverObject];
    if ([theConnection registerName:kRecServerConnectionName] == NO) 
    {
            /* Handle error. */
            NSLog(@"Error registering connection");
            [pool release];
            return -1;
    }
    
    double resolution = 1.0;
    BOOL isRunning;
    do {
        NSDate* next = [NSDate dateWithTimeIntervalSinceNow:resolution]; 
        isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                    beforeDate:next];
    } while (isRunning && ![serverObject shouldExit]);

    NSLog(@"recsched_bkgd EXITING");
    [serverObject release];
    [pool release];
    return 0;
}
