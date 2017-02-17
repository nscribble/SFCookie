//
//  UIApplication+SafariCookie.m
//  SFCookieDemo
//
//  Created by jason on 17/2/16.
//  Copyright © 2017年 almost. All rights reserved.
//

#import "UIApplication+SafariCookie.h"

#import <SafariServices/SafariServices.h>
#import <objc/runtime.h>

#define NTL_SafariCookie_AppHost  @"safaricookie"

#ifndef NTL_SafariCookie_WebURL
#define NTL_SafariCookie_WebURL     (g_NTL_SafariCookie_WebURL ?: @"http://127.0.0.1/sfc.html")
#endif

#ifndef NTL_SafariCookie_AppScheme
#define NTL_SafariCookie_AppScheme  (g_NTL_SafariCookie_AppScheme ?: @"safaricookie")
#endif

static NSString * g_NTL_SafariCookie_WebURL;
static NSString * g_NTL_SafariCookie_AppScheme;

#pragma mark - SFSafariViewController (SafariCookie)

@interface SFSafariViewController (SafariCookie)

@property (nonatomic,strong) NSString *ntl_url;

@end

const char NTL_SFSafariViewController_URL_Key;
@implementation SFSafariViewController (SafariCookie)

- (NSString *)ntl_url
{
    return objc_getAssociatedObject(self, &NTL_SFSafariViewController_URL_Key);
}

- (void)setNtl_url:(NSString *)ntl_url{
    objc_setAssociatedObject(self, &NTL_SFSafariViewController_URL_Key, ntl_url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - NSObject (SafariCookie)

@interface NSObject (SafariCookie)<SFSafariViewControllerDelegate>

+ (BOOL)ntl_swizzleMethod:(SEL)origSEL withMethod:(SEL)altSEL;

/**
 URL dispatch
 @note Should NOT call this directly
 
 @param URL the callback URL
 @return success or not
 */
- (BOOL)ntl_handleOpenURL:(NSURL *)URL;

@end

@implementation NSObject (SafariCookie)

- (BOOL)ntl_handleOpenURL:(NSURL *)URL
{
    return NO;
}

+ (BOOL)ntl_swizzleMethod:(SEL)origSEL withMethod:(SEL)altSEL
{
    Method origMethod = class_getInstanceMethod(self, origSEL);
    Method altMethod = class_getInstanceMethod(self, altSEL);
    if (!origSEL || !altSEL) {
        return NO;
    }
    
    if (!origMethod) {
        class_addMethod(self,
                        origSEL,
                        class_getMethodImplementation(self, origSEL),
                        method_getTypeEncoding(origMethod));//~
        
        origMethod = class_getInstanceMethod(self, origSEL);
    }
    if (!altMethod) {
        class_addMethod(self,
                        altSEL,
                        class_getMethodImplementation(self, altSEL),
                        method_getTypeEncoding(altMethod));
        
        altMethod = class_getInstanceMethod(self, altSEL);
    }
    method_exchangeImplementations(origMethod, altMethod);
    
    return YES;
}

-(BOOL)ntl_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    
    if ([application ntl_handleOpenURL:url]) {
        return YES;
    };
    
    return [self ntl_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)ntl_application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if ([application ntl_handleOpenURL:url]) {
        return YES;
    };
    
    return [self ntl_application:application openURL:url options:options];
}

@end

#pragma mark - UIApplication (SafariCookie)

const char UIApplication_SafariController_Map_Key;
const char UIApplication_SafariCookie_RequestBlock_Key;// 是否需要支持多个查询？

@implementation UIApplication (SafariCookie)

- (void)swizzleAppDelegateMethod
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [object_getClass(self.delegate) ntl_swizzleMethod:@selector(application:openURL:sourceApplication:annotation:) withMethod:@selector(ntl_application:openURL:sourceApplication:annotation:)];
        
        [object_getClass(self.delegate) ntl_swizzleMethod:@selector(application:openURL:options:) withMethod:@selector(ntl_application:openURL:options:)];
    });
}

+ (void)setNTL_SafariCookie_WebURL:(NSString *)webUrl
{
    if ([webUrl isKindOfClass:[NSString class]] &&
        webUrl.length > 0) {
        g_NTL_SafariCookie_WebURL = webUrl;
    }
    else
    {
        NSAssert(NO, @"setNTL_SafariCookie_WebURL: webUrl invalid");
    }
}

