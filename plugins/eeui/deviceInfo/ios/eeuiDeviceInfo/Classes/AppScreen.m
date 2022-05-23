//
//  AppScreen.m
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//

#import "AppScreen.h"
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>
@implementation AppScreen

+ (id)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)info:(AppCallback)callback{
    NSDictionary *diction = @{@"height":@([UIScreen mainScreen].bounds.size.height),@"width":@([UIScreen mainScreen].bounds.size.width),@"scale":@([UIScreen mainScreen].scale),@"dpiX":@([self getdpi]),@"dpiY":@([self getdpi])};
    callback(nil,diction);
}

- (void)getBrightness:(AppCallback)callback{
    callback(nil,@{@"brightness":@([UIScreen mainScreen].brightness)});
}


- (void)setBrightness:(NSNumber *)brightness :(AppCallback)callback{
    if (brightness && [brightness isKindOfClass:[NSNumber class]] && [brightness floatValue] > 0 && [brightness floatValue] <= 1) {
        [[UIScreen mainScreen] setBrightness:[brightness floatValue]];
        callback(nil,@{@"brightness":brightness});
    }else{
        callback(@{@"error":@{@"code":@11,@"msg":@""}},nil);
    }
}

- (void)getOrientation:(AppCallback)callback{
    NSString *orientation = [self getori];
    callback(nil,@{@"orientation":orientation});

}


- (NSString *)getori{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    static NSString* orientation_KEY = @"NATOrientation";
    NSString* app_orientation = [userDefaults stringForKey:orientation_KEY];

    switch (orientation) {
        case UIDeviceOrientationUnknown:
            [userDefaults setObject:@"unknown" forKey:orientation_KEY];
            return @"unknown";
            break;
        case UIDeviceOrientationPortrait:
            [userDefaults setObject:@"portrait" forKey:orientation_KEY];
            return @"portrait";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [userDefaults setObject:@"portrait-down" forKey:orientation_KEY];
            return @"portrait-down";
            break;
        case UIDeviceOrientationLandscapeLeft:
            [userDefaults setObject:@"landscape-left" forKey:orientation_KEY];
            return @"landscape-left";
            break;
        case UIDeviceOrientationLandscapeRight:
            [userDefaults setObject:@"landscape-right" forKey:orientation_KEY];
            return @"landscape-right";
            break;
        case UIDeviceOrientationFaceUp:
            if (app_orientation) {
                return app_orientation;
            }
            return @"portrait";
            break;
        case UIDeviceOrientationFaceDown:
            if (app_orientation) {
                return app_orientation;
            }
            return @"portrait";
            break;
        default:
            return @"unknown";
            break;
    }

}

- (float)getdpi{
//    float dpi = 0;
    float scale = 1;
//    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        scale = [[UIScreen mainScreen] scale];  //得到屏幕分辨率
//    }
//    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//        dpi = 132 * scale;
//    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
//        dpi = 163 * scale;
//    } else {
//        dpi = 160 * scale;
//    }
//    return dpi;

    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    if( [platform hasPrefix:@"iPhone1"] || [platform hasPrefix:@"iPhone2"] || [platform hasPrefix:@"iPhone3"])return 163.0f;
    if( [platform hasPrefix:@"iPhone4"] || [platform hasPrefix:@"iPhone5"] || [platform hasPrefix:@"iPhone6"])return 326.0f;        //    // For iPhone6+    // Added by Gerry 2014.11.22 10:12    //    // Note: iPhone6  326ppi
    if( [platform hasPrefix:@"iPhone7"]) {return 401.0f;}if([platform hasPrefix:@"iPhone"]) // catch-all for higher-end devices not yet existing
        {return 326.0f; }
    if( [platform hasPrefix:@"iPod1"]  || [platform hasPrefix:@"iPod2"]    || [platform hasPrefix:@"iPod3"])return 163.0f;
    if( [platform hasPrefix:@"iPod4"]  || [platform hasPrefix:@"iPod5"])return 326.0f;
    if( [platform hasPrefix:@"iPod"])
        {return 326.0f; }
    if( [platform hasPrefix:@"iPad1"] || [platform hasPrefix:@"iPad2"])return 132.0f;
    if( [platform hasPrefix:@"iPad3"] || [platform hasPrefix:@"iPad4"])return 264.0f;
    if( [platform hasPrefix:@"iPad"]){
            return 264.0f;
    }
    if( [platform hasPrefix:@"x86_64"]) {
        return 132.0f;
    }else{
        return 160 * scale;
    }
}
@end
