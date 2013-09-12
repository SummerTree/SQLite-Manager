//
//  DataRowViewController.h
//  SQLite Manager
//
//  Created by li yipeng on 13-9-5.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DataRowViewController : NSViewController

- (void)browseTable:(NSString*)table;

- (void)executeQuery;

@end
