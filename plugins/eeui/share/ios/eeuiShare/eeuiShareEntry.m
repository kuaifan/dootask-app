//
//  eeuiShareEntry.m
//  Pods
//

#import "eeuiShareEntry.h"
#import "eeuiShareWebModule.h"
#import "WeexInitManager.h"
#import <WebKit/WKWebView.h>
#import <eeui/eeuiNewPageManager.h>

WEEX_PLUGIN_INIT(eeuiShareEntry)
@implementation eeuiShareEntry

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
    NSString *absoulteString = url.absoluteString;
    if ([absoulteString containsString:@"dootask://"]) {
        absoulteString = [absoulteString stringByReplacingOccurrencesOfString:@"dootask://" withString:@""];
        NSDictionary *params = @{
            @"messageType":@"link",
            @"jumpUrl": absoulteString
        };
        
        [[eeuiNewPageManager sharedIntstance] postMessage:params];
    }
    
}

//捕捉握手
- (void) handleOpenURL:(NSURL *)url
{

}

//webView初始化
- (void) setJSCallModule:(JSCallCommon *)callCommon webView:(WKWebView*)webView
{
    [callCommon setJSCallAssign:webView name:@"eeuiShare" bridge:[[eeuiShareWebModule alloc] init]];
}

@end
