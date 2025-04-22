//
//  eeuiBridge.m
//  eeuiProject
//
//  Created by 高一 on 2019/1/2.
//

#import "eeuiBridge.h"

#import "eeuiAdDialogManager.h"
#import "eeuiAjaxManager.h"
#import "eeuiAlertManager.h"
#import "eeuiCachesManager.h"
#import "eeuiCaptchaManager.h"
#import "eeuiLoadingManager.h"
#import "eeuiLocationManager.h"
#import "eeuiSaveImageManager.h"
#import "eeuiNavMaskManager.h"
#import "eeuiPhotoManager.h"
#import "eeuiShareManager.h"
#import "eeuiStorageManager.h"
#import "eeuiToastManager.h"
#import "eeuiNewPageManager.h"
#import "eeuiVersion.h"
#import "DeviceUtil.h"
#import "Config.h"
#import "Cloud.h"
#import "scanViewController.h"
#import <AdSupport/AdSupport.h>
#import "CustomWeexSDKManager.h"

#define iPhoneXSeries [DeviceUtil isNotchedScreen]

@implementation eeuiBridge

- (void)initialize
{

}

#pragma mark 广告弹窗

- (void)adDialog:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAdDialogManager sharedIntstance] adDialog:params callback:callback];
}

- (void)adDialogClose:(NSString*)dialogName
{
    [[eeuiAdDialogManager sharedIntstance] adDialogClose:dialogName];
}

#pragma mark 跨域异步请求

- (void)ajax:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAjaxManager sharedIntstance] ajax:params callback:callback];
}

- (void)ajaxCancel:(NSString*)name
{
    [[eeuiAjaxManager sharedIntstance] ajaxCancel:name];
}

- (void)getCacheSizeAjax:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAjaxManager sharedIntstance] getCacheSizeAjax:callback];
}

- (void)clearCacheAjax
{
    [[eeuiAjaxManager sharedIntstance] clearCacheAjax];
}

#pragma mark 确认对话框

- (void)alert:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAlertManager sharedIntstance] alert:params callback:callback];
}

- (void)confirm:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAlertManager sharedIntstance] confirm:params callback:callback];
}

- (void)input:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiAlertManager sharedIntstance] input:params callback:callback];
}

#pragma mark 缓存管理

- (void)getCacheSizeDir:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] getCacheSizeDir:callback];
}

- (void)clearCacheDir:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] clearCacheDir:callback];
}
- (void)getCacheSizeFiles:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] getCacheSizeFiles:callback];
}
- (void)clearCacheFiles:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] clearCacheFiles:callback];
}
- (void)getCacheSizeDbs:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] getCacheSizeDir:callback];
}
- (void)clearCacheDbs:(WXModuleKeepAliveCallback)callback;
{
    [[eeuiCachesManager sharedIntstance] clearCacheDbs:callback];
}

#pragma mark 验证弹窗

- (void)swipeCaptcha:(NSString*)imgUrl callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiCaptchaManager sharedIntstance] swipeCaptcha:imgUrl callback:callback];
}

#pragma mark 等待弹窗

- (NSString*)loading:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    NSString *str = [[eeuiLoadingManager sharedIntstance] loading:params callback:callback];
    return str;
}

- (void)loadingClose:(NSString*)name
{
    [[eeuiLoadingManager sharedIntstance] loadingClose:name];
}


#pragma mark 页面功能

- (void)openPage:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] openPage:params weexInstance:[[WXSDKManager bridgeMgr] topInstance] callback:callback];
}

- (NSDictionary*)getPageInfo:(id)params
{
    return [[eeuiNewPageManager sharedIntstance] getPageInfo:params weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)getPageInfoAsync:(id)params callback:(WXModuleCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] getPageInfoAsync:params weexInstance:[[WXSDKManager bridgeMgr] topInstance] callback:callback];
}

