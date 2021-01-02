//
//  HedgehogViewController.m
//  MicropatcherAutomator
//
//  Created by Ford on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogViewController.h"

@interface HedgehogViewController ()
@property (weak) IBOutlet NSImageView *bigSurImage;
@property (weak) IBOutlet NSImageView *diskImage;
@property (weak) IBOutlet NSButton *bigSurButton;
@property (weak) IBOutlet NSButton *diskButton;
@property (weak) IBOutlet NSBox *ASentientHedgehog;
@property (weak) IBOutlet NSBox *MinhTon;
@end

@implementation HedgehogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.ASentientHedgehog setHidden:YES];
    [self.MinhTon setHidden:YES];
    NSTrackingArea *bigSurTrackingArea = [[NSTrackingArea alloc] initWithRect:[self.bigSurButton bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:@{@"button": @"ASentientHedgehog"}];
    [self.bigSurButton addTrackingArea:bigSurTrackingArea];
    NSTrackingArea *diskTrackingArea = [[NSTrackingArea alloc] initWithRect:[self.diskButton bounds] options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways owner:self userInfo:@{@"button": @"MinhTon"}];
    [self.diskButton addTrackingArea:diskTrackingArea];
}

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
