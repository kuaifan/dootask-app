//
//  eeuiPicture.m
//  Pods
//
//  Created by 高一 on 2019/3/4.
//

#import "eeuiPicture.h"
#import "eeuiPictureBridge.h"
#import "WeexInitManager.h"

WEEX_PLUGIN_INIT(eeuiPicture)
@implementation eeuiPicture

+ (instancetype) sharedManager {
    static dispatch_once_t onceToken;
    static eeuiPicture *instance;
    dispatch_once(&onceToken, ^{
        instance = [[eeuiPicture alloc] init];
    });
    return instance;
}

- (void) setJSCallModule:(JSCallCommon *)callCommon webView:(WKWebView*)webView
{
    [callCommon setJSCallAssign:webView name:@"eeuiPicture" bridge:[[eeuiPictureBridge alloc] init]];
}

@end
