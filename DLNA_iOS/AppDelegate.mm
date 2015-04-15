//
//  AppDelegate.m
//  DLNA_iOS
//
//  Created by ennrd on 4/15/15.
//  Copyright (c) 2015 ws. All rights reserved.
//

#import "AppDelegate.h"
#import <Platinum/Platinum.h>
#import "UPnPEngine.h"
#import "Util.h"
#import "Macro.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark - upnp methods

- (void)initUpnpServer {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // **This is quite useless for no document content manage support from UI
    [[UPnPEngine getEngine] intendStartLocalFileServerWithRootPath:[[Util sharedInstance] getDocumentPath] serverName:@"iOSDMS_File"];
    // **
    
    [[UPnPEngine getEngine] intendStartItunesMusicServerWithServerName:@"iOSDMS_Music"];
    [[UPnPEngine getEngine] intendStartIOSPhotoServerWithServerName:@"iOSDMS_Photo"];
    
    if (![[UPnPEngine getEngine] startUPnP]) {
        NSLog(@"Error starting up DMS servers");
    }
}


- (void)destroyUpnpServer {
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UPnPEngine getEngine] stopUPnP];
}



#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self destroyUpnpServer];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationFlag_StatusChanged object:nil];

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self initUpnpServer];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationFlag_StatusChanged object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {

}

@end
