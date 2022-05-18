//
//  eeuiUmengManager.m
//

#import "eeuiUmengManager.h"
#import "eeuiNewPageManager.h"
#import <UMCommon/UMCommon.h>
#import <UMCommon/MobClick.h>
#import <UMCommonLog/UMCommonLogHeaders.h>

@implementation eeuiUmengManager

+ (eeuiUmengManager *)sharedIntstance {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)init:(NSString*)key channel:(NSString*)channel launchOptions:(NSDictionary*)launchOptions
{
    NSString * deviceID =[UMConfigure deviceIDForIntegration];
    NSLog(@"集成测试的deviceID:%@", deviceID);
    //开发者需要显式的调用此函数，日志系统才能工作
    [UMCommonLogManager setUpUMCommonLogManager];
    #if DEBUG
    [UMConfigure setLogEnabled:YES];
    #endif


    [UMConfigure initWithAppkey:key channel:channel];

    // Push's basic setting
    UMessageRegisterEntity * entity = [[UMessageRegisterEntity alloc] init];
    //type是对推送的几个参数的选择，可以选择一个或者多个。默认是三个全部打开，即：声音，弹窗，角标
    entity.types = UMessageAuthorizationOptionBadge|UMessageAuthorizationOptionAlert|UMessageAuthorizationOptionSound;
    [UMessage registerForRemoteNotificationsWithLaunchOptions:launchOptions Entity:entity completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            // 用户选择了接收Push消息
            NSLog(@"===granted=YES===");
        }else{
            // 用户拒绝接收Push消息
            NSLog(@"===granted==NO==");
        }
    }];
}

@end
