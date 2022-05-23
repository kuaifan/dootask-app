//
//  deviceInfoEntry.m
//  Pods
//

#import "deviceInfoEntry.h"
#import "WeexInitManager.h"
#import <WebKit/WKWebView.h>

WEEX_PLUGIN_INIT(deviceInfoEntry)
@implementation deviceInfoEntry

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
    
}

//iOS10新增：处理后台点击通知的代理方法
- (void) didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0))
{
    
}

//捕捉回调
- (void) openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    
}

//webView初始化
- (void) setJSCallModule:(JSCallCommon *)callCommon webView:(WKWebView*)webView
{
    
}

@end
