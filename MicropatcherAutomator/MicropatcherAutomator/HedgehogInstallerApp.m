//
//  HedgehogInstallerApp.m
//  MicropatcherAutomator
//
//  Created by Ford on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogInstallerApp.h"

@interface HedgehogInstallerApp ()
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *browseInstallerButton;
@property (weak) IBOutlet NSButton *downloadInstallerButton;
@property (weak) IBOutlet NSPathControl *installerPath;
@property (weak) IBOutlet NSBox *installerPathBox;
@end

@implementation HedgehogInstallerApp

- (void)viewDidLoad {
    [super viewDidLoad];
    [self disableContinueButton:YES browseButton:NO downloadButton:NO];
    [self.installerPath setHidden:YES];
}

- (void)disableContinueButton:(BOOL)continueButton browseButton:(BOOL)browseButton downloadButton:(BOOL)downloadButton{
    [self.continueButton setEnabled:!continueButton];
    [self.browseInstallerButton setEnabled:!browseButton];
    [self.downloadInstallerButton setEnabled:!downloadButton];
}

- (void)showAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (BOOL)isInstallerValid:(NSString *)path {
    NSString *sharedSupportPath = [NSString stringWithFormat:@"%@/Contents/SharedSupport/SharedSupport.dmg", path];
    NSString *clipath = [NSString stringWithFormat:@"%@/Contents/Resources/createinstallmedia", path];
    NSDictionary *installerInfo = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist", path]];
    NSString *installerIdentifier = [installerInfo objectForKey:@"CFBundleIdentifier"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sharedSupportPath isDirectory:nil] && [[NSFileManager defaultManager] fileExistsAtPath:clipath isDirectory:nil] && [installerIdentifier isEqual: @"com.apple.InstallAssistant.macOSBigSur"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)saveToFile:(NSString *)string {
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_app.txt" contents:nil attributes:nil];
    [string writeToFile:@"/tmp/automator_app.txt" atomically:YES];
}

- (IBAction)browseInstaller:(NSButton *)sender {
    __block NSString *path = nil;
    
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    openPanel.title = @"Select a macOS Big Sur Installer app...";
    openPanel.showsResizeIndicator = YES;
    openPanel.showsHiddenFiles = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canCreateDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.allowedFileTypes = @[@"app"];
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *selection = openPanel.URLs[0];
            path = [[selection path] stringByResolvingSymlinksInPath];
            if ([self isInstallerValid:path]) {
                [self.installerPath setHidden:NO];
                [self.installerPath setURL:[NSURL fileURLWithPath:path isDirectory:NO]];
                [self saveToFile:path];
                [self showAlert:@"Great! You've selected a macOS Big Sur Installer app!" withDescription:@"Now, press the Continue button to move on to the next steps."];
                [self disableContinueButton:NO browseButton:YES downloadButton:YES];
            } else {
                [self showAlert:@"Invalid Installer." withDescription:@"Try again."];
            }
        }
    }];
}

@end
