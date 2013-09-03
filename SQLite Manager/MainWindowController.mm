//
//  MainWindowController.m
//  SQLite Manager
//
//  Created by li yipeng on 13-9-3.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "sqlitedb.h"

@interface MainWindowController () <NSTableViewDelegate, NSTableViewDataSource>
{
    DBBrowserDB _db;
    NSTableView *_tableView;
    NSMutableArray *_tableNames;
}
@end

@implementation MainWindowController

@synthesize tableView = _tableView;

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
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
                [self reloadTableView];
            }
            else
            {
                NSLog(@"not open");
            }
        }
    }];
}

- (void)reloadTableView
{
    [self loadData];
    _tableView = [(AppDelegate*)[NSApplication sharedApplication].delegate tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)loadData
{
    if (!_db.isOpen()){
        return;
    }
    _db.updateSchema();
    tableMap::iterator it;
    tableMap tmap = _db.tbmap;
//    Q3ListViewItem * lasttbitem = 0;
    _tableNames = [NSMutableArray array];
    for ( it = tmap.begin(); it != tmap.end(); ++it ) {
//        Q3ListViewItem * tbitem = new Q3ListViewItem( dblistView, lasttbitem );
        //tbitem->setOpen( TRUE );
        [_tableNames addObject:[NSString stringWithUTF8String:it->second.getname().c_str()]];
        /*
        tbitem->setText( 0, it.data().getname() );
        tbitem->setText( 1,  "table" );
        tbitem->setText( 3, it.data().getsql() );
        fieldMap::Iterator fit;
        fieldMap fmap = it.data().fldmap;
        Q3ListViewItem * lastflditem = 0;
        for ( fit = fmap.begin(); fit != fmap.end(); ++fit ) {
            Q3ListViewItem * fielditem = new Q3ListViewItem(tbitem, lastflditem);
            fielditem->setText( 0, fit.data().getname() );
            fielditem->setText( 1, "field"  );
            fielditem->setText( 2, fit.data().gettype() );
            lastflditem = fielditem;
        }
        lasttbitem = tbitem;
         */
    }
    
    indexMap::iterator it2;
    indexMap imap = _db.idxmap;
    for ( it2 = imap.begin(); it2 != imap.end(); ++it2 ) {
        [_tableNames addObject:[NSString stringWithUTF8String:it2->second.getname().c_str()]];
        /*
        Q3ListViewItem * item = new Q3ListViewItem( dblistView, lasttbitem );
        item->setText( 0, it2.data().getname());
        item->setText( 1,  "index"  );
        item->setText( 3, it2.data().getsql() );
        lasttbitem = item ;
         */
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
    return [_tableNames objectAtIndex:row];
}

#pragma mark -
#pragma mark ***** Optional Methods *****

/* NOTE: This method is not called for the View Based TableView.
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
}

/* Sorting support
 This is the indication that sorting needs to be done.  Typically the data source will sort its data, reload, and adjust selections.
 */
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    
}

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



@end
