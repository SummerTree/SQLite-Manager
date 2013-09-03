//
//  MainWindowController.m
//  SQLite Manager
//
//  Created by li yipeng on 13-9-3.
//  Copyright (c) 2013年 li yipeng. All rights reserved.
//

#import "MainWindowController.h"
#import "sqlitedb.h"

@interface MainWindowController ()
{
    DBBrowserDB _db;
}
@end

@implementation MainWindowController

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
    [panel beginWithCompletionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            if (_db.open([[theDoc relativePath] UTF8String]))
            {
                NSLog(@"open");
            }
            else
            {
                NSLog(@"not open");
            }
        }
     
     
        
    }];

}


@end
