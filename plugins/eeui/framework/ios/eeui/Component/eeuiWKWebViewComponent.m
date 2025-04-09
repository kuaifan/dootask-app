//
//  eeuiWKWebViewComponent.m
//  WeexTestDemo
//
//  Created by apple on 2018/6/5.
//  Copyright 2018年 TomQin. All rights reserved.
//

#import "eeuiWKWebViewComponent.h"
#import "DeviceUtil.h"
#import "YHWebViewProgressView.h"
#import "eeuiStorageManager.h"
#import "eeuiNewPageManager.h"
#import "JSCallCommon.h"

NSString * const WKProcessPoolDidCrashNotification = @"WKProcessPoolDidCrashNotification";

@interface _NoInputAccessoryView : NSObject
@end
@implementation _NoInputAccessoryView
- (id)inputAccessoryView {
    return nil;
}
@end

@interface eeuiWKWebView : WKWebView
@end

@implementation eeuiWKWebView


@end

@interface eeuiWKWebViewComponent() <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, assign) CGFloat webContentHeight;
@property (nonatomic, strong) WXSDKInstance *webInstance;
@property (nonatomic, assign) BOOL isShowProgress;
@property (nonatomic, assign) BOOL isAllowsInlineMediaPlayback;
@property (nonatomic, assign) BOOL isAllowFileAccess;
@property (nonatomic, assign) BOOL isScrollEnabled;
@property (nonatomic, assign) BOOL isEnableApi;
@property (nonatomic, assign) BOOL isHeightChanged;
@property (nonatomic, assign) BOOL isReceiveMessage;
@property (nonatomic, assign) BOOL isTransparency;
@property (nonatomic, assign) BOOL isHiddenDone;
@property (nonatomic, assign) BOOL isHapticBackEnabled;
@property (nonatomic, assign) BOOL isDisabledUserLongClickSelect;
@property (nonatomic, assign) BOOL isFullscreen;
@property (nonatomic, strong) JSCallCommon* JSCall;
@property (strong, nonatomic) YHWebViewProgressView *progressView;

@property (nonatomic, assign) BOOL isRemoveObserver;

@end

@implementation eeuiWKWebViewComponent

WX_EXPORT_METHOD(@selector(setContent:))
WX_EXPORT_METHOD(@selector(setUrl:))
WX_EXPORT_METHOD(@selector(setJavaScript:))
WX_EXPORT_METHOD(@selector(setProgressbarVisibility:))
WX_EXPORT_METHOD(@selector(setHapticBackEnabled:))
WX_EXPORT_METHOD(@selector(setDisabledUserLongClickSelect:))
WX_EXPORT_METHOD(@selector(setScrollEnabled:))
WX_EXPORT_METHOD(@selector(setFullscreen:))
WX_EXPORT_METHOD(@selector(canGoBack:))
WX_EXPORT_METHOD(@selector(goBack:))
WX_EXPORT_METHOD(@selector(canGoForward:))
WX_EXPORT_METHOD(@selector(goForward:))

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance
{
    self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance];
    if (self) {
        _webInstance = weexInstance;
        
        _url = @"";
        _content = @"";
        _userAgent = @"";
        _isShowProgress = YES;
        _isAllowsInlineMediaPlayback = YES;
        _isAllowFileAccess = NO;
        _isScrollEnabled = YES;
        _isEnableApi = YES;
        _isTransparency = NO;
        _isHiddenDone = NO;
        _isHapticBackEnabled = NO;
        _isDisabledUserLongClickSelect = NO;
        _isFullscreen = NO;
        _isHeightChanged = [events containsObject:@"heightChanged"];
        _isReceiveMessage = [events containsObject:@"receiveMessage"];

        for (NSString *key in styles.allKeys) {
            [self dataKey:key value:styles[key] isUpdate:NO];
        }
        for (NSString *key in attributes.allKeys) {
            [self dataKey:key value:attributes[key] isUpdate:NO];
        }
    }
    return self;
}

