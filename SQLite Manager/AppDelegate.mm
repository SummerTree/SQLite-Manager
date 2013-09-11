//
//  AppDelegate.m
//  SQLite Manager
//
//  Created by li yipeng on 13-9-2.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"

@implementation AppDelegate

@synthesize windowController = _windowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.windowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    //TODO:FIX constraint
    [self.windowController showWindow:self];
}

- (IBAction)openDocument:(id)sender
{
    [self.windowController openDocument:sender];
}

@end
