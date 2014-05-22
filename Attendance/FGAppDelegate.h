//
//  FGAppDelegate.h
//  Attendance
//
//  Created by wangzz on 14-5-22.
//  Copyright (c) 2014年 FOOGRY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FGAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSButton *_button;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)onLoadDataButtonAction:(id)sender;

@end