- (WKWebView*)loadView
{
    eeuiWKWebView *wv = nil;
    //设置userAgent
    __block NSString *originalUserAgent = nil;
    NSString *versionName = (NSString*)[[[NSBundle mainBundle] infoDictionary]  objectForKey:@"CFBundleShortVersionString"];
    NSString *systemTheme = [[eeuiNewPageManager sharedIntstance] getThemeName:_webInstance];
    if (@available(iOS 9.0, *)) {
        originalUserAgent = [NSString stringWithFormat:@";system_theme/%@;ios_kuaifan_eeui/%@", systemTheme, versionName];
        if (_userAgent.length > 0) {
            originalUserAgent = [NSString stringWithFormat:@"%@/%@", originalUserAgent, self->_userAgent];
        }
        //初始化浏览器对象
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        [configuration setApplicationNameForUserAgent: originalUserAgent];
        if (_isAllowsInlineMediaPlayback) {
            [configuration setAllowsInlineMediaPlayback:YES];
        }
        if (_isAllowFileAccess) {
            [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
        }
        WKProcessPool *processPool = [[WKProcessPool alloc] init];
        [configuration setProcessPool:processPool];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWKProcessPoolDidCrashNotification:) name:WKProcessPoolDidCrashNotification object:processPool];
        wv = [[eeuiWKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    } else {
        eeuiStorageManager *storage = [eeuiStorageManager sharedIntstance];
        originalUserAgent = [storage getCachesString:@"__system:originalUserAgent" defaultVal:@""];
        if (![originalUserAgent containsString:@";ios_kuaifan_eeui/"]) {
            __block WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            [wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                wkWebView = nil;
                if (!error) {
                    NSString *versionName = (NSString*)[[[NSBundle mainBundle] infoDictionary]  objectForKey:@"CFBundleShortVersionString"];
                    originalUserAgent = [NSString stringWithFormat:@"%@;system_theme/%@;ios_kuaifan_eeui/%@", result, systemTheme, versionName];
                    if (self->_userAgent.length > 0) {
                        originalUserAgent = [NSString stringWithFormat:@"%@/%@", originalUserAgent, self->_userAgent];
                    }
                    [storage setCachesString:@"__system:originalUserAgent" value:originalUserAgent expired:0];
                    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:originalUserAgent, @"UserAgent", nil];
                    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
                }
            }];
        }
        if (_userAgent.length > 0) {
            originalUserAgent = [NSString stringWithFormat:@"%@/%@", originalUserAgent, _userAgent];
        }
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:originalUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        //初始化浏览器对象
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        if (_isAllowsInlineMediaPlayback) {
            [configuration setAllowsInlineMediaPlayback:YES];
        }
        if (_isAllowFileAccess) {
            [configuration.preferences setValue:@YES forKey:@"allowFileAccessFromFileURLs"];
        }
        WKProcessPool *processPool = [[WKProcessPool alloc] init];
        [configuration setProcessPool:processPool];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWKProcessPoolDidCrashNotification:) name:WKProcessPoolDidCrashNotification object:processPool];
        wv = [[eeuiWKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    }
    wv.scrollView.backgroundColor = [UIColor clearColor];
#ifdef DEBUG
    if (@available(iOS 16.4, *)) {
        wv.inspectable = YES;
    } else {
        // Fallback on earlier versions
    }
#endif
    return wv;
}

// 处理通知

- (void)handleWKProcessPoolDidCrashNotification:(NSNotification *)notification {
    // 处理 GPU 进程崩溃异常
    UIAlertController * alertController = [UIAlertController
                                           alertControllerWithTitle:@"WKWebView"
                                           message: @"GPU Crash"
                                           preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
        [webView reload];
    }]];
    [[DeviceUtil getTopviewControler] presentViewController:alertController animated:YES completion:nil];
}

