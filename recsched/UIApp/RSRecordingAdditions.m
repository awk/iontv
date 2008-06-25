//  Copyright (c) 2008, Andrew Kimpton
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

#import "RSRecordingAdditions.h"
#import "RSSourceListKeys.h"
#import "Z2ITSchedule.h"
#import "Z2ITProgram.h"

@implementation RSRecording (SourceListAdditions)

- (void) buildSourceListNodeAndAddTo:(NSMutableArray *)anArray
{
  NSMutableDictionary *aFutureRecordingNode = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *aParentNode = nil;
  NSMutableArray *childrenArray = nil;
  BOOL foundParent = NO;
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];

  [dateFormatter setDateStyle:NSDateFormatterShortStyle];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  NSString *parentLabel = [dateFormatter stringFromDate:self.schedule.time];

  NSEnumerator *anEnumerator = [anArray objectEnumerator];
  while (!foundParent && ((aParentNode = [anEnumerator nextObject]) != nil))
  {
    if ([(NSString*)([aParentNode valueForKey:RSSourceListLabelKey]) compare:parentLabel] == NSOrderedSame)
    {
      foundParent = YES;
    }
  }

  if (!foundParent)
  {
    // Make a new parent node
    aParentNode = [[NSMutableDictionary alloc] init];
    [aParentNode setValue:parentLabel forKey:RSSourceListLabelKey];
    childrenArray = [NSMutableArray arrayWithCapacity:3];
    [aParentNode setValue:childrenArray forKey:RSSourceListChildrenKey];
    [anArray addObject:aParentNode];
    [aParentNode release];
  }
  else
  {
    // Retrieve the appropriate parent node
    childrenArray = [aParentNode valueForKey:RSSourceListChildrenKey];
  }

  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  NSString *timeStr = [dateFormatter stringFromDate:self.schedule.time];
  NSString *labelStr = [NSString stringWithFormat:@"%@ - %@", timeStr, self.schedule.program.title];
  [aFutureRecordingNode setValue:labelStr forKey:RSSourceListLabelKey];
  [aFutureRecordingNode setValue:[self objectID] forKey:RSSourceListObjectIDKey];
  [aFutureRecordingNode setValue:@"futureRecordingSelected:" forKey:RSSourceListActionMessageNameKey];
  [aFutureRecordingNode setValue:[NSNumber numberWithBool:YES] forKey:RSSourceListDeletableKey];
  [aFutureRecordingNode setValue:@"deleteFutureRecording:" forKey:RSSourceListDeleteMessageNameKey];
  
  [childrenArray addObject:aFutureRecordingNode];
  [aFutureRecordingNode release];
}

@end
