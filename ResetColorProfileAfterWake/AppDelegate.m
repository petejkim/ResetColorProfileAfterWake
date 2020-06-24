//
//  AppDelegate.m
//  ResetColorProfileAfterWake
//
//  Created by Pete Kim on 6/24/20.
//  Copyright © 2020 petejkim. All rights reserved.
//

#import "AppDelegate.h"

CGDisplayCount const maxDisplays = 8;

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
            selector: @selector(receiveWakeNote:)
            name: NSWorkspaceDidWakeNotification object: NULL];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void) receiveWakeNote: (NSNotification*) note {
    CGDisplayCount displayCount = 0;
    CGDirectDisplayID onlineDisplays[maxDisplays];
    
    CGError error = CGGetOnlineDisplayList(maxDisplays, onlineDisplays, &displayCount);
    if (error != kCGErrorSuccess) {
        return;
    }
    
    for (int i = 0; i < displayCount; i++) {
        CGDirectDisplayID displayID = onlineDisplays[i];
        
        CFUUIDRef displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID);
        CFDictionaryRef deviceInfo = ColorSyncDeviceCopyDeviceInfo(kColorSyncDisplayDeviceClass, displayUUID);
        CFDictionaryRef customProfile = (CFDictionaryRef)CFDictionaryGetValue(deviceInfo, kColorSyncCustomProfiles);
        
        if (!customProfile) {
            continue;
        }

        NSURL *profileURL = (__bridge NSURL *)CFDictionaryGetValue(customProfile, CFSTR("1"));
        
        // Temporarily set to sRGB profile
        ColorSyncDeviceSetCustomProfiles(kColorSyncDisplayDeviceClass, displayUUID, (CFDictionaryRef)@{
            (__bridge NSString *)kColorSyncDeviceDefaultProfileID: [NSURL fileURLWithPath:@"/System/Library/ColorSync/Profiles/sRGB Profile.icc"],
        });
        
        // Restore original profile
        ColorSyncDeviceSetCustomProfiles(kColorSyncDisplayDeviceClass, displayUUID, (CFDictionaryRef)@{
            (__bridge NSString *)kColorSyncDeviceDefaultProfileID: profileURL,
        });
    }
}

@end