// 去掉 WkWebviewe Done 工具栏
- (void) hideWKWebviewKeyboardShortcutBar:(WKWebView *)webView {
    UIView *targetView;
    
    for (UIView *view in webView.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"WKContent"]) {
            targetView = view;
        }
    }
    if (!targetView) {
        return;
    }
    NSString *noInputAccessoryViewClassName = [NSString stringWithFormat:@"%@_NoInputAccessoryView", targetView.class.superclass];
    Class newClass = NSClassFromString(noInputAccessoryViewClassName);
    
    if(newClass == nil) {
        newClass = objc_allocateClassPair(targetView.class, [noInputAccessoryViewClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!newClass) {
            return;
        }
        Method method = class_getInstanceMethod([_NoInputAccessoryView class], @selector(inputAccessoryView));
        class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));
        objc_registerClassPair(newClass);
    }
    object_setClass(targetView, newClass);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;

    self.progressView = [[YHWebViewProgressView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 2)];
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
    self.progressView.hidden = !_isShowProgress;
    [self.progressView useWkWebView:webView];
    [self.view addSubview:self.progressView];

    if (_isTransparency) {
        webView.opaque = NO;
        webView.backgroundColor = [UIColor clearColor];
    }
    
    if (_isHiddenDone) {
        [self hideWKWebviewKeyboardShortcutBar: webView];
    }

    if (_isFullscreen) {
        [self setFullscreen:@YES];
    }

    webView.scrollView.scrollEnabled = _isScrollEnabled;

    webView.UIDelegate = self;
    webView.navigationDelegate  = self;

    if (self.JSCall == nil) {
        self.JSCall = [[JSCallCommon alloc] init];
    }

    if (_url.length > 0) {
        if (![_url hasPrefix:@"http://"] && ![_url hasPrefix:@"https://"]) {
            _url = [NSString stringWithFormat:@"http://%@", _url];
        }
        NSURL *url = [NSURL URLWithString:_url];
        NSURLRequest *request =[NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }

    if (_content.length > 0) {
        [self setContent:_content];
    }

    [self fireEvent:@"ready" params:nil];

    if (_isHeightChanged) {
        [webView.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    }
    [webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
}

- (void) viewWillUnload
{
    [super viewWillUnload];
    if (self.JSCall != nil) {
        [self.JSCall viewDidUnload];
        self.JSCall = nil;
    }
    [self removeObserver];
}

- (void) dealloc
{
    [self removeObserver];
}

- (void) removeObserver
{
    if (_isRemoveObserver != YES) {
        _isRemoveObserver = YES;
        eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
        if (_isHeightChanged) {
            [webView.scrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
        }
        [webView removeObserver:self forKeyPath:@"URL" context:nil];
        [webView removeObserver:self forKeyPath:@"title" context:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.progressView outWkWebView:webView];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    eeuiWKWebView *webView = (eeuiWKWebView*) self.view;
    if ([keyPath isEqualToString:@"contentSize"]) {
        CGFloat webViewHeight = webView.scrollView.contentSize.height;
        CGFloat contentHeight = 750 * 1.0 / [UIScreen mainScreen].bounds.size.width * webViewHeight;
        if (contentHeight != _webContentHeight) {
            _webContentHeight = contentHeight;
            [self fireEvent:@"heightChanged" params:@{@"height":@(contentHeight)}];
        }
    }else if ([keyPath isEqualToString:@"URL"]) {
        NSString *url = webView.URL.absoluteString;
        [self fireEvent:@"stateChanged" params:@{@"status":@"url", @"title":@"", @"url":(url==nil?@"":url), @"errCode":@"", @"errMsg":@"", @"errUrl":@""}];
    }else if ([keyPath isEqualToString:@"title"]) {
        NSString *title = webView.title;
        [self fireEvent:@"stateChanged" params:@{@"status":@"title", @"title":(title==nil?@"":title), @"url":@"", @"errCode":@"", @"errMsg":@"", @"errUrl":@""}];
    }
}

- (void)updateStyles:(NSDictionary *)styles
{
    for (NSString *key in styles.allKeys) {
        [self dataKey:key value:styles[key] isUpdate:YES];
    }
}

- (void)updateAttributes:(NSDictionary *)attributes
{
    for (NSString *key in attributes.allKeys) {
        [self dataKey:key value:attributes[key] isUpdate:YES];
    }
}

#pragma mark data
- (void)dataKey:(NSString*)key value:(id)value isUpdate:(BOOL)isUpdate
{
    key = [DeviceUtil convertToCamelCaseFromSnakeCase:key];
    if ([key isEqualToString:@"eeui"] && [value isKindOfClass:[NSDictionary class]]) {
        for (NSString *k in [value allKeys]) {
            [self dataKey:k value:value[k] isUpdate:isUpdate];
        }
    } else if ([key isEqualToString:@"content"]) {
        _content = [WXConvert NSString:value];
        if (isUpdate) {
            [self setContent:_content];
        }
    } else if ([key isEqualToString:@"url"]) {
        _url = [WXConvert NSString:value];
        if (isUpdate) {
            [self setUrl:_url];
        }
    } else if ([key isEqualToString:@"progressbarVisibility"]) {
        _isShowProgress = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setProgressbarVisibility:value];
        }
    } else if ([key isEqualToString:@"allowsInlineMediaPlayback"]) {
        _isAllowsInlineMediaPlayback = [WXConvert BOOL:value];
    } else if ([key isEqualToString:@"allowFileAccessFromFileURLs"]) {
        _isAllowFileAccess = [WXConvert BOOL:value];
    } else if ([key isEqualToString:@"scrollEnabled"]) {
        _isScrollEnabled = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setScrollEnabled:value];
        }
    } else if ([key isEqualToString:@"enableApi"]) {
        _isEnableApi = [WXConvert BOOL:value];
    } else if ([key isEqualToString:@"userAgent"]) {
        _userAgent = [WXConvert NSString:value];
    } else if ([key isEqualToString:@"transparency"]) {
        _isTransparency = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setTransparency:value];
        }
    } else if ([key isEqualToString:@"hiddenDone"]) {
        _isHiddenDone = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setHiddenDone:value];
        }
    } else if ([key isEqualToString:@"hapticBackEnabled"]) {
        _isHapticBackEnabled = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setHapticBackEnabled:value];
        }
    } else if ([key isEqualToString:@"disabledUserLongClickSelect"]) {
        _isDisabledUserLongClickSelect = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setDisabledUserLongClickSelect:value];
        }
    } else if ([key isEqualToString:@"fullscreen"]) {
        _isFullscreen = [WXConvert BOOL:value];
        if (isUpdate) {
            [self setFullscreen:value];
        }
    }
}

