//
//  DataRowViewController.m
//  SQLite Manager
//
//  Created by li yipeng on 13-9-5.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import "DataRowViewController.h"
#import "AppDelegate.h"
#import "MainWindowController.h"
#include <string>

using namespace std;

//@interface ColumnData : NSObject
//
//@property (nonatomic, retain) NSString *columnName;
//@property (nonatomic, retain) NSMutableArray *columnRecords;
//
//@end
//
//@implementation ColumnData
//
//@synthesize columnName = _columnName;
//
//@synthesize columnRecords = _columnRecords;
//
//@end

@interface DataRowViewController () <NSTableViewDelegate, NSTableViewDataSource>
{
    int recAtTop;
    int recsPerView;
    
    NSMutableDictionary *_columnDatas;
}

@property (strong) IBOutlet NSTextView *textView;
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation DataRowViewController

@synthesize textView = _textView;
@synthesize tableView = _tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        recsPerView = 10;
    }
    return self;
}

- (void)browseTable:(NSString*)table
{
    if (![table length]){
        return;
    }
    DBBrowserDB db = [[(AppDelegate*)[NSApplication sharedApplication].delegate windowController] database];
    string tablename = string([table UTF8String]);
    bool mustreset = false;
    if (tablename.compare(db.curBrowseTableName)!=0)
        mustreset = true;
    
    if (!db.browseTable(tablename)){
        return;
    }
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    if (!_columnDatas) {
        _columnDatas = [NSMutableDictionary dictionary];
    } else {
        [_columnDatas removeAllObjects];
    }
    
    vector<string> fields = db.browseFields;
    
//    int cheadnum = 0;
//    for ( vector<string>::iterator ct = fields.begin(); ct != fields.end(); ++ct ) {
//        ColumnData *columnData = [[ColumnData alloc] init];
//        columnData.columnName = [NSString stringWithUTF8String:(*ct).c_str()];
//        columnData.columnRecords = [NSMutableArray array];
//        cheadnum++;
//    }
    
    rowList tab = db.browseRecs;
    int maxRecs = db.getRecordCount();
    int recsThisView = maxRecs - recAtTop;
    
    if (recsThisView>recsPerView)
        recsThisView = recsPerView;
    
    if ( recsThisView > 0 ) {
        
        int rowNum = 0;
        int colNum = 0;
        string rowLabel;
        for (int i = recAtTop; i < tab.size(); ++i)
        {
            colNum = 0;
            vector<string>& rt = tab[i];
            for (int e = 1; e < rt.size(); ++e)
            {
                string columnName = fields[colNum];
                string& content = rt[e];
                NSLog(@"%s %s", columnName.c_str(), content.c_str());
                NSString *columnNameKey = [NSString stringWithUTF8String:columnName.c_str()];
                NSMutableArray *columnRecords = [_columnDatas objectForKey:columnNameKey];
                if (!columnRecords) {
                    columnRecords = [NSMutableArray array];
                    [_columnDatas setObject:columnRecords forKey:columnNameKey];
                }
                [columnRecords addObject:[NSString stringWithUTF8String:content.c_str()]];
                colNum++;
            }
            rowNum++;
            if (rowNum==recsThisView) break;
        }
        
    }
    
    NSArray *columnKeys = [_columnDatas allKeys];
    
    while([[_tableView tableColumns] count] > 0) {
        [_tableView removeTableColumn:[[_tableView tableColumns] lastObject]];
    }
    
    for (NSString *columnKey in columnKeys)
    {
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:columnKey];
        [[column headerCell] setTitle:columnKey];
        [column setWidth:100];
        [_tableView addTableColumn:column];
    }
    [_tableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count = 0;
    NSArray *allColumnsArray =[_columnDatas allValues];
    if ([allColumnsArray count]) {
        count = [[allColumnsArray objectAtIndex:0] count];
    }
    return count;
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *columnKey = tableColumn.identifier;
    
    NSArray *columnRecords = [_columnDatas objectForKey:columnKey];
    
    if ([columnRecords count] > row)
    {
        return [columnRecords objectAtIndex:row];
    }
    else
    {
        return @"";
    }
}

#pragma mark -
#pragma mark ***** Optional Methods *****

/* NOTE: This method is not called for the View Based TableView.
 */
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    
}

@end
