//
//  HedgehogCreateDiskImage.m
//  Big Hedge
//
//  Created by Minh on 1/8/21.
//  Copyright © 2021 MinhTon. All rights reserved.
//

#import "HedgehogCreateDiskImage.h"
#include "HedgehogPatchOptions.h"
#include "HedgehogDiskImageSuccess.h"

#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface HedgehogCreateDiskImage ()
@property (weak) IBOutlet NSButton *dmgButton;
@property (weak) IBOutlet NSButton *isoButton;
@property (weak) IBOutlet NSTextField *currentModel;
@property (weak) IBOutlet NSTextField *currentOS;
@property (weak) IBOutlet NSTextField *howItWorks;
@property (weak) IBOutlet NSTextField *progressDescription;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *userVerbose;
@property (weak) IBOutlet NSButton *returnButton;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *showVerboseButton;

@property (nonatomic,strong) IBOutlet HedgehogPatchOptions *hedgehogPatchOptions;
@property (nonatomic,strong) IBOutlet HedgehogDiskImageSuccess *hedgehogSuccessView;
@end

@implementation HedgehogCreateDiskImage

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
    
    [self.continueButton setEnabled:NO];
    [self.currentModel setStringValue:[self machineModel]];
    [self.currentOS setStringValue:[self currentOSInfo]];
    [self.progressDescription setHidden:YES];
    [self.userVerbose setHidden:YES];
    [self.continueButton setEnabled:YES];
        
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/diskimage_mode.txt" contents:nil attributes:nil];
    [@"2" writeToFile:@"/tmp/diskimage_mode.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [self.howItWorks setStringValue:@"This type of disk image can be restored to an external disk using Disk Utility (macOS) or TransMac (Windows)."];
    
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
        [compat setInformativeText:@"You can still use this patcher to create a bootable disk image for use on unsupported Macs."];
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
    if (self.returnButton.enabled) [self.returnButton setEnabled:NO];
    [self.progressDescription setHidden:NO];
    [self.progressDescription setStringValue:[NSString stringWithFormat:@"Big Hedge Patcher will automatically start in %ld seconds.", (long)remainingSeconds]];
    if (remainingSeconds < 1) {
        [timer invalidate];
        [self.progressDescription setStringValue:@"Starting Helper..."];
        [self.showVerboseButton setEnabled:YES];
        [self startPatchingProcess];
    }
}

-(void)startPatchingProcess {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Big Hedge Patcher wants to start the disk image creation process."];
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
    NSString* script = [[NSBundle mainBundle] pathForResource:@"diskimage" ofType:@"sh"];
    
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
                [self.progressBar setDoubleValue:[[self readDataFromFile:@"/tmp/.automator_int.txt"] doubleValue]];
            } else {
                processSuccess = NO;
                [automator terminate];
                [self showPatchingErrorAlert:@"Failed to create an installer disk image." withDescription:@"You can check for the problem in the verbose output. Please restart your machine before trying again."];
                [self.progressDescription setStringValue:@"Failed to create an installer disk image."];
                [self.progressBar setDoubleValue:0.0];
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
    self.hedgehogSuccessView = [[HedgehogDiskImageSuccess alloc] initWithNibName:@"HedgehogDiskImageSuccess" bundle:nil];
    self.hedgehogSuccessView.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogSuccessView.view];
}

#pragma mark - Buttons

- (IBAction)showVerbose:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Verbose Output: "];
    [alert addButtonWithTitle:@"Hide"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert setAccessoryView:outputScrollView];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (IBAction)continueClicked:(NSButton *)sender {
    NSSavePanel *save = [[NSSavePanel alloc] init];
    [save setTitle:@"Save DMG Image"];
    [save setPrompt:@"Save"];
    if ([[self readDataFromFile:@"/tmp/diskimage_mode.txt"] isEqualToString:@"2"]) {
        [save setAllowedFileTypes:@[@"dmg"]];
    } else {
        [save setAllowedFileTypes:@[@"iso"]];
    }
    [save setNameFieldStringValue:@"ASentientInstaller"];
    [save beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            [[NSFileManager defaultManager] createFileAtPath:@"/tmp/disk_image_path.txt" contents:nil attributes:nil];
            [[[save URL] path] writeToFile:@"/tmp/disk_image_path.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            remainingSeconds = 6;
            timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(prepareToStart) userInfo:nil repeats: YES];
        }
    }];
}

- (IBAction)backClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
    self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
}

- (IBAction)dmgClicked:(NSButton *)sender {
    [self.isoButton setState:NSOffState];
    [self.howItWorks setStringValue:@"This type of disk image can be restored to an external disk using Disk Utility (macOS) or TransMac (Windows)."];
    
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/diskimage_mode.txt" contents:nil attributes:nil];
    [@"2" writeToFile:@"/tmp/diskimage_mode.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (IBAction)isoClicked:(NSButton *)sender {
    [self.dmgButton setState:NSOffState];
    [self.howItWorks setStringValue:@"This type of disk image can be restored to an external disk using Disk Utility (macOS) or BackToMac (Linux)."];
    
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/diskimage_mode.txt" contents:nil attributes:nil];
    [@"1" writeToFile:@"/tmp/diskimage_mode.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
