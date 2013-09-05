//
//  MainWindowController.h
//  SQLite Manager
//
//  Created by li yipeng on 13-9-3.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "sqlitedb.h"

@interface MainWindowController : NSWindowController

@property (nonatomic, strong) IBOutlet NSView *rightContentView;

@property (nonatomic, strong) IBOutlet NSOutlineView *sidebarOutlineView;

- (IBAction)openDocument:(id)sender;

- (IBAction)schema:(id)sender;

- (IBAction)browse:(id)sender;

- (IBAction)runSQL:(id)sender;

- (DBBrowserDB)database;

@end
