//
//  HedgehogPatchUSB.m
//  Big Hedge
//
//  Created by Minh on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogPatchUSB.h"
#include "HedgehogSuccessView.h"
#include "HedgehogChooseVolume.h"

#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <QuartzCore/QuartzCore.h>

@interface HedgehogPatchUSB ()
@property (nonatomic,strong) IBOutlet HedgehogSuccessView *hedgehogSuccessView;
@property (nonatomic,strong) IBOutlet HedgehogChooseVolume *hedgehogChooseVolume;

@property (weak) IBOutlet NSTextField *modelString;
@property (weak) IBOutlet NSTextField *osString;
@property (weak) IBOutlet NSTextField *targetVolume;
@property (weak) IBOutlet NSTextField *installPath;
@property (weak) IBOutlet NSPathControl *targetVolumePath;
@property (weak) IBOutlet NSPathControl *installerPathView;
@property (weak) IBOutlet NSTextField *progressDescription;
@property (weak) IBOutlet NSProgressIndicator *patcherProgress;
@property (weak) IBOutlet NSBox *infoBoxView;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *backButton;
@property (weak) IBOutlet NSButton *showVerboseButton;
@property (weak) IBOutlet NSTextField *userVerbose;
@end

@implementation HedgehogPatchUSB

NSTimer *timer;
int remainingSeconds;
NSTextView *outputView;
NSScrollView *outputScrollView;

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
    
    [self.modelString setStringValue:[self machineModel]];
    [self.osString setStringValue:[self currentOSInfo]];
    [self.targetVolumePath setURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Volumes/%@", [self readDataFromFile:@"/tmp/automator_volume.txt"]] isDirectory:NO]];
    [self.installerPathView setURL:[NSURL fileURLWithPath:[self readDataFromFile:@"/tmp/automator_app.txt"] isDirectory:NO]];
    [self.progressDescription setHidden:YES];
    [self.userVerbose setHidden:YES];
    
    outputScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 570, 250)];
    NSSize outputContentSize = [outputScrollView contentSize];
    
    [outputScrollView setBorderType:NSNoBorder];
    [outputScrollView setHasVerticalScroller:YES];
    [outputScrollView setHasHorizontalScroller:NO];
    
    outputView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, outputContentSize.width, outputContentSize.height)];
    [outputView setEditable:NO];
    [outputView setBackgroundColor:[NSColor whiteColor]];
    
    [outputScrollView setDocumentView:outputView];
}

-(void)viewDidAppear {
    [super viewDidAppear];
    NSDictionary *supportedMacs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"OfficialSupportedMacs" ofType:@"plist"]];
    NSArray *supportedMacsList = [supportedMacs objectForKey:@"SupportedModelProperties"];
        
    // If the machine running this patcher is unsupported
    if ([supportedMacsList containsObject:[self machineModel]]) {
        NSAlert *compat = [[NSAlert alloc] init];
        [compat addButtonWithTitle:@"Continue"];
        [compat setMessageText:@"This Mac is officially supported \nby macOS Big Sur."];
        [compat setInformativeText:@"You can still use this patcher to create a bootable installer for use on unsupported Macs."];
        [compat setAlertStyle:NSWarningAlertStyle];
        
        [compat beginSheetModalForWindow:self.view.window completionHandler:nil];
    }
}

#pragma mark - Functions

- (NSString *)machineModel {
    size_t len = 0;
    sysctlbyname("hw.model", NULL, &len, NULL, 0);
    if (len) {
        char *model = malloc(len * sizeof(char));
        sysctlbyname("hw.model", model, &len, NULL, 0);
        NSString *model_ns = [NSString stringWithUTF8String:model];
        free(model);
        return model_ns;
    }
    return @"Unknown Model";
}

- (NSString *)currentOSInfo {
    NSDictionary *osInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *osVersion = [osInfo objectForKey:@"ProductVersion"];
    NSString *osBuild = [osInfo objectForKey:@"ProductBuildVersion"];
    return [NSString stringWithFormat:@"%@ (%@)", osVersion, osBuild];
}