+ (void)setNTL_SafariCookie_AppScheme:(NSString *)appScheme
{
    if ([appScheme isKindOfClass:[NSString class]] &&
        appScheme.length > 0) {
        g_NTL_SafariCookie_AppScheme = appScheme;
    }
    else
    {
        NSAssert(NO, @"setNTL_SafariCookie_AppScheme: appScheme invalid");
    }
}

#pragma mark - Request

- (void)getCookies:(NSArray<NSString *> *)names complete:(NTLSafariCookieCompletion)completion
{
    names = [names sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    NSString *query = [names componentsJoinedByString:@","];
    NSString *url = [NSString stringWithFormat:@"%@?action=getCookie&scheme=%@&key=%@",NTL_SafariCookie_WebURL,NTL_SafariCookie_AppScheme,query];
    
    NSMutableDictionary *callbacks = [self callbacks];
    NSString *mapKey = [@"onGetCookie|" stringByAppendingString:query];
    if (url && completion) {
        callbacks[mapKey] = completion;
    }
    
    SFSafariViewController *safari = [self safariViewControllerWithUrl:url mapKey:mapKey];
    [self ntl_openSafari:safari];
}

- (void)delCookies:(NSArray<NSString *> *)names complete:(NTLSafariCookieCompletion)completion
{
    names = [names sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    NSString *query = [names componentsJoinedByString:@","];
    NSString *url = [NSString stringWithFormat:@"%@?action=delCookie&scheme=%@&key=%@",NTL_SafariCookie_WebURL,NTL_SafariCookie_AppScheme,query];
    
    NSMutableDictionary *callbacks = [self callbacks];
    NSString *mapKey = [@"onDelCookie|" stringByAppendingString:query];
    if (url && completion) {
        callbacks[mapKey] = completion;
    }
    
    SFSafariViewController *safari = [self safariViewControllerWithUrl:url mapKey:mapKey];
    [self ntl_openSafari:safari];
}

- (void)setCookies:(NSDictionary *)nameValues complete:(NTLSafariCookieCompletion)completion
{
    NSMutableString *url = [NSString stringWithFormat:@"%@?action=setCookie&scheme=%@",NTL_SafariCookie_WebURL,NTL_SafariCookie_AppScheme].mutableCopy;
    [nameValues enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [url appendFormat:@"&%@=%@",key,obj];
    }];
    
    NSArray *keys = [[nameValues allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    NSString *query = [keys componentsJoinedByString:@","];
    
    NSMutableDictionary *callbacks = [self callbacks];
    NSString *mapKey = [@"onSetCookie|" stringByAppendingString:query];
    if (url && completion) {
        callbacks[mapKey] = completion;
    }
    
    SFSafariViewController *safari = [self safariViewControllerWithUrl:url mapKey:mapKey];
    [self ntl_openSafari:safari];
}

#pragma mark - Response

- (void)dispatchSafariURL:(NSURL *)URL
{
    if (![URL.host isEqualToString:NTL_SafariCookie_AppHost]) {
        return;
    }
    
    NSMutableDictionary *queyKvs = @{}.mutableCopy;
    NSString *path;
    if ([UIDevice currentDevice].systemVersion.doubleValue >= 8.0) {
#ifdef __IPHONE_8_0
        NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:nil];
        [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {//! 修改可支持iOS7.queryItems
            if (![obj.name isEqualToString:@"action"] &&
                ![obj.name isEqualToString:@"scheme"]) {
                NSString *value = [obj.value stringByRemovingPercentEncoding];
                if (value.length) { // && ![value isEqualToString:@"null"]
                    // 为取到正确的Cookie:key及mapkey，可能返回null
                    queyKvs[obj.name] = value;
                }
            }
        }];
        path = components.path;
#endif
    }
    
    NSArray *keys = [[queyKvs allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
    
    NSString *query = [keys componentsJoinedByString:@","];
    NSString *mapKey;
    
    if ([path isEqualToString:@"/onGetCookie"]) {
        mapKey = [@"onGetCookie|" stringByAppendingString:query];
    }
    else if ([path isEqualToString:@"/onSetCookie"]){
        mapKey = [@"onSetCookie|" stringByAppendingString:query];
    }
    else if ([path isEqualToString:@"/onDelCookie"]) {
        mapKey = [@"onDelCookie|" stringByAppendingString:query];
    }
    
    if (!mapKey) {
        return;
    }
    
    NSMutableDictionary *callbacks = [self callbacks];
    NTLSafariCookieCompletion callback = callbacks[mapKey];
    
    if (!callback) {
        // incase of mismatch
        NSArray *allKeys = [[self callbacks] allKeys];
        if (allKeys.count == 1) {
            NSString *prefix = [mapKey substringToIndex:[mapKey rangeOfString:@"|"].location];
            if ([allKeys.firstObject hasPrefix:prefix]) {
                mapKey = allKeys.firstObject;
                
                callback = callbacks[mapKey];
            }
        }
    }
    
    NSDictionary *queryKvsCopy = [queyKvs copy];
    [queryKvsCopy enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        if ([value isEqualToString:@"null"])
        {
            [queyKvs removeObjectForKey:key];
        }
    }];
    
    if (callback) {
        callback(queyKvs, nil);
        [callbacks removeObjectForKey:mapKey];
    }
    SFSafariViewController *safari = [[self safariMap] objectForKey:mapKey];
    if (safari) {
        [self ntl_closeSafari:safari];
        [[self safariMap] removeObjectForKey:mapKey];
    }
}

- (BOOL)ntl_handleOpenURL:(NSURL *)URL
{
    if ([URL.scheme isEqualToString:NTL_SafariCookie_AppScheme] &&
        [URL.host isEqualToString:NTL_SafariCookie_AppHost]) {
        [self dispatchSafariURL:URL];
        return YES;
    }
    
    return NO;
}

- (void)ntl_openSafari:(SFSafariViewController *)safari
{
    UIViewController *rootViewController = [self.delegate window].rootViewController;
    
    if (!rootViewController) {
        // just delay to get the rootViewController
        [self performSelector:_cmd withObject:safari afterDelay:0.2];
        return;
    }
    
    [self swizzleAppDelegateMethod];
    
    [rootViewController addChildViewController:safari];
    safari.view.frame = rootViewController.view.bounds;
    [rootViewController.view insertSubview:safari.view atIndex:0];
    [rootViewController.view addSubview:safari.view];
    [safari didMoveToParentViewController:rootViewController];
}

- (void)ntl_closeSafari:(SFSafariViewController *)safari
{
    [safari willMoveToParentViewController:nil];
    [safari.view removeFromSuperview];
    [safari removeFromParentViewController];
}

#pragma mark - Property

- (NSMutableDictionary *)callbacks
{
    NSMutableDictionary *callbacks = objc_getAssociatedObject(self, &UIApplication_SafariCookie_RequestBlock_Key);
    if (callbacks) {
        return callbacks;
    }
    
    callbacks = [NSMutableDictionary new];
    [self setCallback:callbacks];
    return callbacks;
}

- (void)setCallback:(NSMutableDictionary *)callbacks
{
    objc_setAssociatedObject(self, &UIApplication_SafariCookie_RequestBlock_Key, callbacks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark  Safari

- (SFSafariViewController *)safariViewControllerWithUrl:(NSString *)url mapKey:(NSString *)mapKey
{
    if (!mapKey || !url) {
        return nil;
    }
    
    SFSafariViewController *safari = [[self safariMap] objectForKey:mapKey];
    if (safari) {
        return safari;
    }
    
    //url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //deprecated
    NSMutableCharacterSet *charSets = [[NSMutableCharacterSet alloc] init];
    [charSets formUnionWithCharacterSet:[NSCharacterSet URLHostAllowedCharacterSet]];
    [charSets formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
    [charSets formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [charSets formUnionWithCharacterSet:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:charSets];
    
    NSURL *referrerUrl = [NSURL URLWithString:url];
    safari = [[SFSafariViewController alloc] initWithURL:referrerUrl];
    safari.delegate = self;
    safari.view.alpha = 0.05;
    safari.ntl_url = url;
    
    [[self safariMap] setObject:safari forKey:mapKey];
    
    return safari;
}

- (NSMapTable *)safariMap
{
    NSMapTable *safariMap = objc_getAssociatedObject(self, &UIApplication_SafariController_Map_Key);
    if (safariMap) {
        return safariMap;
    }
    
    safariMap = [NSMapTable strongToStrongObjectsMapTable];//~~
    [self setSafariMap:safariMap];
    
    return safariMap;
}

- (void)setSafariMap:(NSMapTable *)safariMap
{
    objc_setAssociatedObject(self, &UIApplication_SafariController_Map_Key, safariMap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewController:(SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully
{
    ;
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    ;
}

@end
