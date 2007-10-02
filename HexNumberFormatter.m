//
//  HexNumberFormatter.m
//  recsched
//
//  Created by Andrew Kimpton on 5/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "HexNumberFormatter.h"


@implementation HexNumberFormatter

- (NSString *) stringForObjectValue:(id)inArg
{
  NSException *anException;
  NSString *aValue;
  
  if (inArg != nil)
  {
    if ([inArg isKindOfClass:[NSNumber class]])
    {
      aValue = [NSString stringWithFormat:@"0x%x", [inArg intValue]];
    }
    else
    {
      anException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"Unsupported datatype" userInfo:nil];
      [anException raise];
    }
  }
  else
  {
    anException = [NSException exceptionWithName:NSInvalidArgumentException reason:@"Nil Argument" userInfo:nil];
    [anException raise];
  }
  
  // Return the formatted results
  return aValue;
}

- (BOOL) getObjectValue:(id *)inObj forString:(NSString*)inStr errorDescription:(NSString **)anErr
{
  return [super getObjectValue:inObj forString:inStr errorDescription:anErr];
}

@end
