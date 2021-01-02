//
//  AppDelegate.m
//  PostAutomator
//
//  Created by Ford on 12/29/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "AppDelegate.h"

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
@end

@implementation AppDelegate

NSString *selectedVol = nil;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.outputView setHidden:YES];
    [self.volumeList removeAllItems];
    [self.volumeList addItemsWithTitles:[self getAvailableVolumes]];
    [self.continueButton setEnabled:NO];
    [self.progressBar setDoubleValue:0.0];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
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
    if ([osVersion hasPrefix:@"11."] && !([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Volumes/%@/Install macOS Big Sur.app", volumeName]] || [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Volumes/%@/Install macOS Big Sur Beta.app", volumeName]])) {
        return YES;
    } else {
        return NO;
    }
}

- (void)reboot {
    NSTask *reboot = [[NSTask alloc] init];
    [reboot setLaunchPath:@"/bin/bash"];
    [reboot setArguments:@[@"-c", @"reboot"]];
    [reboot performSelectorInBackground:@selector(launch) withObject:nil];
}

- (void)startPatchingProcess:(NSString *)volumeName {
    // Start script
    NSString* script = [[NSBundle mainBundle] pathForResource:@"postautomator" ofType:@"sh"];
    
    NSTask *automator = [[NSTask alloc] init];
    [automator setLaunchPath:@"/bin/bash"];
    [automator setArguments:@[script, volumeName]];
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
        [automator.standardOutput fileHandleForReading].readabilityHandler = nil;
        [automator.standardError fileHandleForReading].readabilityHandler = nil;
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
    [self.progressBar setIndeterminate:YES];
    [self.progressBar startAnimation:self];
    [self.outputView setHidden:NO];
    [self.bigSurImage setHidden:YES];
    [self startPatchingProcess:selectedVol];
}

@end
