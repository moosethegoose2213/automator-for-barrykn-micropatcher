//
//  AppDelegate.m
//  Big Hedge
//
//  Created by Minh on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "AppDelegate.h"
#include "HedgehogViewController.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic,strong) IBOutlet HedgehogViewController *hedgehogViewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Just for fun
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        printf("\n\n              \\ / \\/ \\/ / ,\n");
        printf("            \\ /  \\/ \\/  \\/  / ,\n");
        printf("          \\ \\ \\/ \\/ \\/ \\ \\/ \\/ /\n");
        printf("        .\\  \\/  \\/ \\/ \\/  \\/ / / /\n");
        printf("      '  / / \\/  \\/ \\/ \\/  \\/ \\ \\/ \\\n");
        printf("    .\'     ) \\/ \\/ \\/ \\/  \\/  \\/ \\ / \\\n");
        printf("  /   o    ) \\/ \\/ \\/ \\/ \\/ \\/ \\// /\n");
        printf("o\'_ \',__ .'   ,.,.,.,.,.,.,.,\'- \'%%\n");
        printf("            // \\\\          // \\\\\n");
        printf("           \'\'  \'\'         \'\'  \'\'\n\n");
        printf("                BIG HEDGE PATCHER\n");
        printf("     CREATED BY ASENTIENTHEDGEHOG & MINHTON\n\n");
        printf("                SPECIAL THANKS TO\n");
        printf("BarryKN, ASentientBot, BenSova, jackluke, and many others.\n\n\n\n");
        
        // Remove caches
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/automator_app.txt" isDirectory:nil]) [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/automator_app.txt" error:nil];
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/automator_volume.txt" isDirectory:nil]) [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/automator_volume.txt" error:nil];
    });
    
    // Add main view to empty window
    self.hedgehogViewController = [[HedgehogViewController alloc] initWithNibName:@"HedgehogViewController" bundle:nil];
    [self.window.contentView addSubview:self.hedgehogViewController.view];
    self.hedgehogViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

- (BOOL)isPasswordCorrect:(NSString *)password {
    NSTask *whoami = [[NSTask alloc] init];
    [whoami setLaunchPath:@"/bin/bash"];
    [whoami setArguments:@[@"-c", [NSString stringWithFormat:@"echo \"%@\" | sudo -S whoami", password]]];
    NSPipe *out = [NSPipe pipe];
    [whoami setStandardOutput:out];
    [whoami setStandardError:out];
    
    NSFileHandle *file;
    file = [out fileHandleForReading];
    
    [whoami performSelectorInBackground:@selector(launch) withObject:nil];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    if ([output rangeOfString:@"root"].location == NSNotFound && [output rangeOfString:@"Password:"].location != NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

- (IBAction)openPostInstall:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] launchApplication:[[NSBundle mainBundle] pathForResource:@"PostAutomator" ofType:@"app"]];
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)panic:(NSMenuItem *)sender {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Big Hedge Patcher wants to kernel panic your Mac."];
    [alert setInformativeText:@"Enter your administrator password to allow this."];
    [alert addButtonWithTitle:@"Restart"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:@""];
    [alert setAccessoryView:input];
    
    // Check if the password entered is correct
    BOOL isRoot = NO;
    NSString *password;
    
    while (isRoot == NO) {
        NSInteger button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            password = [input stringValue];
            isRoot = [self isPasswordCorrect:password];
        } else if (button == NSAlertSecondButtonReturn) {
            return;
        }
    }
    
    NSTask *kp = [[NSTask alloc] init];
    [kp setLaunchPath:@"/bin/bash"];
    [kp setArguments:@[@"-c", [NSString stringWithFormat:@"echo \"%@\" | sudo -S dtrace -w -n \"BEGIN{ panic();}\"", password]]];
    [kp performSelectorInBackground:@selector(launch) withObject:nil];
}

- (IBAction)restart:(NSMenuItem *)sender {
    NSAppleScript *restart = [[NSAppleScript alloc] initWithSource:@"Tell application \"Finder\" to restart"];
    [restart executeAndReturnError:nil];
}

- (IBAction)report:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/moosethegoose2213/big-hedge/issues"]];
}

- (IBAction)sourceCode:(NSMenuItem *)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/moosethegoose2213/big-hedge"]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
