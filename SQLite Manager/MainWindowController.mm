//
//  MainWindowController.m
//  SQLite Manager
//
//  Created by li yipeng on 13-9-3.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "SidebarTableCellView.h"
#import "DataRowViewController.h"

@interface TableObject : NSObject

@property (nonatomic, retain) NSString *name;

@property (nonatomic, retain) NSString *sql;

@end

@implementation TableObject

@synthesize name;

@synthesize sql;

@end

@interface MainWindowController () <NSTableViewDelegate, NSTableViewDataSource, NSOutlineViewDelegate, NSOutlineViewDataSource>
{
    DBBrowserDB _db;
    NSView *_rightContentView;
    NSMutableArray *_tableNames;
    
    DataRowViewController *_browseViewController;
}
@end

@implementation MainWindowController

@synthesize rightContentView = _rightContentView;

@synthesize sidebarOutlineView = _sidebarOutlineView;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        _db = DBBrowserDB();
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.sidebarOutlineView.delegate = self;
    self.sidebarOutlineView.dataSource = self;
}

- (DBBrowserDB)database
{
    return _db;
}

- (IBAction)openDocument:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"db", @"sqlite", nil]];
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            if (_db.open([[theDoc relativePath] UTF8String]))
            {
                NSLog(@"open");
                [self reloadOutlineView];
            }
            else
            {
                NSLog(@"not open");
            }
        }
    }];
}

- (IBAction)schema:(id)sender
{
    
}

- (IBAction)browse:(NSString*)table
{
    if (!_browseViewController) {
        _browseViewController = [[DataRowViewController alloc] initWithNibName:@"DataRowViewController" bundle:nil];
        NSView *view = [_browseViewController view];
        view.frame = _rightContentView.bounds;
        [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [_rightContentView addSubview:view];
    }
    
    [_browseViewController browseTable:table];
}

- (IBAction)runSQL:(id)sender
{
    [_browseViewController executeQuery];
}

- (void)reloadOutlineView
{
    [self loadData];
    [self loadDatas];
}

- (void)loadData
{
    if (!_db.isOpen()){
        return;
    }
    _db.updateSchema();
    tableMap::iterator it;
    tableMap tmap = _db.tbmap;
    _tableNames = [NSMutableArray array];
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
        TableObject *obj = [[TableObject alloc] init];
        obj.name = [NSString stringWithUTF8String:it->second.getname().c_str()];
        obj.sql = [NSString stringWithUTF8String:it->second.getsql().c_str()];
        [_tableNames addObject:obj];
    }
    
    indexMap::iterator it2;
    indexMap imap = _db.idxmap;
    for ( it2 = imap.begin(); it2 != imap.end(); ++it2 ) {
        TableObject *obj = [[TableObject alloc] init];
        obj.name = [NSString stringWithUTF8String:it2->second.getname().c_str()];
        obj.sql = [NSString stringWithUTF8String:it2->second.getsql().c_str()];
        [_tableNames addObject:obj];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_tableNames count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    TableObject *obj = [_tableNames objectAtIndex:row];
    
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        return obj.name;
    }
    else if ([tableColumn.identifier isEqualToString:@"sql"])
    {
        return obj.sql;
    }
    return @"";//[_tableNames objectAtIndex:row];
}

#pragma mark -
#pragma mark ***** Optional Methods *****

