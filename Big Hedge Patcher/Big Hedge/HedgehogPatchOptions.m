//
//  HedgehogPatchOptions.m
//  Big Hedge
//
//  Created by Minh on 1/5/21.
//  Copyright © 2021 MinhTon. All rights reserved.
//

#import "HedgehogPatchOptions.h"
#import "HedgehogChooseVolume.h"
#import "HedgehogCreateDiskImage.h"
#import "HedgehogInstallerApp.h"
#import "HedgehogInstallToMachine.h"
#import <QuartzCore/QuartzCore.h>

@interface HedgehogPatchOptions ()
// View controllers
@property (nonatomic,strong) IBOutlet HedgehogChooseVolume *hedgehogChooseVolume;
@property (nonatomic,strong) IBOutlet HedgehogInstallerApp *hedgehogInstallerApp;
@property (nonatomic,strong) IBOutlet HedgehogCreateDiskImage *hedgehogCreateDiskImage;
@property (nonatomic,strong) IBOutlet HedgehogInstallToMachine *hedgehogInstallToMachine;
@property (weak) IBOutlet NSButton *createusb;
@property (weak) IBOutlet NSButton *createimage;

@end

@implementation HedgehogPatchOptions

#pragma mark - Set up view

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    NSOperatingSystemVersion mininumOS = { .majorVersion = 10, .minorVersion = 13, .patchVersion = 0 };
    
    if (![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:mininumOS]) {
        [self.createusb setEnabled:NO];
        [self.createimage setEnabled:NO];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"\"Create Bootable Installer\" & \"Create Disk Image\" options are not available."];
        [alert setInformativeText:[NSString stringWithFormat:@"The current version of macOS on this machine is not capable of reading or writing to APFS (Apple File System) volumes.\n\nYou have macOS %@. Please update to macOS High Sierra 10.13 or newer to use these options.", [[[NSProcessInfo.processInfo operatingSystemVersionString] componentsSeparatedByString:@" "] objectAtIndex:1]]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        return;
    }
}

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

#pragma mark - Buttons

- (IBAction)createBootableInstaller:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogChooseVolume = [[HedgehogChooseVolume alloc] initWithNibName:@"HedgehogChooseVolume" bundle:nil];
    self.hedgehogChooseVolume.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogChooseVolume.view];
}

- (IBAction)createDiskImage:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogCreateDiskImage = [[HedgehogCreateDiskImage alloc] initWithNibName:@"HedgehogCreateDiskImage" bundle:nil];
    self.hedgehogCreateDiskImage.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogCreateDiskImage.view];
}

- (IBAction)installToMachine:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogInstallToMachine = [[HedgehogInstallToMachine alloc] initWithNibName:@"HedgehogInstallToMachine" bundle:nil];
    self.hedgehogInstallToMachine.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogInstallToMachine.view];
}

- (IBAction)returnClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogInstallerApp.view];
}

@end
