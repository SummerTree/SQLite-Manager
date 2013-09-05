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

@interface DataRowViewController ()
{
    int recAtTop;
    int recsPerView;
}
@end

@implementation DataRowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
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
    
//    if (mustreset){
        //recAtTop = 0;
        //updateTableView(0);
        //if (findWin) findWin->resetFields(db.getTableFields(db.curBrowseTableName));
//    } else {

        vector<string> fields = db.browseFields;
        
        //dataTable->setNumRows(0);
        //dataTable->setNumCols( fields.size() );
        int cheadnum = 0;
        for ( vector<string>::iterator ct = fields.begin(); ct != fields.end(); ++ct ) {
//            dataTable->horizontalHeader()->setLabel( cheadnum, *ct  );
//            NSLog(@"content %s", ct.c_str());
            cheadnum++;
        }
        
        rowList tab = db.browseRecs;
        int maxRecs = db.getRecordCount();
        int recsThisView = maxRecs - recAtTop;
        
        if (recsThisView>recsPerView)
            recsThisView = recsPerView;
        
        //dataTable->setNumRows( recsThisView);
        
        if ( recsThisView > 0 ) {
            
            int rowNum = 0;
            int colNum = 0;
            string rowLabel;
            for (int i = recAtTop; i < tab.size(); ++i)
            {
                //rowLabel.setNum(recAtTop+rowNum+1);
                //dataTable->verticalHeader()->setLabel( rowNum, rowLabel  );
                colNum = 0;
                vector<string>& rt = tab[i];
                for (int e = 1; e < rt.size(); ++e)
                {
                    string columnName = fields[colNum];
                    string& content = rt[e];
                    NSLog(@"%s %s", columnName.c_str(), content.c_str());
                    //string firstline = content.section( '\n', 0,0 );
                    if (content.length()>MAX_DISPLAY_LENGTH)
                    {
                        //firstline.truncate(MAX_DISPLAY_LENGTH);
                        //firstline.append("...");
                    }
                    //dataTable->setText( rowNum, colNum, firstline);
                    colNum++;
                }
                rowNum++;
                if (rowNum==recsThisView) break;
            }
            
        }
        
        /*
        //dataTable->clearSelection(true);
        if (lineToSelect!=-1){
            //qDebug("inside selection");
            selectTableLine(lineToSelect);
        }
        setRecordsetLabel();
        QApplication::restoreOverrideCursor();
         */
//    }
}

@end
