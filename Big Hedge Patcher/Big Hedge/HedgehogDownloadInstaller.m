//
//  HedgehogDownloadInstaller.m
//  Big Hedge
//
//  Created by Minh on 12/28/20.
//  Copyright © 2020 MinhTon. All rights reserved.
//

#import "HedgehogDownloadInstaller.h"
#include "HedgehogPatchOptions.h"
#include "HedgehogInstallerApp.h"
#import <QuartzCore/QuartzCore.h>

@interface HedgehogDownloadInstaller ()
@property (nonatomic,strong) IBOutlet HedgehogPatchOptions *hedgehogPatchOptions;
@property (nonatomic,strong) IBOutlet HedgehogInstallerApp *hedgehogInstallerApp;

@property (nonatomic, retain) NSURLResponse *downloadResponse;
@property (nonatomic, assign) long bytesReceived;
@property (weak) IBOutlet NSTextField *downloadDescription;
@property (weak) IBOutlet NSTextField *downloadSizeProgress;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSProgressIndicator *downloadProgressBar;
@property (weak) IBOutlet NSButton *backButton;
@end

@implementation HedgehogDownloadInstaller

NSString *rootPassword = nil;

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
    [self hideViews];
}

#pragma mark - Functions

- (void)hideViews {
    [self.downloadDescription setHidden:YES];
    [self.downloadSizeProgress setHidden:YES];
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

- (void)saveToFile:(NSString *)string {
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/automator_app.txt" contents:nil attributes:nil];
    [string writeToFile:@"/tmp/automator_app.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)prepareInstaller {
    dispatch_async (dispatch_get_main_queue(), ^{
        if (self.downloadDescription.hidden) [self.downloadDescription setHidden:NO];
        if (!self.downloadSizeProgress.hidden) [self.downloadSizeProgress setHidden:YES];
        if (self.continueButton.enabled) [self.continueButton setEnabled:NO];
        [self.downloadDescription setStringValue:@"Preparing Installer..."];
        [self.downloadProgressBar setIndeterminate:YES];
        [self.downloadProgressBar startAnimation:self];
    });
    
    NSTask *prepare = [[NSTask alloc] init];
    [prepare setLaunchPath:@"/bin/bash"];
    [prepare setArguments:@[@"-c", [NSString stringWithFormat:@"echo \"%@\" | sudo -S installer -pkg /tmp/InstallAssistant.pkg -target /", rootPassword]]];
    [prepare launch];
    [prepare waitUntilExit];
    
    dispatch_async (dispatch_get_main_queue(), ^{
        [self.downloadProgressBar stopAnimation:self];
        [self.downloadDescription setStringValue:@"Complete!"];
    });
    
    [self saveToFile:@"/Applications/Install macOS Big Sur.app"];
    
    dispatch_async (dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Do you want to use the downloaded Installer app to create a bootable Big Sur Installer?"];
        [alert addButtonWithTitle:@"Yes"];
        [alert addButtonWithTitle:@"No"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertSecondButtonReturn) {
                dispatch_async (dispatch_get_main_queue(), ^{
                    [self.downloadDescription setStringValue:@"Complete! The \"Install macOS Big Sur.app\" is located in your Applications folder."];
                });
                return;
            } else {
                dispatch_async (dispatch_get_main_queue(), ^{
                    [self.downloadDescription setStringValue:@"Complete! Press the Continue button to move on to the next steps."];
                    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
                    self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
                    self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
                    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
                });
            }
        }];
    });
}

- (void)showErrorAlert:(NSString *)title withDescription:(NSString *)description {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:description];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

#pragma mark - Download manager

