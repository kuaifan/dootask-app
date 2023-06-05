//
//  eeuiUmengEntry.m
//

#import "eeuiUmengEntry.h"
#import "WeexInitManager.h"
#import "eeuiUmengManager.h"
#import "eeuiNewPageManager.h"
#import "Config.h"

WEEX_PLUGIN_INIT(eeuiUmengEntry)

@implementation eeuiUmengEntry

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static eeuiUmengEntry *instance;
    dispatch_once(&onceToken, ^{
        instance = [[eeuiUmengEntry alloc] init];
    });
    return instance;
}

//初始化友盟
- (void)didFinishLaunchingWithOptions:(NSMutableDictionary *)lanchOption {
    NSMutableDictionary *umeng = [[Config getObject:@"umeng"] objectForKey:@"ios"];
    NSString *enabled = [NSString stringWithFormat:@"%@", umeng[@"enabled"]];
    //
    if ([enabled containsString:@"1"] || [enabled containsString:@"true"]) {
        NSString *appKey = [NSString stringWithFormat:@"%@", umeng[@"appKey"]];
        NSString *channel = [NSString stringWithFormat:@"%@", umeng[@"channel"]];
        [[eeuiUmengManager sharedIntstance] init:appKey channel:channel launchOptions:lanchOption];
    }
}

//注册成功
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (![deviceToken isKindOfClass:[NSData class]]) return;
    const unsigned* tokenBytes = (const unsigned*)[deviceToken bytes];
    NSString *token =[NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                        ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                        ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                        ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    [eeuiUmengManager sharedIntstance].token = @{@"status": @"success", @"msg": @"", @"token": token};
    [[eeuiNewPageManager sharedIntstance] postMessage:@{@"messageType": @"umengToken", @"token": token}];
}

//注册失败
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [eeuiUmengManager sharedIntstance].token = @{@"status": @"error", @"msg": [error localizedDescription], @"token": @""};
}

//iOS10以下使用这两个方法接收通知，
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [UMessage setAutoAlert:NO];
    if ([[[UIDevice currentDevice] systemVersion] intValue] < 10) {
        [UMessage didReceiveRemoteNotification:userInfo];
    }
    [self pushInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

//iOS10新增：处理前台收到通知的代理方法
- (void)willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)) {
    NSDictionary *userInfo = notification.request.content.userInfo;
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于前台时的远程推送接受
        //关闭U-Push自带的弹出框
        [UMessage setAutoAlert:NO];
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    } else {
        //应用处于前台时的本地推送接受
    }
    //当应用处于前台时提示设置，需要哪个可以设置哪一个
    completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
}


//iOS10新增：处理后台点击通知的代理方法
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)) {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于后台时的远程推送接受
        [self pushInfo:userInfo];
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    } else {
        //应用处于后台时的本地推送接受
    }
}

- (void)pushInfo:(NSDictionary *)data {
    if (!data) {
        return;
    }
    NSString *msgid = data[@"d"] ? data[@"d"] : @"";
    //
    NSDictionary *alert = data[@"aps"][@"alert"];
    if (![alert isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSMutableDictionary *extra = [[NSMutableDictionary alloc] init];
    for (NSString *key in data) {
        if (![key isEqualToString:@"aps"] &&
                ![key isEqualToString:@"d"] &&
                ![key isEqualToString:@"p"]) {
            [extra setObject:data[key] forKey:key];
        }
    }
    NSDictionary *result = @{
            @"messageType": @"notificationClick",
            @"status": @"click",
            @"msgid": msgid,
            @"title": alert[@"title"] ? alert[@"title"] : @"",
            @"subtitle": alert[@"subtitle"] ? alert[@"subtitle"] : @"",
            @"text": alert[@"body"] ? alert[@"body"] : @"",
            @"extra": extra,
            @"rawData": data};
    [[eeuiNewPageManager sharedIntstance] postMessage:result];
}

@end