- (void)reloadPage:(id)params
{
    [[eeuiNewPageManager sharedIntstance] reloadPage:params weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setSoftInputMode:(id)params modo:(NSString*)modo
{
    [[eeuiNewPageManager sharedIntstance] setSoftInputMode:params modo:modo weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setStatusBarStyle:(BOOL)isLight
{
    [[eeuiNewPageManager sharedIntstance] setStatusBarStyle:isLight weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)statusBarStyle:(BOOL)isLight
{
    [[eeuiNewPageManager sharedIntstance] setStatusBarStyle:isLight weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setStatusBarColor:(NSString *)colorString
{
    [[eeuiNewPageManager sharedIntstance] setStatusBarColor:colorString weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setBackgroundColor:(NSString *)backgroundColor
{
    [[eeuiNewPageManager sharedIntstance] setBackgroundColor:backgroundColor weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setPageBackPressed:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] setPageBackPressed:params callback:callback];
}

- (void)setOnRefreshListener:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] setOnRefreshListener:params weexInstance:[[WXSDKManager bridgeMgr] topInstance] callback:callback];
}

- (void)setRefreshing:(id)params refreshing:(BOOL)refreshing
{
    [[eeuiNewPageManager sharedIntstance] setRefreshing:params refreshing:refreshing weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)setPageStatusListener:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] setPageStatusListener:params weexInstance:[[WXSDKManager bridgeMgr] topInstance] callback:callback];
}

- (void)clearPageStatusListener:(id)params
{
    [[eeuiNewPageManager sharedIntstance] clearPageStatusListener:params  weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)onPageStatusListener:(id)params status:(NSString*)status
{
    [[eeuiNewPageManager sharedIntstance] onPageStatusListener:params status:status weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)postMessage:(id)params
{
    [[eeuiNewPageManager sharedIntstance] postMessage:params];
}

- (void)getCacheSizePage:(WXModuleKeepAliveCallback)callback
{
    [[eeuiNewPageManager sharedIntstance] getCacheSizePage:callback];
}

- (void)clearCachePage
{
    [[eeuiNewPageManager sharedIntstance] clearCachePage];
}

- (void)closePage:(id)params
{
    [[eeuiNewPageManager sharedIntstance] closePage:params weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)closePageTo:(id)params
{
    [[eeuiNewPageManager sharedIntstance] closePageTo:params weexInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (void)openWeb:(NSString*)url
{
    [[eeuiNewPageManager sharedIntstance] openWeb:url];
}

- (void)goDesktop
{
    [[eeuiNewPageManager sharedIntstance] goDesktop];
}

- (NSString*)getThemeName
{
    return [[eeuiNewPageManager sharedIntstance] getThemeName:[[WXSDKManager bridgeMgr] topInstance]];
}

- (id)getConfigRaw:(NSString*)key
{
    return [Config getRawValue:key];
}

- (NSString*)getConfigString:(NSString*)key
{
    return [Config getString:key defaultVal:@""];
}

- (void)setCustomConfig:(NSString*)key params:(id)params
{
    [Config setCustomConfig:key value:params];
}

- (NSDictionary*)getCustomConfig
{
    return [Config getCustomConfig];
}

- (void)clearCustomConfig
{
    [Config clearCustomConfig];
}

- (NSString*)realUrl:(NSString*)url
{
    return [DeviceUtil realUrl:url];
}

- (NSString*)rewriteUrl:(NSString*)url
{
    return [DeviceUtil rewriteUrl:url mInstance:[[WXSDKManager bridgeMgr] topInstance]];
}

- (NSInteger)getUpdateId
{
    NSMutableArray *tempArray = [Config verifyData];
    if (tempArray.count == 0) {
        return 0;
    }else{
        return [WXConvert NSInteger:[tempArray objectAtIndex:0]];
    }
}

- (void)checkUpdate
{
    [Cloud appData:YES];
}

#pragma mark 打开其他APP

- (void)openOtherApp:(NSString*)type
{
    NSString *ali = [NSString stringWithFormat:@"ali%@", @"pay"];//防止检测被拒

    NSString *app = @"";
    if ([type isEqualToString:@"wx"]) {
        app = @"weixin";
    } else if ([type isEqualToString:@"qq"]) {
        app = @"mqq";
    } else if ([type isEqualToString:ali]) {
        app = ali;
    } else if ([type isEqualToString:@"jd"]) {
        app = @"jd";
    }
    #warning ssss 京东开不开
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", app]];

    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

- (void)openOtherAppTo:(NSString*)pkg cls:(NSString*)cls callback:(WXModuleKeepAliveCallback)callback
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", pkg, cls]];

    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
        if (callback != nil) {
            callback(@{@"status":@"success", @"error":@""}, NO);
        }
    }else{
        if (callback != nil) {
            callback(@{@"status":@"error", @"error":@"无法跳转到指定APP"}, NO);
        }
    }
}

#pragma mark 复制粘贴

- (void)copyText:(NSString*)text
{
    UIPasteboard * pastboard = [UIPasteboard generalPasteboard];
    pastboard.string = text;
}

- (NSString*)pasteText
{
    UIPasteboard * pastboard = [UIPasteboard generalPasteboard];
    return pastboard.string;
}

#pragma mark 二维码

- (void)openScaner:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    if (callback == nil) {
        return;
    }
    NSString *title = @"";
    NSString *desc = @"";
    BOOL continuous = NO;
    if ([params isKindOfClass:[NSDictionary class]]) {
        title = params[@"title"] ? [WXConvert NSString:params[@"title"]] : @"";
        desc = params[@"desc"] ? [WXConvert NSString:params[@"desc"]] : @"";
        continuous = params[@"continuous"] ? [WXConvert BOOL:params[@"continuous"]] : NO;
    } else if ([params isKindOfClass:[NSString class]]){
        desc = (NSString*)params;
    }

    scanViewController *scan = [[scanViewController alloc]init];
    scan.headTitle = title;
    scan.desc = desc;
    scan.continuous = continuous;

    callback(@{
            @"pageName": @"scanPage",
            @"status": @"create"
    }, YES);

    scan.scanerBlock = ^(NSDictionary *dic) {
        NSMutableDictionary *result = dic.mutableCopy;
        result[@"pageName"] = @"scanPage";
        callback(result, ![result[@"status"] isEqualToString:@"destroy"]);
    };
    [[[DeviceUtil getTopviewControler] navigationController] pushViewController:scan animated:YES];
}

#pragma mark 保存图片至本地

- (void)saveImage:(NSString*)imgUrl callback:(WXKeepAliveCallback)callback
{
    [[eeuiSaveImageManager sharedIntstance] saveImage:imgUrl callback:callback];
}

- (void)saveImageTo:(NSString*)imgUrl childDir:(NSString*)childDir callback:(WXKeepAliveCallback)callback
{
    [[eeuiSaveImageManager sharedIntstance] saveImage:imgUrl callback:callback];
}

#pragma mark 分享

- (void)shareText:(NSString*)text
{
    [[eeuiShareManager sharedIntstance] shareText:text];
}

- (void)shareImage:(NSString*)imgUrl
{
    [[eeuiShareManager sharedIntstance] shareImage:imgUrl];
}

#pragma mark 保存数据信息

- (void)setCachesString:(NSString*)key value:(NSString*)value expired:(NSString*)expired
{
    [[eeuiStorageManager sharedIntstance] setCachesString:key value:value expired:[WXConvert NSInteger:expired]];
}

- (id)getCachesString:key defaultVal:(NSString*)defaultVal
{
    return [[eeuiStorageManager sharedIntstance] getCachesString:key defaultVal:defaultVal];
}

- (void)setVariate:(NSString*)key value:(id)value
{
    [[eeuiStorageManager sharedIntstance] setVariate:key value:value];
}

- (id)getVariate:(NSString*)key defaultVal:(id)defaultVal
{
    return [[eeuiStorageManager sharedIntstance] getVariate:key defaultVal:defaultVal];
}

#pragma mark 系统信息

- (NSInteger)getStatusBarHeight
{
    if (iPhoneXSeries) {
        return 44;
    } else {
        return 20;
    }
}

- (NSInteger)getStatusBarHeightPx
{
    return [self weexDp2px:[self getStatusBarHeight]];
}

- (NSInteger)getNavigationBarHeight
{
    eeuiStorageManager *storage = [eeuiStorageManager sharedIntstance];
    NSString *value = [storage getCachesString:@"__system:keyboardHeight" defaultVal:@"0"];
    return [value intValue];
}

- (NSInteger)getNavigationBarHeightPx
{
    return [self weexDp2px:[self getNavigationBarHeight]];
}

- (NSInteger)getVersion
{
    return [[eeuiVersion eeuiVersion] integerValue];
}

- (NSString*)getVersionName
{
    return [eeuiVersion eeuiVersionName];
}

- (NSInteger)getLocalVersion
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary]  objectForKey:@"CFBundleVersion"];

    NSArray *list = [version componentsSeparatedByString:@"."];
    if (list.count > 0) {
        //版本号形式
        return [list.lastObject integerValue];
    } else {
        //数字形式
        return [version integerValue];
    }
}

- (NSString*)getLocalVersionName
{
    return (NSString*)[[[NSBundle mainBundle] infoDictionary]  objectForKey:@"CFBundleShortVersionString"];
}

- (NSInteger)compareVersion:(NSString*)firstVersion secondVersion:(NSString*)secondVersion
{
    NSInteger comp = [firstVersion compare:secondVersion];
    if (comp == NSOrderedAscending) {
        return -1;
    } else if (comp == NSOrderedDescending){
        return 1;
    } else {
        return 0;
    }
}

- (NSString*)getImei
{
    return (NSString*)[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

- (NSString*)getIfa
{
    return [self getImei];
}

- (void)getImeiAsync:(WXModuleCallback)callback
{
    if (callback == nil) {
        return;
    }
    callback(@{@"status":@"success", @"content":[self getImei]});
}

- (void)getIfaAsync:(WXModuleCallback)callback
{
    [self getImeiAsync:callback];
}

- (void)getDeviceInfo:(WXModuleCallback)callback
{
    if (callback == nil) {
        return;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *modelName = [DeviceUtil getDeviceModelName];
    
    NSString *deviceName = device.name;
    if (@available(iOS 16.0, *)) {
        deviceName = @"";
    }
    
    callback(@{
        @"status": @"success",      // 状态码，例如："success"
        @"manufacturer": @"Apple",  // 制造商，例如："Apple"
        @"brand": @"Apple",         // 品牌，例如："Apple"
        @"model": device.model,     // 设备类型，例如："iPhone"、"iPad"、"iPod touch"
        @"modelName": modelName,    // 具体型号名称，例如："iPhone 13 Pro Max"、"iPad Air (5th generation)"
        @"deviceName": deviceName,  // 用户设置的设备名称，例如："张三的iPhone"、"公司的iPad"（iOS 16+仅返回空）
        @"systemName": device.systemName,     // 操作系统名称，例如："iOS"、"iPadOS"
        @"systemVersion": device.systemVersion // 操作系统版本，例如："17.4.1"
    });
}

- (NSInteger)getSDKVersionCode
{
    NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];
    NSArray *list = [phoneVersion componentsSeparatedByString:@"."];
    if (list.count > 0) {
        return [list.firstObject integerValue];
    } else {
        return [phoneVersion integerValue];
    }
}

- (NSString*)getSDKVersionName
{
    return (NSString*)[[UIDevice currentDevice] systemVersion];
}

- (Boolean)isIPhoneXType
{
    return iPhoneXSeries;
}

- (Boolean)isDebug
{
#ifdef DEBUG
    return true;
#else
    return false;
#endif
}

- (void)getSafeAreaInsets:(WXModuleCallback)callback
{
    if (callback == nil) {
        return;
    }
    
    // 使用 DeviceUtil 共享方法获取安全区域高度
    NSDictionary *insets = [DeviceUtil getSafeAreaInsets];
    
    // 添加状态信息
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:insets];
    [result setObject:@"success" forKey:@"status"];
    
    callback(result);
}

#pragma mark 导航栏遮罩

- (NSString*)addNavMask:(NSString*)color
{
    return [[eeuiNavMaskManager sharedIntstance] addNavMask:color];
}

- (void)removeNavMask:(NSString*)name
{
    [[eeuiNavMaskManager sharedIntstance] removeNavMask:name];
}

- (void)removeAllNavMasks
{
    [[eeuiNavMaskManager sharedIntstance] removeAllNavMasks];
}

#pragma mark 吐司提示

- (void)toast:(NSDictionary *)param
{
    [[eeuiToastManager sharedIntstance] toast:param];
}

- (void)toastClose
{
    [[eeuiToastManager sharedIntstance] toastClose];
}

#pragma mark px单位转换

//weex px转屏幕像素
- (NSInteger)weexPx2dp:(NSInteger)value
{
    return [UIScreen mainScreen].bounds.size.width * 1.0 / 750 * value;
}

//屏幕像素转weex px
- (NSInteger)weexDp2px:(NSInteger)value
{
    return 750 * 1.0 / [UIScreen mainScreen].bounds.size.width * value;
}

#pragma mark 键盘
- (void) keyboardUtils:(NSString*)key
{
    //动态隐藏软键盘
    if ([key isEqualToString:@"hideSoftInput"]) {
        UIViewController *vc = [DeviceUtil getTopviewControler];
        [vc.view endEditing:YES];
    }
}

//动态隐藏软键盘
- (void) keyboardHide
{
    UIViewController *vc = [DeviceUtil getTopviewControler];
    [vc.view endEditing:YES];
}

//判断软键盘是否可见
- (BOOL) keyboardStatus
{
    return [CustomWeexSDKManager getKeyBoardlsVisible];
}

#pragma mark 屏幕
//打开屏幕常亮
- (void) keepScreenOn
{
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

//关闭屏幕常亮
- (void) keepScreenOff
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark 位置
//获取当前位置
- (void) getGeolocation:(WXModuleKeepAliveCallback)callback
{
    [[eeuiLocationManager shared] requestLocationWithCompletion:^(CLLocation * _Nullable location, NSError * _Nullable error) {
        if (error) {
            callback(@{@"status":@"error", @"error":error.localizedDescription}, NO);
            return;
        }
        CLLocationCoordinate2D coordinate = location.coordinate;
        callback(@{@"status":@"success", @"latitude":@(coordinate.latitude), @"longitude":@(coordinate.longitude)}, NO);
    }];
}

#pragma mark 摇动
//开启应用程序级别的摇动撤销
- (void) shakeToEditOn
{
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
}

//禁用应用程序级别的摇动撤销
- (void) shakeToEditOff
{
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
}

#pragma mark 相册相关
//获取相册最新图片（同时返回缩略图和原图）
- (void) getLatestPhoto:(WXModuleKeepAliveCallback)callback
{
    [[eeuiPhotoManager sharedInstance] getLatestPhoto:^(id result, BOOL keepAlive) {
        if (callback) {
            callback(result, keepAlive);
        }
    }];
}

//上传图片到指定URL
- (void) uploadPhoto:(id)params callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiPhotoManager sharedInstance] uploadPhoto:params callback:^(id result, BOOL keepAlive) {
        if (callback) {
            callback(result, keepAlive);
        }
    }];
}

//取消图片上传
- (void) cancelUploadPhoto:(NSString*)uploadId callback:(WXModuleKeepAliveCallback)callback
{
    [[eeuiPhotoManager sharedInstance] cancelUploadPhoto:uploadId callback:^(id result, BOOL keepAlive) {
        if (callback) {
            callback(result, keepAlive);
        }
    }];
}

@end