- (void)downloadInstaller {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Big Hedge Patcher wants to download the macOS Big Sur Installer."];
    [alert setInformativeText:@"Enter your administrator password to allow this."];
    [alert addButtonWithTitle:@"Authorize"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSSecureTextField *input = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:@""];
    [alert setAccessoryView:input];
    
    // Check if the password entered is correct
    BOOL isRoot = NO;
    
    while (isRoot == NO) {
        NSInteger button = [alert runModal];
        if (button == NSAlertFirstButtonReturn) {
            rootPassword = [input stringValue];
            isRoot = [self isPasswordCorrect:rootPassword];
        } else if (button == NSAlertSecondButtonReturn) {
            return;
        }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/InstallAssistant.pkg"]) {
        [self performSelectorInBackground:@selector(prepareInstaller) withObject:nil];
        return;
    }
    
    NSURL *jsonURL = [[NSURL alloc] initWithString:@"https://bensova.github.io/patched-sur/installers/Release.json"];
    NSData *jsonData = [[NSData alloc] initWithContentsOfURL:jsonURL];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSMutableArray *URLs = [NSMutableArray array];
    for (NSDictionary *urlObject in jsonDict) {
        [URLs addObject:urlObject[@"URL"]];
    }
    NSURLRequest *requestDownload = [NSURLRequest requestWithURL:[NSURL URLWithString:[URLs lastObject]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:6000.0];
    NSURLDownload  *download = [[NSURLDownload alloc] initWithRequest:requestDownload delegate:self];
    [download setDeletesFileUponFailure:YES];
    [self.downloadDescription setStringValue:@"Downloading InstallAssistant.pkg..."];
    [self.continueButton setEnabled:NO];
    [self.backButton setEnabled:NO];
    if (!download) {
        [self.continueButton setEnabled:YES];
        [self hideViews];
        [self showErrorAlert:@"Big Hedge" withDescription:@"An unknown error occured."];
    }
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    [download setDestination:[@"/tmp" stringByAppendingPathComponent:filename] allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    [self.continueButton setEnabled:YES];
    [self hideViews];
    [self showErrorAlert:@"Big Hedge Patcher has encountered an error." withDescription:[NSString stringWithFormat:@"%@", [error localizedDescription]]];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    [self performSelectorInBackground:@selector(prepareInstaller) withObject:nil];
}

- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse {
    _downloadResponse = aDownloadResponse;
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
    self.bytesReceived = 0;
    [self setDownloadResponse:response];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned long)length {
    long long expectedLength = [[self downloadResponse] expectedContentLength];
    self.bytesReceived = self.bytesReceived + length;
    
    if (expectedLength != NSURLResponseUnknownLength) {
        if (self.downloadDescription.hidden) [self.downloadDescription setHidden:NO];
        if (self.downloadSizeProgress.hidden) [self.downloadSizeProgress setHidden:NO];
        double percentComplete = (self.bytesReceived/(float)expectedLength)*100.0;
        [self.downloadProgressBar setDoubleValue:percentComplete];
        [self.downloadSizeProgress setStringValue:[NSString stringWithFormat:@"%@ of %@", [NSByteCountFormatter stringFromByteCount:self.bytesReceived countStyle:NSByteCountFormatterCountStyleFile], [NSByteCountFormatter stringFromByteCount:expectedLength countStyle:NSByteCountFormatterCountStyleFile]]];
    } else {
        NSLog(@"Bytes received - %ld",self.bytesReceived);
    }
}

#pragma mark - Buttons

- (IBAction)hedgehogDownloadInstallerContinue:(NSButton *)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Continue"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Big Hedge"];
    [alert setInformativeText:@"Are you sure you want to download the latest macOS Big Sur Installer?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertSecondButtonReturn) {
            return;
        } else {
            [self performSelector:@selector(downloadInstaller) withObject:nil afterDelay:1.0];
        }
    }];
}

- (IBAction)returnClicked:(NSButton *)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogInstallerApp = [[HedgehogInstallerApp alloc] initWithNibName:@"HedgehogInstallerApp" bundle:nil];
    self.hedgehogInstallerApp.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogInstallerApp.view];
}

@end
