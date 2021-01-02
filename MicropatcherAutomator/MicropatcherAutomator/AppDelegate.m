//
//  AppDelegate.m
//  MicropatcherAutomator
//
//  Created by Ford on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "AppDelegate.h"
#include "HedgehogViewController.h"
#include "HedgehogPatchUSB.h"
#include "HedgehogInstallerApp.h"
#include "HedgehogChooseVolume.h"
#include "HedgehogDownloadInstaller.h"
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

// View controllers
@property (nonatomic,strong) IBOutlet HedgehogViewController *hedgehogViewController;
@property (nonatomic,strong) IBOutlet HedgehogInstallerApp *hedgehogInstallerApp;
@property (nonatomic,strong) IBOutlet HedgehogChooseVolume *hedgehogChooseVolume;
@property (nonatomic,strong) IBOutlet HedgehogPatchUSB *hedgehogPatchUSB;
@property (nonatomic,strong) IBOutlet HedgehogDownloadInstaller *hedgehogDownloadInstaller;

@end

@implementation AppDelegate

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

- (IBAction)hedgehogWelcomeContinue:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogViewController.view with:self.hedgehogInstallerApp.view];
}

- (IBAction)hedgehogInstallerAppContinue:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogChooseVolume = [[HedgehogChooseVolume alloc] initWithNibName:@"HedgehogChooseVolume" bundle:nil];
    self.hedgehogChooseVolume.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogInstallerApp.view with:self.hedgehogChooseVolume.view];
}

- (IBAction)hedgehogInstallerAppBack:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogViewController = [[HedgehogViewController alloc] initWithNibName:@"HedgehogViewController" bundle:nil];
    self.hedgehogViewController.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogInstallerApp.view with:self.hedgehogViewController.view];
}

- (IBAction)hedgehogChooseVolumeContinue:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogPatchUSB = [[HedgehogPatchUSB alloc] initWithNibName:@"HedgehogPatchUSB" bundle:nil];
    self.hedgehogPatchUSB.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogChooseVolume.view with:self.hedgehogPatchUSB.view];
}


- (IBAction)hedgehogChooseVolumeBack:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogChooseVolume.view with:self.hedgehogInstallerApp.view];
}

- (IBAction)hedgehogPatchUSBBack:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogChooseVolume = [[HedgehogChooseVolume alloc] initWithNibName:@"HedgehogChooseVolume" bundle:nil];
    self.hedgehogChooseVolume.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogPatchUSB.view with:self.hedgehogChooseVolume.view];
}


- (IBAction)hedgehogDownloadInstaller:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogDownloadInstaller = [[HedgehogDownloadInstaller alloc] initWithNibName:@"HedgehogDownloadInstaller" bundle:nil];
    self.hedgehogDownloadInstaller.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogInstallerApp.view with:self.hedgehogDownloadInstaller.view];
}


- (IBAction)hedgehogDownloadInstallerBack:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogDownloadInstaller.view with:self.hedgehogInstallerApp.view];
}

- (IBAction)hedgehogDownloadInstallerContinue:(NSButton *)sender {
    [self.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogChooseVolume = [[HedgehogChooseVolume alloc] initWithNibName:@"HedgehogChooseVolume" bundle:nil];
    self.hedgehogChooseVolume.view.frame = ((NSView*)self.window.contentView).bounds;
    [[self.window.contentView animator] replaceSubview:self.hedgehogDownloadInstaller.view with:self.hedgehogChooseVolume.view];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.hedgehogViewController = [[HedgehogViewController alloc] initWithNibName:@"HedgehogViewController" bundle:nil];
    [self.window.contentView addSubview:self.hedgehogViewController.view];
    self.hedgehogViewController.view.frame = ((NSView*)self.window.contentView).bounds;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/automator_app.txt" isDirectory:nil]) [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/automator_app.txt" error:nil];
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/automator_volume.txt" isDirectory:nil]) [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/automator_volume.txt" error:nil];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
