/* 

Copyright (c) 2006 Joris Kluivers

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the 
Software, and to permit persons to whom the Software is furnished to do so, subject 
to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

More information:
http://joris.kluivers.nl

*/

#import "JKSourceTableView.h"
#import "JKSourceTableColumnHeaderCell.h"
#import "RBSplitView.h"

@implementation JKSourceTableView

- (id) initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	
	if (self) {	
          NSRect headerFrame = frame;
          headerFrame.size.height = 16;
          [self setHeaderView:[[JKSourceTableHeaderView alloc] initWithFrame:headerFrame]];
	}
	
	return self;
}

- (void) awakeFromNib {
	[self setBackgroundColor:[NSColor colorWithDeviceRed:0.906 green:0.930 blue:0.965 alpha:1.0]];
	[self setIntercellSpacing:NSMakeSize(0.0, 0.1)];
	heightCache = [[NSMutableDictionary alloc] init];
        
        NSRect headerFrame = [self frame];
        headerFrame.size.height = 16;
        [self setHeaderView:[[JKSourceTableHeaderView alloc] initWithFrame:headerFrame]];
}

- (float) heightForRow:(int)row {
	if ([[self delegate] respondsToSelector:@selector(heightFor:row:)]) {
		return [[self delegate] heightFor:self row:row];
	}
	
	return [self rowHeight];
}

- (Class) cellClassForRow:(int) row {
	switch (row) {
		case 0:
		case 1:
		default:
			return [[[self tableColumns] objectAtIndex:0] dataCell];
			break;
	}
}

- (NSRect) rectOfRow:(int)row {	
	NSNumber *cachedY = [heightCache objectForKey:[NSNumber numberWithInt:row]];
	float y = 0;
	
	if (cachedY == nil) {
		if (row > 0) {
			NSRect previousRect = [self rectOfRow:row - 1];
			y = previousRect.origin.y + previousRect.size.height;
			y += 1;
		} else {
			y = 0;
		}
		
		[heightCache setObject:[NSNumber numberWithFloat:y] forKey:[NSNumber numberWithInt:row]];
	} else {
		y = [cachedY floatValue];
	}
	
	NSRect rowRect = [super rectOfRow:row];
	rowRect.origin.y = y;
	rowRect.size.height = [self heightForRow:row];
	
	return rowRect;
}

- (NSRect) frameOfCellAtColumn:(int)col row:(int)row {
	NSRect cellRect = [super frameOfCellAtColumn:col row:row];
	NSRect rowRect = [self rectOfRow:row];
	
	cellRect.origin.y = rowRect.origin.y;
	cellRect.size.height = rowRect.size.height -1;
		
	return cellRect;
}

- (int) rowAtPoint:(NSPoint)p {
	int row = -1;
	int i;
	
	for (i=0; i<[self numberOfRows]; i++) {
		if (NSPointInRect(p, [self rectOfRow:i])) { row = i; break; }
	}
	
	return row;
}

- (void) reloadData {
	[heightCache removeAllObjects];
	
	[super reloadData];
}

@end

@implementation JKSourceTableHeaderView

- (void) updateColumnHeaderCells
{
    NSArray *columns = [[self tableView] tableColumns];
    NSEnumerator *cols = [columns objectEnumerator];
    NSTableColumn *col = nil;
    
    JKSourceTableColumnHeaderCell *headerCell;
    
    while (col = [cols nextObject]) {
        headerCell = [[JKSourceTableColumnHeaderCell alloc]  initTextCell:[[col headerCell] stringValue]];
        [col setHeaderCell:headerCell];
        [headerCell release];
    }
}

- (NSRect) resizeThumbRect
{
  // The right hand 15 pixels should tigger the split view resize cursor
  NSRect resizeThumbRect = NSMakeRect([self frame].origin.x + [self frame].size.width - 15, [self frame].origin.y, 15, [self frame].size.height);
  return resizeThumbRect;
}

- (void) resetCursorRects
{
  NSCursor* cursor = [RBSplitView cursor:RBSVVerticalCursor];
  NSRect resizeThumbRect = [self resizeThumbRect];
  if (!NSIsEmptyRect(resizeThumbRect))
  {
    [self addCursorRect:resizeThumbRect cursor:cursor];
  }
}

- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
  return YES;
}

- (void)mouseDown:(NSEvent *)theEvent 
{
  // Swallow mouse downs so that click in the header doesn't attempt to re-order the contents of the source list.
}

- (void) setTableView:(NSTableView*)inTableView
{
  [super setTableView:inTableView];
  [self updateColumnHeaderCells];
}

@end