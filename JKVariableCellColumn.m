//
//  JKVariableCellColumn.m
//  JKSourceTableView
//
//  Created by ruud on 12/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

// http://www.corbinstreehouse.com/blog/?p=46

#import "JKVariableCellColumn.h"
#import "JKSourceTableView.h"


@implementation JKVariableCellColumn
- (id) dataCellForRow:(int)row {
	id delegate = [[self tableView] delegate];
	
	if ([delegate respondsToSelector:@selector(tableColumn:inTableView:dataCellForRow:)]) {
		id cell = [delegate tableColumn:self inTableView:[self tableView] dataCellForRow:row];
		if (cell != nil) {
			return cell;
		}
	}
	
	return [super dataCellForRow:row];
}
@end
