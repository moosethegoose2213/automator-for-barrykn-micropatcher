//
//  HedgehogInstallerApp.m
//  Big Hedge
//
//  Created by Minh on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogInstallerApp.h"
#include "HedgehogDownloadInstaller.h"
#include "HedgehogPatchOptions.h"
#include "HedgehogViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface HedgehogInstallerApp ()

@property (nonatomic,strong) IBOutlet HedgehogViewController *hedgehogViewController;
@property (nonatomic,strong) IBOutlet HedgehogPatchOptions *hedgehogPatchOptions;

@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *browseInstallerButton;
@property (weak) IBOutlet NSButton *downloadInstallerButton;
@property (weak) IBOutlet NSPathControl *installerPath;
@property (weak) IBOutlet NSBox *installerPathBox;
@property (nonatomic,strong) IBOutlet HedgehogDownloadInstaller *hedgehogDownloadInstaller;
@end

@implementation HedgehogInstallerApp

#pragma mark - Animations

- (CATransition *)continueAnimation {
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromRight];
    return transition;
}

- (CATransition *)returnAnimation {
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromLeft];
    return transition;
}

#pragma mark - Set up view

- (void)viewDidLoad {
    [super viewDidLoad];
    [self disableContinueButton:YES browseButton:NO downloadButton:NO];
    [self.installerPath setHidden:YES];
}

#pragma mark - Functions

- (void)disableContinueButton:(BOOL)continueButton browseButton:(BOOL)browseButton downloadButton:(BOOL)downloadButton {
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
    NSDictionary *installerInfo = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist", path]];
    NSString *installerIdentifier = [installerInfo objectForKey:@"CFBundleIdentifier"];
    if ([installerIdentifier isEqual: @"com.apple.InstallAssistant.macOSBigSur"] || [installerIdentifier isEqual: @"com.apple.InstallAssistant.Seed.macOS1016Seed1"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)saveToFile:(NSString *)string {
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_app.txt" contents:nil attributes:nil];
    [string writeToFile:@"/tmp/automator_app.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - Buttons

- (IBAction)downloadInstaller:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogDownloadInstaller = [[HedgehogDownloadInstaller alloc] initWithNibName:@"HedgehogDownloadInstaller" bundle:nil];
    self.hedgehogDownloadInstaller.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogDownloadInstaller.view];
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
                [self showAlert:@"The selected installer app is not a valid macOS Big Sur Installer." withDescription:@"Please try selecting the installer app again, or press the Download button if you don't have it."];
            }
        }
    }];
}

- (IBAction)continueClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
    self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
}

- (IBAction)returnClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogViewController = [[HedgehogViewController alloc] initWithNibName:@"HedgehogViewController" bundle:nil];
    self.hedgehogViewController.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogViewController.view];
}

@end
