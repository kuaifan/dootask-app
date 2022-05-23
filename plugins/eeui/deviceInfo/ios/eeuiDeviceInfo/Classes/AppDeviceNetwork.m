//
//  AppDeviceNetwork.m
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//
#import "AppDeviceNetwork.h"
#import "Reachability.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>


@implementation AppDeviceNetwork
+ (id)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)status:(AppCallback)callback{
    NSString *type = [self networkType];
    callback(nil,@{@"type":type});
}

- (NSString *)networkType{
    Reachability *reachability   = [Reachability reachabilityWithHostName:@"www.apple.com"];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];

    switch (networkStatus) {
        case NotReachable:
            return @"none";

        case ReachableViaWWAN:
        {
            BOOL isConnectionRequired = [reachability connectionRequired];
            if (isConnectionRequired) {
                return @"none";
            } else {
                if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
                    CTTelephonyNetworkInfo *telephonyInfo = [CTTelephonyNetworkInfo new];
                    if ([telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                        return @"2g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyEdge]) {
                        return @"2g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyWCDMA]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyHSDPA]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyHSUPA]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyeHRPD]) {
                        return @"3g";
                    } else if ([telephonyInfo.currentRadioAccessTechnology  isEqualToString:CTRadioAccessTechnologyLTE]) {
                        return @"4g";
                    }
                }
                return @"generic";
            }
        }
        case ReachableViaWiFi:
            return @"wifi";

        default:
            return @"unknown";
    }

}

@end
