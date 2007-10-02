//
//  RSOutlineView.h
//  recsched
//
//  Created by Andrew Kimpton on 9/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSOutlineView : NSOutlineView {

}

- (IBAction) delete:(id) sender;

@end

@interface NSObject(RSOutlineViewDatasource)

- (void) deleteSelectedRowsOfOutlineView:(NSOutlineView*)outlineView;

@end

@interface NSObject(RSOutlineViewDelegate)

- (BOOL) outlineView:(NSOutlineView*)outlineView shouldShowDisclosureTriangleForItem:(id)item;

@end
