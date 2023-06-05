//
//  eeuiNotificationsEntry.m
//  Pods
//

#import "eeuiNotificationsEntry.h"
#import "WeexInitManager.h"
#import "eeuiNewPageManager.h"

WEEX_PLUGIN_INIT(eeuiNotificationsEntry)
@implementation eeuiNotificationsEntry

//启动成功
- (void) didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
}

//注册推送成功调用
- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    
}

// 注册推送失败调用
- (void) didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    
}

//iOS10以下使用这两个方法接收通知
- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    
}

//iOS10新增：处理前台收到通知的代理方法
- (void) willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0))
{
    // NSDictionary *userInfo = notification.request.content.userInfo;
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于前台时的远程推送接受
    } else {
        //应用处于前台时的本地推送接受
    }
    //当应用处于前台时提示设置，需要哪个可以设置哪一个
    completionHandler(UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionAlert);
}

//iOS10新增：处理后台点击通知的代理方法
- (void) didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0))
{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于后台时的远程推送接受
    } else {
        //应用处于后台时的本地推送接受
        [[eeuiNewPageManager sharedIntstance] postMessage:@{
            @"messageType": @"notifyClick",
            @"rawData": userInfo
        }];
    }
}

//捕捉回调
- (void) openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    
}

//捕捉握手
- (void) handleOpenURL:(NSURL *)url
{

}

//webView初始化
- (void) setJSCallModule:(JSCallCommon *)callCommon webView:(WKWebView*)webView
{

}

@end
