//
//  AppBattery.m
//
//  Created by EEUI 19/06/14.
//  Copyright © 2019 All rights reserved.
//

#import "AppBattery.h"
#import <UIKit/UIKit.h>

@implementation AppBattery
+ (id)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}


- (void)status:(AppCallback)callback{
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    BOOL charging = NO;
    //huoqu电池的状态
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateUnknown:
            NSLog(@"电池的状态未知");
            break;
        case UIDeviceBatteryStateCharging:
            NSLog(@"电池正在充电");
            charging = YES;
            break;
        case UIDeviceBatteryStateUnplugged:
            NSLog(@"电池未充电");
            break;
        case UIDeviceBatteryStateFull:
            NSLog(@"电池电量充满");
            charging = YES;
            break;
        default:
            break;
    }

    //获取当前电池的电量
    NSInteger level = [[UIDevice currentDevice] batteryLevel] *100;
    callback(nil,@{@"level":@(level),@"isPlugged":@(charging)});


}
@end
