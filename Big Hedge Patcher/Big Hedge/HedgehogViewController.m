//
//  HedgehogViewController.m
//  Big Hedge
//
//  Created by Minh on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogViewController.h"
#include "HedgehogInstallerApp.h"
#import <QuartzCore/QuartzCore.h>

@interface HedgehogViewController ()
@property (nonatomic,strong) IBOutlet HedgehogInstallerApp *hedgehogInstallerApp;

@property (weak) IBOutlet NSImageView *bigSurImage;
@property (weak) IBOutlet NSImageView *diskImage;
@property (weak) IBOutlet NSButton *bigSurButton;
@property (weak) IBOutlet NSButton *diskButton;
@property (weak) IBOutlet NSBox *ASentientHedgehog;
@property (weak) IBOutlet NSBox *MinhTon;
@end

@implementation HedgehogViewController

- (CATransition *)continueAnimation {
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromRight];
    return transition;
}

- (IBAction)continueClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogInstallerApp.view];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.ASentientHedgehog setHidden:YES];
    [self.MinhTon setHidden:YES];
    NSTrackingArea *bigSurTrackingArea = [[NSTrackingArea alloc] initWithRect:[self.bigSurButton bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:@{@"button": @"ASentientHedgehog"}];
    [self.bigSurButton addTrackingArea:bigSurTrackingArea];
    NSTrackingArea *diskTrackingArea = [[NSTrackingArea alloc] initWithRect:[self.diskButton bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:@{@"button": @"MinhTon"}];
    [self.diskButton addTrackingArea:diskTrackingArea];
}

// Funny hovering effects

- (void)mouseEntered:(NSEvent *)event {
    if ([[[event trackingArea] userInfo][@"button"] isEqual:@"ASentientHedgehog"]) {
        [self.ASentientHedgehog setHidden:NO];
    }
    if ([[[event trackingArea] userInfo][@"button"] isEqual:@"MinhTon"]) {
        [self.MinhTon setHidden:NO];
    }
}

- (void)mouseExited:(NSEvent *)event{
    if ([[[event trackingArea] userInfo][@"button"] isEqual:@"ASentientHedgehog"]) {
        [self.ASentientHedgehog setHidden:YES];
    }
    if ([[[event trackingArea] userInfo][@"button"] isEqual:@"MinhTon"]) {
        [self.MinhTon setHidden:YES];
    }
}

@end
