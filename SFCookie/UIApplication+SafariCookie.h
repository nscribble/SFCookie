//
//  UIApplication+SafariCookie.h
//  SFCookieDemo
//
//  Created by jason on 17/2/16.
//  Copyright © 2017年 almost. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^NTLSafariCookieCompletion)(NSDictionary *nv, NSError *error);

@interface UIApplication (SafariCookie)

/**
 AppScheme configuration，Please Define the Unique AppScheme(And MAKE SURE the URLTypes is configured in the Info_Plist). Default is 'safaricookie', but YOU'D BETTER CHOOSE A UNIQUE APP_SCHEME.
 @note if you reuse the scheme, just ignore this url pattern:(actually you won't get callbacks on your AppDelegate `openURL`-like handlers)
 $appScheme://safaricookie/$theAction?$xxxKey=$yyyValue
 */
+ (void)setNTL_SafariCookie_AppScheme:(NSString *)appScheme;


/**
 the location of the `sfc.html` on the webserver
 */
+ (void)setNTL_SafariCookie_WebURL:(NSString *)webUrl;

/**
 GET Cookies
 
 @param names Names of Cookie
 @param completion Callback on completion(on MainQueue)
 */
- (void)getCookies:(NSArray<NSString *> *)names complete:(NTLSafariCookieCompletion)completion;

/**
 DEL Cookies
 
 @param names Names of Cookie
 @param completion Callback on completion(on MainQueue), nv contains `key`，the deleted names joined by `,`
 */
- (void)delCookies:(NSArray<NSString *> *)names complete:(NTLSafariCookieCompletion)completion;


/**
 SET Cookies
 
 @param nameValues Names-Values of Cookie, `&` is NOT allowed in Name-Values
 @param completion Callback on completion
 */
- (void)setCookies:(NSDictionary *)nameValues complete:(NTLSafariCookieCompletion)completion;

@end
