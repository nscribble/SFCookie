# SFCookie
In-App-Access of Safari Cookies. Share Infos between apps of different vendors.

SFCookie access Safari cookies via `SafariServices`, specifically `SFSafariViewController`. You can get/set/delete cookies stored in the Safari.app, and therefore it enables us to share infos(e.g., a device-identifier) with other apps(even of different vendors).

## Installation

### CocoaPods

```ruby
pod "SFCookie"
```

### Manually

1. Download all files in `SFCookie` subdir
2. Add the source files("UIApplication+SafariCookie.{h,m}") to your project
3. Add `SafariServices`framework to your project
4. import `UIApplication+SafariCookie.h`

## Usage

### Configuration

1. Define `YOUR_UNIQUE_APP_SCHEME`: You need to config the `URLTypes` in the info.plist, and update using 

   ```objective-c
   [UIApplication setNTL_SafariCookie_AppScheme:@"$YOUR_UNIQUE_APP_SCHEME"];
   ```

2. Define `SFC_HTML_IN_WEBSERVER`: put the 'sfc.html' onto your webserver, and update using

   ```objective-c
   [UIApplication setNTL_SafariCookie_WebURL:@"$SFC_HTML_IN_WEBSERVER"];
   ```

### Example

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //  1. Config the URLTypes In Info.plist.
    //  2. Put the `sfc.html` onto your webserver, and setup the route url here.
    [UIApplication setNTL_SafariCookie_AppScheme:@"safaricookiedemo"];
    [UIApplication setNTL_SafariCookie_WebURL:@"http://10.32.8.148/sfci.html"];
    
    [application getCookies:@[@"BYYX",@"BXXY"] complete:^(NSDictionary *nv, NSError *error) {
        NSLog(@"onGetCookie：%@",nv);
        if (nv[@"BYYX"] && nv[@"BXXY"])
        {
            [application delCookies:@[@"BYYX",@"BXXY"] complete:^(NSDictionary *nv, NSError *error) {
                NSLog(@"onDelCookie：%@",nv);
            }];
        }
    }];
    
    return YES;
}
```

That is all!

## Environment

- iOS 9+
- SafariServices.framework
- UIKit.framework