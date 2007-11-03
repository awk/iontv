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

#import "RSColorDictionary.h"
#import <objc/runtime.h>

@implementation RSColorDictionary

static NSMutableDictionary *sColorDictionaries = nil;

+ (void)initialize
{
    if ( self == [RSColorDictionary class] ) 
	{
		sColorDictionaries = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
}

struct colorDetails
{
	float red;
	float green;
	float blue;
	NSString *key;
};

struct colorDetails defaultColorList[] = {
  { 157, 215, 118, @"Movie" },
  { 164, 218, 255, @"Children" },
  { 164, 218, 255, @"Children-music" },
  { 255, 217, 228, @"Sports non-event" },
  { 255, 217, 228, @"Sports event" },
  { 255, 217, 228, @"Sports talk" },
  { 217, 245, 195, @"Special" },
  { 232, 209, 255, @"Reality" },
  { 0, 185, 255, @"Sitcom" },
  { 0, 185, 255, @"Comedy" },
  { 0, 185, 255, @"Standup" },
  { 255, 156, 184, @"Religious" },
  { 255, 162, 235, @"Music" },
  { 255, 162, 235, @"Music special" },
  { 123, 169, 255, @"Drama" },
  { 123, 169, 255, @"Crime drama" },
  { 0, 108, 179, @"Talk" },
  { 173, 44, 81, @"Documentary" },
  { 50, 107, 13, @"News" },
  { 50, 107, 13, @"Bus./financial" },
  { 50, 107, 13, @"Newsmagazine" },
  { 50, 107, 13, @"Public affairs" },
  { 114, 75, 164, @"House/garden" },
  { 114, 75, 164, @"Cooking" },
  { 114, 75, 164, @"How-to" },
  { 114, 75, 164, @"Home improvement" }
};

+ (NSDictionary*) colorDictionaryNamedDefault
{
	NSLog(@"returning default color dictionary");
	
	int numColors = sizeof(defaultColorList) / sizeof(struct colorDetails);
	
	NSMutableDictionary *aDictionary = [NSMutableDictionary dictionaryWithCapacity:numColors];
	
	int i=0;
	for (i=0; i < numColors; i++)
	{
		[aDictionary setValue:[NSColor colorWithDeviceRed:defaultColorList[i].red/255.0 green:defaultColorList[i].green/255.0 blue:defaultColorList[i].blue/255.0 alpha:1.0] forKey:defaultColorList[i].key];
	}
	return aDictionary;
}

+ (NSDictionary*) colorDictionaryNamed:(NSString*)dictionaryName
{
	NSDictionary *aDictionary = nil;
	if (sColorDictionaries)
		aDictionary = [sColorDictionaries valueForKey:dictionaryName];

	if (!aDictionary)
	{
		if ([dictionaryName compare:@"Default"] == NSOrderedSame)
		{
			aDictionary = [RSColorDictionary colorDictionaryNamedDefault];
			if (aDictionary)
				[sColorDictionaries setValue:aDictionary forKey:dictionaryName];
		}
	}
	
	return aDictionary;
}

@end
