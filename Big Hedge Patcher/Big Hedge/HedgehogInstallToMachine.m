//
//  HedgehogInstallToMachine.m
//  Big Hedge
//
//  Created by Minh on 1/6/21.
//  Copyright © 2021 MinhTon. All rights reserved.
//

#import "HedgehogInstallToMachine.h"
#include "HedgehogPatchOptions.h"
#include "HedgehogToMachineSuccess.h"

#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <Metal/Metal.h>


@interface HedgehogInstallToMachine ()
@property (weak) IBOutlet NSTextField *progressDescription;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSButton *continueButton;
@property (weak) IBOutlet NSButton *returnButton;

@property (weak) IBOutlet NSTextField *currentModel;
@property (weak) IBOutlet NSTextField *currentIdentifier;
@property (weak) IBOutlet NSTextField *currentMacOS;
@property (weak) IBOutlet NSTextField *currentProcessor;
@property (weak) IBOutlet NSTextField *currentGraphics;
@property (weak) IBOutlet NSPathControl *installerPath;


@property (nonatomic,strong) IBOutlet HedgehogPatchOptions *hedgehogPatchOptions;
@property (nonatomic,strong) IBOutlet HedgehogToMachineSuccess *hedgehogSuccessView;
@end

@implementation HedgehogInstallToMachine

NSTimer *timer;
int remainingSeconds;

NSString *checks;

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
    [self.progressDescription setHidden:YES];
    [self.continueButton setEnabled:NO];
    [self.returnButton setEnabled:NO];
    
    self.currentModel.stringValue = [self machineReadableModel];
    self.currentIdentifier.stringValue = [self machineModel];
    self.currentMacOS.stringValue = [self currentOSInfo];
    self.currentProcessor.stringValue = [self machineProcessor];
    
    if ([self metalCapable] == 1) {
        self.currentGraphics.stringValue = [NSString stringWithFormat:@"%@ ⚠️", [self machineGraphics]];
    } else {
        self.currentGraphics.stringValue = [self machineGraphics];
    }
    [self.installerPath setURL:[NSURL fileURLWithPath:[self readDataFromFile:@"/tmp/automator_app.txt"] isDirectory:NO]];
    
}

