//
//  AppDeviceInfo.m
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//


#import "AppDeviceInfo.h"
#import <UIKit/UIKit.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include "TargetConditionals.h"


@implementation UIDevice (ModelVersion)

- (NSString*)modelVersion
{
    size_t size;

    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString* platform = [NSString stringWithUTF8String:machine];
    free(machine);

    return platform;
}

@end


@implementation AppDeviceInfo

+ (id)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)info:(AppCallback)callback{
     NSDictionary* deviceProperties = [self deviceProperties];
    if (deviceProperties) {
        callback(nil,deviceProperties);
    }else{
        callback(@{@"error":@{}},nil);
    }
}

- (NSString*)uniqueAppInstanceIdentifier:(UIDevice*)device
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    static NSString* UUID_KEY = @"NATUUID";
    NSString* app_uuid = [userDefaults stringForKey:UUID_KEY];
    if (app_uuid == nil) {
        if ([device respondsToSelector:@selector(identifierForVendor)]) {
            app_uuid = [[device identifierForVendor] UUIDString];
        } else {
            CFUUIDRef uuid = CFUUIDCreate(NULL);
            app_uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
            CFRelease(uuid);
        }
        [userDefaults setObject:app_uuid forKey:UUID_KEY];
        [userDefaults synchronize];
    }

    return app_uuid;
}


- (NSDictionary*)deviceProperties
{
    UIDevice* device = [UIDevice currentDevice];

    return @{
             @"language": [[NSLocale preferredLanguages] objectAtIndex:0],
             @"vendor": @"Apple",
             @"model": [device modelVersion],
             @"platform": @"iOS",
             @"os": @"iOS",
             @"version": [device systemVersion],
             @"uuid": [self uniqueAppInstanceIdentifier:device],
             @"isVirtual": @([self isVirtual])
             };
}


- (BOOL)isVirtual
{
#if TARGET_OS_SIMULATOR
    return true;
#elif TARGET_IPHONE_SIMULATOR
    return true;
#else
    return false;
#endif
}


@end