/* NOTE: This method is not called for the View Based TableView.
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
}

- (void)loadDatas
{
    // The basic recipe for a sidebar. Note that the selectionHighlightStyle is set to NSTableViewSelectionHighlightStyleSourceList in the nib
    [_sidebarOutlineView sizeLastColumnToFit];
    [_sidebarOutlineView reloadData];
    [_sidebarOutlineView setFloatsGroupRows:NO];
    
    // NSTableViewRowSizeStyleDefault should be used, unless the user has picked an explicit size. In that case, it should be stored out and re-used.
    [_sidebarOutlineView setRowSizeStyle:NSTableViewRowSizeStyleDefault];
    
    // Expand all the root items; disable the expansion animation that normally happens
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [_sidebarOutlineView expandItem:nil expandChildren:YES];
    [NSAnimationContext endGrouping];
}

- (void)_setContentViewToName:(NSString *)name {
    //    if (_currentContentViewController) {
    //        [[_currentContentViewController view] removeFromSuperview];
    //        [_currentContentViewController release];
    //    }
    //    _currentContentViewController = [[NSViewController alloc] initWithNibName:name bundle:nil]; // Retained
    //    NSView *view = [_currentContentViewController view];
    //    view.frame = _mainContentView.bounds;
    //    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    //    [_mainContentView addSubview:view];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    if ([_sidebarOutlineView selectedRow] != -1) {
        NSString *item = [_sidebarOutlineView itemAtRow:[_sidebarOutlineView selectedRow]];
        [self browse:item];
//        if ([_sidebarOutlineView parentForItem:item] != nil) {
            // Only change things for non-root items (root items can be selected, but are ignored)
//            [self _setContentViewToName:item];
//        }
    }
}

//- (NSArray *)_childrenForItem:(id)item {
//    NSArray *children;
//    if (item == nil) {
//        children = _topLevelItems;
//    } else {
//        children = [_childrenDictionary objectForKey:item];
//    }
//    return children;
//}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    TableObject *tableObject = [_tableNames objectAtIndex:index];
    return tableObject.name;
//    return [[self _childrenForItem:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return NO;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return [_tableNames count];
//    return [[self _childrenForItem:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return NO;
//    return [_topLevelItems containsObject:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    // As an example, hide the "outline disclosure button" for FAVORITES. This hides the "Show/Hide" button and disables the tracking area for that row.
    if ([item isEqualToString:@"Favorites"]) {
        return NO;
    } else {
        return YES;
    }
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // For the groups, we just return a regular text view.
    if (NO){//[_topLevelItems containsObject:item]) {
        NSTextField *result = [outlineView makeViewWithIdentifier:@"HeaderTextField" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        NSString *value = [item uppercaseString];
        [result setStringValue:value];
        return result;
    } else  {
        // The cell is setup in IB. The textField and imageView outlets are properly setup.
        // Special attributes are automatically applied by NSTableView/NSOutlineView for the source list
        SidebarTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        result.textField.stringValue = item;
        // Setup the icon based on our section
        id parent = [outlineView parentForItem:item];
        NSInteger index = 5;//[_topLevelItems indexOfObject:parent];
        NSInteger iconOffset = index % 4;
        switch (iconOffset) {
            case 0: {
                result.imageView.image = [NSImage imageNamed:NSImageNameIconViewTemplate];
                break;
            }
            case 1: {
                result.imageView.image = [NSImage imageNamed:NSImageNameHomeTemplate];
                break;
            }
            case 2: {
                result.imageView.image = [NSImage imageNamed:NSImageNameQuickLookTemplate];
                break;
            }
            case 3: {
                result.imageView.image = [NSImage imageNamed:NSImageNameSlideshowTemplate];
                break;
            }
        }
        BOOL hideUnreadIndicator = YES;
        // Setup the unread indicator to show in some cases. Layout is done in SidebarTableCellView's viewWillDraw
        if (index == 0) {
            // First row in the index
            hideUnreadIndicator = NO;
            [result.button setTitle:@"42"];
            [result.button sizeToFit];
            // Make it appear as a normal label and not a button
            [[result.button cell] setHighlightsBy:0];
        } else if (index == 2) {
            // Example for a button
            hideUnreadIndicator = NO;
            result.button.target = self;
            result.button.action = @selector(buttonClicked:);
            [result.button setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
            // Make it appear as a button
            [[result.button cell] setHighlightsBy:NSPushInCellMask|NSChangeBackgroundCellMask];
        }
        [result.button setHidden:hideUnreadIndicator];
        return result;
    }
}

- (void)buttonClicked:(id)sender {
    // Example target action for the button
    NSInteger row = [_sidebarOutlineView rowForView:sender];
    NSLog(@"row: %ld", row);
}

- (IBAction)sidebarMenuDidChange:(id)sender {
    // Allow the user to pick a sidebar style
    NSInteger rowSizeStyle = [sender tag];
    [_sidebarOutlineView setRowSizeStyle:(NSTableViewRowSizeStyle)rowSizeStyle];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    for (NSInteger i = 0; i < [menu numberOfItems]; i++) {
        NSMenuItem *item = [menu itemAtIndex:i];
        if (![item isSeparatorItem]) {
            // In IB, the tag was set to the appropriate rowSizeStyle. Read in that value.
            NSInteger state = ([item tag] == [_sidebarOutlineView rowSizeStyle]) ? 1 : 0;
            [item setState:state];
        }
    }
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMinimumPosition < 75) {
        proposedMinimumPosition = 75;
    }
    return proposedMinimumPosition;
}

@end

/* Dragging Source Support - Required for multi-image dragging. Implement this method to allow the table to be an NSDraggingSource that supports multiple item dragging. Return a custom object that implements NSPasteboardWriting (or simply use NSPasteboardItem). If this method is implemented, then tableView:writeRowsWithIndexes:toPasteboard: will not be called.
 */