//开始加载网页
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    [self fireEvent:@"stateChanged" params:@{@"status":@"start", @"title":@"", @"url":@"", @"errCode":@"", @"errMsg":@"", @"errUrl":@""}];
}

//网页加载完成
- (void)webView:(WKWebView *)webView didFinishNavigation:( WKNavigation *)navigation
{
    [self fireEvent:@"stateChanged" params:@{@"status":@"success", @"title":@"", @"url":@"", @"errCode":@"", @"errMsg":@"", @"errUrl":@""}];
    if (self.JSCall != nil) {
        [self.JSCall setJSCallAll:self webView:webView];
        [self.JSCall addRequireModule:webView];
    }
}

//网页加载错误
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (error) {
        NSString *code = [NSString stringWithFormat:@"%ld", (long)error.code];
        NSString *msg = [NSString stringWithFormat:@"%@", error.description];
        [self fireEvent:@"stateChanged" params:@{@"status":@"error", @"title":@"", @"url":@"", @"errCode":code, @"errMsg":msg, @"errUrl":_url}];
    }
}

// 新窗口打开
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        NSString * url = [navigationAction.request.URL absoluteString];
        [self fireEvent:@"stateChanged" params:@{@"status":@"createTarget", @"title":@"", @"url":url, @"errCode":@"", @"errMsg":@"", @"errUrl":@""}];
    }
    return nil;
}

// Web内存过大，进程终止
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0))
{
    [webView reload];
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)response decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (action.navigationType == WKNavigationTypeLinkActivated) {

    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    if (_isEnableApi == YES && self.JSCall != nil && [self.JSCall isJSCall:prompt]) {
        completionHandler([self.JSCall onJSCall:webView JSText:prompt]);
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) { }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields.lastObject.text);
    }]];
    [[DeviceUtil getTopviewControler] presentViewController:alertController animated:YES completion:nil];
}

// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }]];
    [[DeviceUtil getTopviewControler] presentViewController:alertController animated:YES completion:nil];
}

// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [[DeviceUtil getTopviewControler] presentViewController:alertController animated:YES completion:nil];
}

// 允许媒体权限
- (void)webView:(WKWebView *)webView requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame type:(WKMediaCaptureType)type decisionHandler:(void (^)(WKPermissionDecision decision))decisionHandler  API_AVAILABLE(ios(15.0))
{
    decisionHandler(WKPermissionDecisionGrant);
}

//设置浏览器内容
- (void)setContent:(NSString*)content
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    if (![content containsString:@"</html>"] && ![content containsString:@"</HTML>"]) {
        NSString *html = @"<html><header><meta charset='utf-8'><meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no'><style type='text/css'>{commonStyle}</style></header><body>{content}</body></html>";
        html = [html stringByReplacingOccurrencesOfString:@"{commonStyle}" withString:[DeviceUtil webCommonStyle]];
        content = [html stringByReplacingOccurrencesOfString:@"{content}" withString:content];
    }
    [webView loadHTMLString:content baseURL:nil];
}

