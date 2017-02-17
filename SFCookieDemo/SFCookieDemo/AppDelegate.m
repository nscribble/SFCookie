//
//  AppDelegate.m
//  SFCookieDemo
//
//  Created by jason on 17/2/16.
//  Copyright © 2017年 almost. All rights reserved.
//

#import "AppDelegate.h"
#import "UIApplication+SafariCookie.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //{ 1. Config the URLTypes In Info.plist.
    //  2. Put the `sfc.html` onto your webserver, and setup the route url here.
    [UIApplication setNTL_SafariCookie_AppScheme:@"safaricookiedemo"];
    [UIApplication setNTL_SafariCookie_WebURL:@"http://10.32.8.148/sfci.html"];
    //}
    
    [application getCookies:@[@"BYYX",@"BXXY"] complete:^(NSDictionary *nv, NSError *error) {
        NSLog(@"onGetCookie：%@",nv);
        if (!nv[@"BYYX"] && !nv[@"BXXY"]) {
            [application setCookies:@{@"BYYX":@"SXUIL+#DKD*%%@",
                                      @"BXXY":@"XESD-3dlsD=djs",
                                      } complete:^(NSDictionary *nv, NSError *error) {
                                          NSLog(@"onSetCookie：%@",nv);
                                      }];
        }
        else
        {
            [application delCookies:@[@"BYYX",@"BXXY"] complete:^(NSDictionary *nv, NSError *error) {
                NSLog(@"onDelCookie：%@",nv);
            }];
        }
    }];
    
    return YES;
}

/*
 Either of the methods below should be implemented:
 `-application:openURL:options:` OR `-application:openURL:sourceApplication:annotation:`
 */
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return YES;
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
//{
//    return YES;
//}


@end