-(void)viewDidAppear {
    [super viewDidAppear];
    
    NSAlert *progress = [[NSAlert alloc] init];
    [progress setMessageText:@"Checking for issues..."];
    [progress setAlertStyle:NSWarningAlertStyle];
    [progress addButtonWithTitle:@"Cancel"];
    
    // Hide the buttons
    NSButton *button = [[progress buttons] objectAtIndex:0];
    [button setHidden:YES];
    
    NSProgressIndicator *alertbar = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 300, 25)];
    alertbar.style = NSProgressIndicatorBarStyle;
    alertbar.indeterminate = YES;
    [alertbar startAnimation:self];
    
    [progress setAccessoryView:alertbar];
    
    [progress beginSheetModalForWindow:self.view.window completionHandler:nil];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", @"csrutil status && fdesetup status"];
    NSPipe *output = [NSPipe pipe];
    NSFileHandle *file = output.fileHandleForReading;
    task.standardOutput = output;
    [task performSelectorInBackground:@selector(launch) withObject:nil];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    checks = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    
    [alertbar stopAnimation:self];
    [NSApp endSheet:progress.window];
    
    NSDictionary *supportedMacs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"OfficialSupportedMacs" ofType:@"plist"]];
    NSArray *supportedMacsList = [supportedMacs objectForKey:@"SupportedModelProperties"];
        
    // If the machine running this patcher is unsupported
    if (![supportedMacsList containsObject:[self machineModel]]) {
        
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 500, 60)];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setAccessoryView:view];
        
        if ([checks rangeOfString:@"disable"].location == NSNotFound || [checks rangeOfString:@"Off"].location == NSNotFound) {
            [alert setMessageText:@"Big Hedge Patcher has found some problems with your Mac."];
            [alert setInformativeText:@"To continue, please resolve these following issues:"];
            [alert addButtonWithTitle:@"Go Back"];
        } else if ([checks rangeOfString:@"disable"].location != NSNotFound & [checks rangeOfString:@"Off"].location != NSNotFound && [self metalCapable] == 1) {
            [alert setMessageText:@"Big Hedge Patcher has found some problems with your Mac."];
            [alert setInformativeText:@"Your Mac will not have graphics acceleration on macOS Big Sur.\nmacOS Big Sur will be unusable on this machine."];
            [alert addButtonWithTitle:@"Continue"];
        } else if ([checks rangeOfString:@"disable"].location != NSNotFound && [checks rangeOfString:@"Off"].location != NSNotFound && [self metalCapable] == 0) {
            [alert setMessageText:@"No problems detected."];
            [alert setInformativeText:@"Your Mac is fully capable of running macOS Big Sur."];
            [alert addButtonWithTitle:@"Continue"];
        }
        
        NSTextField *sip = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 40, 500, 20)];
        sip.editable = NO;
        sip.selectable = NO;
        sip.bezeled = NO;
        sip.drawsBackground = NO;
        
        if ([checks rangeOfString:@"disable"].location == NSNotFound) {
            sip.stringValue = @"❌ System Integrity Protection (SIP) is ENABLED. Please DISABLED SIP.";
        } else {
            sip.stringValue = @"✅ SIP is DISABLED.";
        }
        
        NSTextField *fv = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 20, 500, 20)];
        fv.editable = NO;
        fv.selectable = NO;
        fv.bezeled = NO;
        fv.drawsBackground = NO;
        
        if ([checks rangeOfString:@"Off"].location == NSNotFound) {
            fv.stringValue = @"❌ FileVault is ENABLED. Please DISABLED FileVault.";
        } else {
            fv.stringValue = @"✅ FileVault is DISABLED.";
        }
        
        NSTextField *gfx = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 500, 20)];
        gfx.editable = NO;
        gfx.selectable = NO;
        gfx.bezeled = NO;
        gfx.drawsBackground = NO;
        
        if ([self metalCapable] == 1) {
            gfx.stringValue = @"⚠️ No Graphics Acceleration. Slow performance expected on macOS Big Sur.";
        } else {
            gfx.stringValue = @"✅ Full Graphics Acceleration.";
        }
        
        [view addSubview:sip];
        [view addSubview:fv];
        [view addSubview:gfx];
        
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if ([checks rangeOfString:@"disable"].location == NSNotFound || [checks rangeOfString:@"Off"].location == NSNotFound) {
                [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
                self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
                self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
                [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
            } else {
                [self.continueButton setEnabled:YES];
                [self.returnButton setEnabled:YES];
            }
        }];
    } else {
        NSAlert *compat = [[NSAlert alloc] init];
        [compat addButtonWithTitle:@"Go Back"];
        [compat setMessageText:@"This Mac is officially supported \nby macOS Big Sur."];
        [compat setInformativeText:@"\"Install to This Machine\" is designed to \nrun on unsupported Macs only."];
        [compat setAlertStyle:NSWarningAlertStyle];
        
        [compat beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
            self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
            self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
            [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
        }];
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
    return @"Unknown Model.";
}

- (NSString *)currentOSInfo {
    NSDictionary *osInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *osVersion = [osInfo objectForKey:@"ProductVersion"];
    NSString *osBuild = [osInfo objectForKey:@"ProductBuildVersion"];
    return [NSString stringWithFormat:@"%@ (%@)", osVersion, osBuild];
}

- (NSString *)machineReadableModel {
    NSURL *modeldata = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.apple.SystemProfiler.plist"]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[modeldata path]]) return @"Unknown Model.";
    NSData *data = [NSData dataWithContentsOfURL:modeldata options:0 error:nil];
    if (!data) return @"Unknown Model.";
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];
    if (!dictionary) return @"Unknown Model.";
    NSArray *array = [dictionary[@"CPU Names"] allValues];
    if (!array) return @"Unknown Model.";
    if ([array objectAtIndex:0]) {
        return [array objectAtIndex:0];
    } else {
        return @"Unknown Model.";
    }
}