//设置浏览器地址
- (void)setUrl:(NSString*)urlStr
{
    eeuiWKWebView *webView = (eeuiWKWebView*) self.view;
    _url = urlStr;
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

//设置JavaScript
- (void)setJavaScript:(NSString*)script
{
    eeuiWKWebView *webView = (eeuiWKWebView*) self.view;
    NSString *javaScript = [@";(function(){?})();" stringByReplacingOccurrencesOfString:@"?" withString:script];
    [webView evaluateJavaScript:javaScript completionHandler:nil];
}

//是否显示进度条
- (void)setProgressbarVisibility:(id)var
{
    _isShowProgress = [WXConvert BOOL:var];
    if (_isShowProgress == NO) {
        [self.progressView setProgress:1.0f];
    }
    self.progressView.hidden = !_isShowProgress;
}

//设置是否透明背景
- (void)setTransparency:(id)var
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    if ([WXConvert BOOL:var]) {
        webView.opaque = NO;
        webView.backgroundColor = [UIColor clearColor];
    }else{
        webView.opaque = YES;
        webView.backgroundColor = [UIColor whiteColor];
    }
}

//隐藏键盘done部分（仅支持ios，android无效）
- (void)setHiddenDone:(id)var
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    if ([WXConvert BOOL:var]) {
        [self hideWKWebviewKeyboardShortcutBar: webView];
    }else{
        //不支持恢复
    }
}

//长按网页内容震动（仅支持android，ios无效）
- (void)setHapticBackEnabled:(id)var
{
    _isHapticBackEnabled = [WXConvert BOOL:var];
}

//允许用户长按选择内容（仅支持android，ios无效）
- (void)setDisabledUserLongClickSelect:(id)var
{
    _isDisabledUserLongClickSelect = [WXConvert BOOL:var];
}

//设置是否全屏显示（覆盖顶部状态栏和底部安全区域，仅支持ios，android无效）
- (void)setFullscreen:(id)var
{
    _isFullscreen = [WXConvert BOOL:var];
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    
    if (_isFullscreen) {
        if (@available(iOS 11.0, *)) {
            // 禁用顶部状态栏自动调整
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            
            // 清除所有边距
            webView.scrollView.contentInset = UIEdgeInsetsZero;
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            // 延迟处理确保安全区域信息可用
            dispatch_async(dispatch_get_main_queue(), ^{
                // 获取安全区域信息
                UIWindow *window = [UIApplication sharedApplication].keyWindow;
                CGFloat bottomInset = 0;
                if (@available(iOS 11.0, *)) {
                    bottomInset = window.safeAreaInsets.bottom;
                }
                
                // 增加内容高度以覆盖底部安全区域
                if (bottomInset > 0) {
                    UIEdgeInsets scrollInsets = webView.scrollView.contentInset;
                    scrollInsets.bottom = -bottomInset; // 负值抵消安全区域
                    webView.scrollView.contentInset = scrollInsets;
                    
                    // 增加内容尺寸确保内容可以滚动到底部
                    CGSize contentSize = webView.scrollView.contentSize;
                    contentSize.height += bottomInset;
                    webView.scrollView.contentSize = contentSize;
                }
                
                // 更新布局
                [webView setNeedsLayout];
                [webView layoutIfNeeded];
            });
        }
    } else {
        if (@available(iOS 11.0, *)) {
            // 恢复默认行为
            webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
            webView.scrollView.contentInset = UIEdgeInsetsZero;
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        }
    }
}

//设置是否允许滚动
- (void)setScrollEnabled:(id)var
{
    _isScrollEnabled = [WXConvert BOOL:var];
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    webView.scrollView.scrollEnabled = _isScrollEnabled;
}

//是否可以后退
- (void)canGoBack:(WXModuleKeepAliveCallback)callback
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    callback(@(webView.canGoBack), NO);
}

//后退并返回是否后退成功
- (void)goBack:(WXModuleKeepAliveCallback)callback
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;

    if (webView.canGoBack) {
        [webView goBack];
    }
    callback(@(webView.canGoBack), NO);
}

//是否可以前进
- (void)canGoForward:(WXModuleKeepAliveCallback)callback
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    callback(@(webView.canGoForward), NO);
}

//前进并返回是否前进成功
- (void)goForward:(WXModuleKeepAliveCallback)callback
{
    eeuiWKWebView *webView = (eeuiWKWebView*)self.view;
    if (webView.canGoForward) {
        [webView goForward];
    }
    callback(@(webView.canGoForward), NO);
}

//网页向组件发送参数
- (void)sendMessage:(id) message
{
    if (_isReceiveMessage) {
        [self fireEvent:@"receiveMessage" params:@{@"message": message}];
    }
}


@end
