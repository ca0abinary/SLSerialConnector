//
//  AppDelegate.m
//  SLSerialConnector
//
//  Created by Jonathan DeMarks on 10/10/15.
//  Copyright (c) 2015 Jonathan DeMarks. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

NSProcessInfo *highPriority;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    highPriority = [[NSProcessInfo processInfo]
                    beginActivityWithOptions:
                           (NSActivityLatencyCritical |
                            NSActivityIdleSystemSleepDisabled |
                            NSActivityAutomaticTerminationDisabled |
                            NSActivitySuddenTerminationDisabled |
                            NSActivityBackground) 
                    reason:@"Serial SL Studio Log Monnitor"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSProcessInfo processInfo] endActivity:highPriority];
}

@end