- (NSString *)machineProcessor {
    size_t len = 0;
    sysctlbyname("machdep.cpu.brand_string", NULL, &len, NULL, 0);
    if (len) {
        char *cpu = malloc(len * sizeof(char));
        sysctlbyname("machdep.cpu.brand_string", cpu, &len, NULL, 0);
        NSString *cpu_ns = [NSString stringWithUTF8String:cpu];
        free(cpu);
        return cpu_ns;
    }
    return @"Unknown Processor.";
}

- (NSString *)machineGraphics {
    CFMutableDictionaryRef matchDict = IOServiceMatching("IOPCIDevice");
    io_iterator_t iterator;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault,matchDict, &iterator) == kIOReturnSuccess) {
        io_registry_entry_t regEntry;
        while ((regEntry = IOIteratorNext(iterator))) {
            CFMutableDictionaryRef serviceDictionary;
            if (IORegistryEntryCreateCFProperties(regEntry, &serviceDictionary, kCFAllocatorDefault, kNilOptions) != kIOReturnSuccess) {
                IOObjectRelease(regEntry);
                continue;
            }
            const void *GPUModel = CFDictionaryGetValue(serviceDictionary, @"model");
            if (GPUModel != nil) {
                if (CFGetTypeID(GPUModel) == CFDataGetTypeID()) {
                    NSString *modelName = [[NSString alloc] initWithData:
                                           (__bridge NSData *)GPUModel encoding:NSASCIIStringEncoding];
                    return modelName;
                }
            }
            CFRelease(serviceDictionary);
            IOObjectRelease(regEntry);
        }
        IOObjectRelease(iterator);
    }
    return @"Unknown Graphics Card.";
}

- (int)metalCapable {
    NSArray<id<MTLDevice>> *devices = MTLCopyAllDevices();
    
    if (devices.count > 0) return 0;
    return 1;
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

-(void)startToInstall {
    // Create an alert to ask for password input
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Big Hedge Patcher wants to run some helper tools."];
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
    
    [self.progressDescription setHidden:NO];
    [self.progressBar setIndeterminate:YES];
    [self.progressBar startAnimation:self];
    
    [self.progressDescription setStringValue:@"Bypassing Installer Compatibility Check..."];
    
    NSString* script = [[NSBundle mainBundle] pathForResource:@"installtomachine" ofType:@"sh"];
    
    NSTask *hax = [[NSTask alloc] init];
    [hax setLaunchPath:@"/bin/bash"];
    [hax setArguments:@[@"-c", [NSString stringWithFormat:@"chmod +x \"%@\" && \"%@\" \"%@\"", script, script, password]]];
    
    [hax performSelectorInBackground:@selector(launch) withObject:nil];
    
    [hax setTerminationHandler:^(NSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self success];
        });
    }];
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
        [self startToInstall];
    }
}

- (void)success {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self continueAnimation] forKey:@"subviews"]];
    self.hedgehogSuccessView = [[HedgehogToMachineSuccess alloc] initWithNibName:@"HedgehogToMachineSuccess" bundle:nil];
    self.hedgehogSuccessView.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogSuccessView.view];
}

#pragma mark - Buttons

- (IBAction)continueClicked:(NSButton *)sender {
    NSAlert *readyOrNot = [[NSAlert alloc] init];
    [readyOrNot setMessageText:@"This method is not recommended to install macOS Big Sur on your unsupported Mac."];
    [readyOrNot setInformativeText:@"It is more recommend to use a USB to patch, as this method is more likely to fail when applying post-install patches. \n\nIf you cannot use \"Create Bootable Installer\" feature, please upgrade to a newer OS (10.13 or later).\n\nCONTINUE AT YOUR OWN RISK. PLEASE REMEMBER TO KEEP A BACKUP OF YOUR FILES."];
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

- (IBAction)backClicked:(id)sender {
    [self.view.window.contentView setAnimations:[NSDictionary dictionaryWithObject:[self returnAnimation] forKey:@"subviews"]];
    self.hedgehogPatchOptions = [[HedgehogPatchOptions alloc] initWithNibName:@"HedgehogPatchOptions" bundle:nil];
    self.hedgehogPatchOptions.view.frame = ((NSView*)self.view.window.contentView).bounds;
    [[self.view.window.contentView animator] replaceSubview:self.view with:self.hedgehogPatchOptions.view];
}

@end
