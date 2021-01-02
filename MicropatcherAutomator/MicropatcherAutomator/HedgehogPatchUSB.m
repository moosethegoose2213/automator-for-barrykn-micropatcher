//
//  HedgehogPatchUSB.m
//  MicropatcherAutomator
//
//  Created by Ford on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogPatchUSB.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include "HedgehogSuccessView.h"
#import <QuartzCore/QuartzCore.h>

@interface HedgehogPatchUSB ()
@property (nonatomic,strong) IBOutlet HedgehogSuccessView *hedgehogSuccessView;
@property (unsafe_unretained) IBOutlet NSTextView *outputView;
@property (weak) IBOutlet NSTextField *modelString;
@property (weak) IBOutlet NSTextField *osString;
@property (weak) IBOutlet NSTextField *targetVolume;
@property (weak) IBOutlet NSTextField *installPath;
@property (weak) IBOutlet NSPathControl *targetVolumePath;
@property (weak) IBOutlet NSPathControl *installerPathView;
@property (weak) IBOutlet NSTextField *progressDescription;
@property (weak) IBOutlet NSProgressIndicator *patcherProgress;
@property (weak) IBOutlet NSBox *infoBoxView;
@property (weak) IBOutlet NSButton *hideVerboseButton;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *backButton;
@property (weak) IBOutlet NSButton *showVerboseButton;
@end

@implementation HedgehogPatchUSB

NSTimer *timer;
int remainingSeconds;

- (CATransition *)continueAnimation {
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionPush];
    [transition setSubtype:kCATransitionFromRight];
    return transition;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.modelString setStringValue:[NSString stringWithFormat:@"%@", [self machineModel]]];
    [self.osString setStringValue:[NSString stringWithFormat:@"%@", [[[NSProcessInfo processInfo] operatingSystemVersionString] substringFromIndex:8]]];
    [self.targetVolumePath setURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Volumes/%@", [self readDataFromFile:@"/tmp/automator_volume.txt"]] isDirectory:NO]];
    [self.installerPathView setURL:[NSURL fileURLWithPath:[self readDataFromFile:@"/tmp/automator_app.txt"] isDirectory:NO]];
    [self.hideVerboseButton setHidden:YES];
    [self.outputView setHidden:YES];
    [self.progressDescription setHidden:YES];
    [self.showVerboseButton setEnabled:NO];
}

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

- (void)scrollLogToBottom {
    BOOL scroll = (NSMaxY(self.outputView.visibleRect) == NSMaxY(self.outputView.bounds));
    if (scroll) [self.outputView scrollRangeToVisible: NSMakeRange(self.outputView.string.length, 0)];
}

- (void)showPatchingErrorAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
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

- (NSString *)readDataFromFile:(NSString *)path {
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding];
}

-(void)prepareToStart {
    remainingSeconds--;
    if (self.continueButton.enabled) [self.continueButton setEnabled:NO];
    if (self.backButton.enabled) [self.backButton setEnabled:NO];
    [self.progressDescription setHidden:NO];
    [self.progressDescription setStringValue:[NSString stringWithFormat:@"Automator will automatically start in %ld seconds.", (long)remainingSeconds]];
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
    [alert setMessageText:@"Automator wants to start the patching process."];
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
    [automator setArguments:@[@"-c", [NSString stringWithFormat:@"echo \"%@\" | sudo -S \"%@\"", password, script]]];
    NSPipe *out = [NSPipe pipe];
    [automator setStandardOutput:out];
    [automator setStandardError:out];
    
    __block BOOL processSuccess = YES;
    
    [[automator.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self.outputView textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
            [self.outputView scrollRangeToVisible:NSMakeRange([[self.outputView string] length], 0)];
            NSString *processData = [self readDataFromFile:@"/tmp/automator_progress.txt"];
            if ([processData rangeOfString:@"[Error]"].location == NSNotFound) {
                if (self.progressDescription.hidden) [self.progressDescription setHidden:NO];
                [self.progressDescription setStringValue:processData];
                [self.patcherProgress setDoubleValue:[[self readDataFromFile:@"/tmp/automator_int.txt"] doubleValue]];
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
        [automator.standardOutput fileHandleForReading].readabilityHandler = nil;
        [automator.standardError fileHandleForReading].readabilityHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_log.txt" contents:nil attributes:nil];
            [[[self.outputView textStorage] string] writeToFile:@"/tmp/automator_log.txt" atomically:YES];
            if (processSuccess) [self success];
        });
    }];
    
    // do in background
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

- (IBAction)showVerbose:(NSButton *)sender {
    [self.hideVerboseButton setHidden:NO];
    [self.outputView setHidden:NO];
    [self.infoBoxView setHidden:YES];
}

- (IBAction)hideVerbose:(NSButton *)sender {
    [self.hideVerboseButton setHidden:YES];
    [self.outputView setHidden:YES];
    [self.infoBoxView setHidden:NO];
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
