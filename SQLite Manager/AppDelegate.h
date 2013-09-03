//
//  AppDelegate.h
//  SQLite Manager
//
//  Created by li yipeng on 13-9-2.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) MainWindowController *windowController;

@end