- (void)showPatchingErrorAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (NSString *)readDataFromFile:(NSString *)path {
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
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

-(void)prepareToStart {
    remainingSeconds--;
    if (self.continueButton.enabled) [self.continueButton setEnabled:NO];
    if (self.backButton.enabled) [self.backButton setEnabled:NO];
    [self.progressDescription setHidden:NO];
    [self.progressDescription setStringValue:[NSString stringWithFormat:@"Big Hedge Patcher will automatically start in %ld seconds.", (long)remainingSeconds]];
    if (remainingSeconds < 1) {
        [timer invalidate];
        [self.progressDescription setStringValue:@"Starting Helper..."];
        [self.showVerboseButton setEnabled:YES];
        [self startPatchingProcess];
    }
}

- (void)startPatchingProcess {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Big Hedge Patcher wants to start the patching process."];
    [alert setInformativeText:@"Enter your administrator password to allow this."];
    [alert addButtonWithTitle:@"Authorize"];
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
    
    // Start script
    NSString* script = [[NSBundle mainBundle] pathForResource:@"automator" ofType:@"sh"];
    
    // Ha! Who needs STPrivilegedTask? Not me! [I spent almost a day trying to find a solution for this -_-]
    NSTask *automator = [[NSTask alloc] init];
    [automator setLaunchPath:@"/bin/bash"];
    [automator setArguments:@[@"-c", [NSString stringWithFormat:@"chmod +x \"%@\" && echo \"%@\" | sudo -S \"%@\"", script, password, script]]];
    NSPipe *out = [NSPipe pipe];
    [automator setStandardOutput:out];
    [automator setStandardError:out];
    
    __block BOOL processSuccess = YES;
    
    [[automator.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[outputView textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
            [outputView scrollRangeToVisible:NSMakeRange([[outputView string] length], 0)];
            if (self.userVerbose.hidden) [self.userVerbose setHidden:NO];
            [self.userVerbose setStringValue:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            NSString *processData = [self readDataFromFile:@"/tmp/.automator_progress.txt"];
            if ([processData rangeOfString:@"[Error]"].location == NSNotFound) {
                if (self.progressDescription.hidden) [self.progressDescription setHidden:NO];
                [self.progressDescription setStringValue:processData];
                [self.patcherProgress setDoubleValue:[[self readDataFromFile:@"/tmp/.automator_int.txt"] doubleValue]];
            } else {
                processSuccess = NO;
                [automator terminate];
                [self showPatchingErrorAlert:@"The patching process has failed." withDescription:@"You can check for the problem in the verbose output. Try quitting the app, re-format your volume, and try again."];
                [self.progressDescription setStringValue:@"The patching process has failed!"];
                [self.patcherProgress setDoubleValue:0.0];
            }
        });
        [file waitForDataInBackgroundAndNotify];
    }];
    
    [automator setTerminationHandler:^(NSTask *task) {
        [out fileHandleForReading].readabilityHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Save log to file
            [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_log.txt" contents:nil attributes:nil];
            [[[outputView textStorage] string] writeToFile:@"/tmp/automator_log.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            if (processSuccess) [self success];
        });
    }];
    
    // perform task in background
    [self.progressDescription setHidden:NO];
    [automator performSelectorInBackground:@selector(launch) withObject:nil];
    [automator waitUntilExit];
}

- (void)success {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogSuccessView = [[HedgehogSuccessView alloc] initWithNibName:@"HedgehogSuccessView" bundle:nil];
    self.hedgehogSuccessView.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogSuccessView.view];
}

#pragma mark - Buttons

- (IBAction)hedgehogPatchUSBBack:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogChooseVolume = [[HedgehogChooseVolume alloc] initWithNibName:@"HedgehogChooseVolume" bundle:nil];
    self.hedgehogChooseVolume.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogChooseVolume.view];
}

- (IBAction)showVerbose:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Verbose Output: "];
    [alert addButtonWithTitle:@"Hide"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert setAccessoryView:outputScrollView];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (IBAction)hedgehogStartPatching:(NSButton *)sender {
    
    NSAlert *readyOrNot = [[NSAlert alloc] init];
    [readyOrNot setMessageText:[NSString stringWithFormat:@"Are you sure you want to create a bootable installer on \"%@\"?", [self readDataFromFile:@"/tmp/automator_volume.txt"]]];
    [readyOrNot setInformativeText:@"During the process, your target volume will be ERASED. Make sure that you have a backup of your files on the target volume."];
    [readyOrNot addButtonWithTitle:@"Continue"];
    [readyOrNot addButtonWithTitle:@"Cancel"];
    [readyOrNot setAlertStyle:NSWarningAlertStyle];
    [readyOrNot beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            return;
        } else {
            remainingSeconds = 6;
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(prepareToStart) userInfo:nil repeats: YES];
        }
    }];
}

@end
