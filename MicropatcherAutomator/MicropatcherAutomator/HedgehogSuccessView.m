//
//  HedgehogSuccessView.m
//  MicropatcherAutomator
//
//  Created by Ford on 1/1/21.
//  Copyright © 2021 MinhTon. All rights reserved.
//

#import "HedgehogSuccessView.h"

@interface HedgehogSuccessView ()

@end

@implementation HedgehogSuccessView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
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

- (IBAction)restart:(NSButton *)sender {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Automator wants to restart your Mac."];
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
    
    NSTask *reboot = [[NSTask alloc] init];
    [reboot setLaunchPath:@"/bin/bash"];
    [reboot setArguments:@[@"-c", [NSString stringWithFormat:@"echo \"%@\" | sudo -S reboot", password]]];
    [reboot performSelectorInBackground:@selector(launch) withObject:nil];
}

@end