//- (id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row NS_AVAILABLE_MAC(10_7);

/* Dragging Source Support - Optional. Implement this method to know when the dragging session is about to begin and to potentially modify the dragging session.'rowIndexes' are the row indexes being dragged, excluding rows that were not dragged due to tableView:pasteboardWriterForRow: returning nil. The order will directly match the pasteboard writer array used to begin the dragging session with [NSView beginDraggingSessionWithItems:event:source]. Hence, the order is deterministic, and can be used in -tableView:acceptDrop:row:dropOperation: when enumerating the NSDraggingInfo's pasteboard classes.
 */
//- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes NS_AVAILABLE_MAC(10_7);

/* Dragging Source Support - Optional. Implement this method to know when the dragging session has ended. This delegate method can be used to know when the dragging source operation ended at a specific location, such as the trash (by checking for an operation of NSDragOperationDelete).
 */
//- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation NS_AVAILABLE_MAC(10_7);

/* Dragging Destination Support - Required for multi-image dragging. Implement this method to allow the table to update dragging items as they are dragged over the view. Typically this will involve calling [draggingInfo enumerateDraggingItemsWithOptions:forView:classes:searchOptions:usingBlock:] and setting the draggingItem's imageComponentsProvider to a proper image based on the content. For View Based TableViews, one can use NSTableCellView's -draggingImageComponents. For cell based TableViews, use NSCell's draggingImageComponentsWithFrame:inView:.
 */
//- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id <NSDraggingInfo>)draggingInfo NS_AVAILABLE_MAC(10_7);

/* Dragging Source Support - Optional for single-image dragging. Implement this method to support single-image dragging. Use the more modern tableView:pasteboardWriterForRow: to support multi-image dragging. This method is called after it has been determined that a drag should begin, but before the drag has been started.  To refuse the drag, return NO.  To start a drag, return YES and place the drag data onto the pasteboard (data, owner, etc...).  The drag image and other drag related information will be set up and provided by the table view once this call returns with YES.  'rowIndexes' contains the row indexes that will be participating in the drag.
 */
//- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;

/* Dragging Destination Support - This method is used by NSTableView to determine a valid drop target. Based on the mouse position, the table view will suggest a proposed drop 'row' and 'dropOperation'. This method must return a value that indicates which NSDragOperation the data source will perform. The data source may "re-target" a drop, if desired, by calling setDropRow:dropOperation: and returning something other than NSDragOperationNone. One may choose to re-target for various reasons (eg. for better visual feedback when inserting into a sorted position).
 */
//- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation;

/* Dragging Destination Support - This method is called when the mouse is released over an NSTableView that previously decided to allow a drop via the validateDrop method. The data source should incorporate the data from the dragging pasteboard at this time. 'row' and 'dropOperation' contain the values previously set in the validateDrop: method.
 */
//- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation;

/* Dragging Destination Support - NSTableView data source objects can support file promised drags by adding NSFilesPromisePboardType to the pasteboard in tableView:writeRowsWithIndexes:toPasteboard:.  NSTableView implements -namesOfPromisedFilesDroppedAtDestination: to return the results of this data source method.  This method should returns an array of filenames for the created files (filenames only, not full paths).  The URL represents the drop location.  For more information on file promise dragging, see documentation on the NSDraggingSource protocol and -namesOfPromisedFilesDroppedAtDestination:.
 */
//- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet;
/* Sorting support
 This is the indication that sorting needs to be done.  Typically the data source will sort its data, reload, and adjust selections.
 */
//- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
