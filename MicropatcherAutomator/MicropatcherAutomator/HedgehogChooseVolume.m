//
//  HedgehogChooseVolume.m
//  MicropatcherAutomator
//
//  Created by Ford on 12/27/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogChooseVolume.h"

@interface HedgehogChooseVolume ()
@property (weak) IBOutlet NSPopUpButton *volumeList;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSPathControl *volumePath;
@end

@implementation HedgehogChooseVolume

-(NSArray *)getAvailableVolumes {
    NSMutableArray *availableVolumes = [[NSMutableArray alloc] initWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Volumes" error:nil]];
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".DS_Store"]) {
        [availableVolumes removeObjectAtIndex:0];
    }
    if ([[availableVolumes objectAtIndex:0] isEqualToString:@".Trashes"]) {
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
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (void)saveToFile:(NSString *)string {
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_volume.txt" contents:nil attributes:nil];
    [string writeToFile:@"/tmp/automator_volume.txt" atomically:YES];
}

- (BOOL)checkTargetVolumeSize:(NSString *)volumePath {
    const double MIN_SIZE = 15032377839;
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:volumePath error:nil];
    double volumeSize = [[attr objectForKey:NSFileSystemSize] doubleValue];
    if (volumeSize < MIN_SIZE) {
        return NO;
    }
    return YES;
}

- (BOOL)isVolumeCurrentBootDisk:(NSString *)volumeName {
    NSTask *bootDisk = [[NSTask alloc] init];
    [bootDisk setLaunchPath:@"/bin/bash"];
    [bootDisk setArguments:@[@"-c", @"diskutil info / | grep \"Volume Name\""]];
    NSPipe *out = [NSPipe pipe];
    [bootDisk setStandardOutput:out];
    [bootDisk setStandardError:out];
    
    NSFileHandle *file;
    file = [out fileHandleForReading];
    
    [bootDisk performSelectorInBackground:@selector(launch) withObject:nil];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    if ([output rangeOfString:volumeName].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isVolumeHFS:(NSString *)volumeName {
    NSTask *bootDisk = [[NSTask alloc] init];
    [bootDisk setLaunchPath:@"/bin/bash"];
    [bootDisk setArguments:@[@"-c", [NSString stringWithFormat:@"diskutil info \"%@\" | grep \"Name (User Visible)\"", [NSString stringWithFormat:@"/Volumes/%@", volumeName]]]];
    NSPipe *out = [NSPipe pipe];
    [bootDisk setStandardOutput:out];
    [bootDisk setStandardError:out];
    
    NSFileHandle *file;
    file = [out fileHandleForReading];
    
    [bootDisk performSelectorInBackground:@selector(launch) withObject:nil];
    
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    if ([output rangeOfString:@"Mac OS Extended (Journaled)"].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

- (void)initUI {
    [self.volumeList removeAllItems];
    [self.volumeList addItemsWithTitles:[self getAvailableVolumes]];
    [self.continueButton setEnabled:NO];
    [self.volumeList setEnabled:YES];
}

- (IBAction)refreshVolumes:(NSButton *)sender {
    [self initUI];
}

- (IBAction)chooseVolume:(NSPopUpButton *)sender {
    [self.continueButton setEnabled:NO];
    NSString *selectedVolume = [[self getAvailableVolumes] objectAtIndex:[sender indexOfSelectedItem]];
    if ([selectedVolume isEqualToString:@"- Select Volume -"]) {
        [self showAlert:@"You haven't selected a target volume to use as your bootable installer." withDescription:@"Please choose the target volume from the drop-down menu below."];
        return;
    }
    if ([self checkTargetVolumeSize:[NSString stringWithFormat:@"/Volumes/%@", selectedVolume]] == NO) {
        [self showAlert:@"The volume that you have selected is too small." withDescription:@"Please choose a volume that has at least 14GB in size."];
        return;
    }
    if ([self isVolumeCurrentBootDisk:selectedVolume]) {
        [self showAlert:@"The selected volume is your Mac startup disk, and data loss will occur if you continue." withDescription:@"Please choose another volume."];
        return;
    }
    if (![self isVolumeHFS:selectedVolume]) {
        [self showAlert:@"The selected volume is NOT formatted as \"macOS Extended (Journaled)\", which does not work with the automator." withDescription:@"Please format the volume as \"macOS Extended (Journaled)\" and press the Refresh button."];
        return;
    }
    [self showAlert:@"Awesome! You've selected a target volume as your bootable installer!" withDescription:@"Now, press the Continue button to move on to the next steps."];
    [self.volumeList setEnabled:NO];
    [self.volumePath setHidden:NO];
    [self.volumePath setURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"/Volumes/%@", selectedVolume] isDirectory:NO]];
    [self saveToFile:selectedVolume];
    [self.continueButton setEnabled:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    [self.volumePath setHidden:YES];
}

@end
