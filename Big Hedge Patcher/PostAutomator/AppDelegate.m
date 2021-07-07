//
//  AppDelegate.m
//  PostAutomator
//
//  Created by Minh on 12/29/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "AppDelegate.h"
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSPopUpButton *volumeList;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressDescription;
@property (weak) IBOutlet NSButton *refreshButton;
@property (unsafe_unretained) IBOutlet NSTextView *outputView;
@property (weak) IBOutlet NSScrollView *outputScrollView;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSImageView *bigSurImage;
@property (weak) IBOutlet NSButton *force;

@end

@implementation AppDelegate

NSString *selectedVol = nil;
NSString *password = nil;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.outputView setHidden:YES];
    [self.volumeList removeAllItems];
    [self.volumeList addItemsWithTitles:[self getAvailableVolumes]];
    [self.continueButton setEnabled:NO];
    [self.progressBar setDoubleValue:0.0];
    
    NSDictionary *supportedMacs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"OfficialSupportedMacs" ofType:@"plist"]];
    NSArray *supportedMacsList = [supportedMacs objectForKey:@"SupportedModelProperties"];
        
    // If the machine running this patcher is unsupported
    if ([supportedMacsList containsObject:[self machineModel]]) {
        NSAlert *compat = [[NSAlert alloc] init];
        [compat addButtonWithTitle:@"Return"];
        [compat setMessageText:@"This Mac is officially supported \nby macOS Big Sur."];
        [compat setInformativeText:@"This application is for unsupported Macs only."];
        [compat setAlertStyle:NSAlertStyleWarning];
        
        [compat beginSheetModalForWindow:self.window completionHandler:nil];
        
        [self.outputView setHidden:YES];
        [self.volumeList removeAllItems];
        // [self.volumeList addItemsWithTitles:[self getAvailableVolumes]];
        [self.volumeList setEnabled:NO];
        [self.force setEnabled:NO];
        [self.continueButton setEnabled:NO];
        [self.progressBar setDoubleValue:0.0];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
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
    return @"Unknown Model.";
}

-(NSArray *)getAvailableVolumes {
    NSMutableArray *availableVolumes = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:nil]];
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".DS_Store"]) {
        [availableVolumes removeObjectAtIndex:0];
    }
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".Trashes"]) {
        [availableVolumes removeObjectAtIndex:0];
    }
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".fseventsd"]) {
        [availableVolumes removeObjectAtIndex:0];
    }
    [availableVolumes insertObject:@"- Select Volume -" atIndex:0];
    return availableVolumes;
}

- (void)showAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void)showRebootAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Restart"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            return;
        } else {
            [self reboot];
        }
    }];
}

- (IBAction)refreshVolumes:(NSButton *)sender {
    [self.continueButton setEnabled:NO];
    [self.volumeList removeAllItems];
    [self.volumeList addItemsWithTitles:[self getAvailableVolumes]];
    [self.volumeList setEnabled:YES];
}

- (BOOL)isVolumeValid:(NSString *)volumeName {
    NSDictionary *osInfo = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/Volumes/%@/System/Library/CoreServices/SystemVersion.plist", volumeName]];
    NSString *osVersion = [osInfo objectForKey:@"ProductVersion"];
    if (([osVersion hasPrefix:@"11."] || [osVersion hasPrefix:@"10.16"]) && !([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Volumes/%@/Install macOS Big Sur.app", volumeName]] || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Volumes/%@/Install macOS Big Sur Beta.app", volumeName]])) {
        return YES;
    } else {
        return NO;
    }
}

- (void)reboot {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/Image Volume"]) {
        NSAppleScript *restart = [[NSAppleScript alloc] initWithSource:@"Tell application \"Finder\" to restart"];
        [restart executeAndReturnError:nil];
    } else {
        NSTask *reboot = [[NSTask alloc] init];
        [reboot setLaunchPath:@"/bin/bash"];
        [reboot setArguments:@[@"-c", @"reboot"]];
        [reboot performSelectorInBackground:@selector(launch) withObject:nil];
    }
}

