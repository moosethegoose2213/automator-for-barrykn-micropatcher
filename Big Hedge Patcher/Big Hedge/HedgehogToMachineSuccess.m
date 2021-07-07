//
//  HedgehogToMachineSuccess.m
//  Big Hedge
//
//  Created by Ford on 2/16/21.
//  Copyright © 2021 MinhTon. All rights reserved.
//

#import "HedgehogToMachineSuccess.h"

@interface HedgehogToMachineSuccess ()

@end

@implementation HedgehogToMachineSuccess

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self showSpecialWindow];
}

#pragma mark - Functions

-(void)showSpecialWindow {
    NSRect frame = NSMakeRect(NSWidth([[NSScreen mainScreen] frame])/2 - 100, NSHeight([[NSScreen mainScreen] frame])/2 - 250, 200, 200);
    NSWindow* window  = [[NSWindow alloc] initWithContentRect:frame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window setBackgroundColor:[NSColor clearColor]];
    window.level = NSFloatingWindowLevel;
    [window setOpaque:NO];
    [window setHasShadow:NO];
    
    NSVisualEffectView *visualEffect = [[NSVisualEffectView alloc] initWithFrame:[[window screen] frame]];
    visualEffect.translatesAutoresizingMaskIntoConstraints = NO;
    visualEffect.state = NSVisualEffectStateActive;
    visualEffect.material = NSVisualEffectMaterialPopover;
    visualEffect.wantsLayer = YES;
    visualEffect.layer.cornerRadius = 18.0;
    visualEffect.hidden = NO;
    visualEffect.alphaValue = 1;
    
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 13, 200, 30)];
    label.editable = NO;
    label.selectable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.stringValue = @"Operation Finished";
    label.hidden = NO;
    label.alphaValue = 1;
    label.alignment = NSTextAlignmentCenter;
    label.font = [NSFont systemFontOfSize:18];
    label.textColor = [NSColor labelColor];
    
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(25, 40, 150, 150)];
    NSImage *image = [NSImage imageNamed:@"success.png"];
    image.template = YES;
    imageView.image = image;
    imageView.imageScaling = NSImageScaleProportionallyDown;
    
    [window.contentView addSubview:visualEffect];
    [visualEffect addSubview:label];
    [visualEffect addSubview:imageView];
    visualEffect.animator.alphaValue = 0;
    window.contentView.wantsLayer = YES;
    window.contentView.layer.cornerRadius = 16.0;
    window.contentView.hidden = NO;
    window.hasShadow = NO;
    
    [window makeKeyAndOrderFront:self];
    visualEffect.animator.alphaValue = 1;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:2.0f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                context.duration = 0.2;
                visualEffect.animator.alphaValue = 0;
            } completionHandler:^{
                [window orderOut:nil];
            }];
        });
    });
}

- (NSString *)readDataFromFile:(NSString *)path {
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
}

- (IBAction)readyToInstall:(NSButton *)sender {
    [[NSWorkspace sharedWorkspace] launchApplication:[self readDataFromFile:@"/tmp/automator_app.txt"]];
}

@end