- (void)startPatchingProcess:(NSString *)volumeName {
    // Start script
    NSString* script = [[NSBundle mainBundle] pathForResource:@"postautomator" ofType:@"sh"];
    
    NSTask *automator = [[NSTask alloc] init];
    [automator setLaunchPath:@"/bin/bash"];
    
    
    if (password) {
        if (self.force.state == NSOffState) [automator setArguments:@[@"-c", [NSString stringWithFormat:@"chmod +x \"%@\" && echo \"%@\" | sudo -S \"%@\" notforce \"%@\"", script, password, script, volumeName]]];
        if (self.force.state == NSOnState) [automator setArguments:@[@"-c", [NSString stringWithFormat:@"chmod +x \"%@\" && echo \"%@\" | sudo -S \"%@\" force \"%@\"", script, password, script, volumeName]]];
    } else {
        if (self.force.state == NSOffState) [automator setArguments:@[[NSString stringWithFormat:@"chmod +x \"%@\" && \"%@\" notforce \"%@\"", script, script, volumeName]]];
        if (self.force.state == NSOnState) [automator setArguments:@[[NSString stringWithFormat:@"chmod +x \"%@\" && \"%@\" force \"%@\"", script, script, volumeName]]];
    }
    
    NSPipe *out = [NSPipe pipe];
    [automator setStandardOutput:out];
    [automator setStandardError:out];
    
    __block BOOL processSuccess = YES;
    
    [[automator.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self.outputView textStorage] appendAttributedString:[[NSAttributedString alloc] initWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]]];
            [self.outputView scrollRangeToVisible:NSMakeRange([[self.outputView string] length], 0)];
            if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] rangeOfString:@"[Error]"].location == NSNotFound) {
                if (self.progressDescription.hidden) [self.progressDescription setHidden:NO];

                if ([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] rangeOfString:@"[Out]"].location != NSNotFound) {
                    [self.progressDescription setStringValue:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] substringFromIndex:5]];
                }
            } else {
                processSuccess = NO;
                [automator terminate];
                [self showAlert:@"The patching process has failed." withDescription:@"You can check for the problem in the verbose output. Try restarting your machine, or reinstalling macOS Big Sur, and try again."];
                [self.progressDescription setStringValue:@"The patching process has failed!"];
                [self.progressBar stopAnimation:self];
            }
        });
        [file waitForDataInBackgroundAndNotify];
    }];
    
    [automator setTerminationHandler:^(NSTask *task) {
        [out fileHandleForReading].readabilityHandler = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (processSuccess) {
                [self.progressBar stopAnimation:self];
                [self showRebootAlert:@"Complete!" withDescription:@"Now, press the Restart button to restart your Mac!"];
            }
        });
    }];
    
    [self.progressDescription setHidden:NO];
    [automator performSelectorInBackground:@selector(launch) withObject:nil];
    [automator waitUntilExit];
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

- (IBAction)chooseVolume:(NSPopUpButton *)sender {
    NSString *selectedVolume = [[self getAvailableVolumes] objectAtIndex:[sender indexOfSelectedItem]];
    if ([selectedVolume isEqualToString:@"- Select Volume -"]) {
        [self showAlert:@"You haven't selected a target volume to use as your bootable installer." withDescription:@"Please choose the target volume from the drop-down menu below."];
        return;
    }
    if (![self isVolumeValid:selectedVolume]) {
        [self showAlert:@"The selected volume does not contain a valid copy of macOS Big Sur." withDescription:@"Please choose another volume."];
        return;
    }
    [self showAlert:@"Awesome! You've selected your new macOS Big Sur volume!" withDescription:@"Now, press the Continue button to start installing patches."];
    [self.continueButton setEnabled:YES];
    [self.volumeList setEnabled:NO];
    selectedVol = selectedVolume;
}

- (IBAction)continuePatching:(NSButton *)sender {
    [self.volumeList setEnabled:NO];
    [self.continueButton setEnabled:NO];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Volumes/Image Volume"]) {
        // Create an alert to ask for password input
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"PostAutomator wants to start the patching process."];
        [alert setInformativeText:@"Enter your administrator password to allow this."];
        [alert addButtonWithTitle:@"Authorize"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setAlertStyle:NSAlertStyleWarning];
        
        NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [input setStringValue:@""];
        [alert setAccessoryView:input];
        
        // Check if the password entered is correct
        BOOL isRoot = NO;
        
        while (isRoot == NO) {
            NSInteger button = [alert runModal];
            if (button == NSAlertFirstButtonReturn) {
                password = [input stringValue];
                isRoot = [self isPasswordCorrect:password];
            } else if (button == NSAlertSecondButtonReturn) {
                [self.continueButton setEnabled:YES];
                return;
            }
        }
        
        [self.progressBar setIndeterminate:YES];
        [self.progressBar startAnimation:self];
        [self.outputView setHidden:NO];
        [self.bigSurImage setHidden:YES];
        [self startPatchingProcess:selectedVol];
    } else {
        [self.progressBar setIndeterminate:YES];
        [self.progressBar startAnimation:self];
        [self.outputView setHidden:NO];
        [self.bigSurImage setHidden:YES];
        [self startPatchingProcess:selectedVol];
    }
}

@end
