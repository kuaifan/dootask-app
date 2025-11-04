//
//  DeviceUtil.m
//  WeexTestDemo
//
//  Created by apple on 2018/6/5.
//  Copyright 2018年 TomQin. All rights reserved.
//

#import "DeviceUtil.h"
#import <sys/sysctl.h>
#import <math.h>
#import "WeexSDKManager.h"
#import "TBCityIconInfo.h"
#import "TBCityIconFont.h"
#import "eeuiViewController.h"
#import "Config.h"

/// 设备宽度，跟横竖屏无关
#define DEVICE_WIDTH MIN([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)

/// 设备高度，跟横竖屏无关
#define DEVICE_HEIGHT MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)

#define NSEC_PER_SEC 1000000000ull //1000000000纳秒/秒

static UIWindow *eeuiActiveKeyWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = application.connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isHidden) {
                    continue;
                }
                if (window.isKeyWindow) {
                    return window;
                }
            }
            
            // Fallback to first visible window in the scene
            for (UIWindow *window in windowScene.windows) {
                if (!window.isHidden) {
                    return window;
                }
            }
        }
    }
    
    UIWindow *keyWindow = application.keyWindow;
    if (keyWindow != nil) {
        return keyWindow;
    }
    
    for (UIWindow *window in application.windows.reverseObjectEnumerator) {
        if (!window.isHidden) {
            return window;
        }
    }
    
    return application.windows.lastObject;
}

static BOOL eeuiRectsAlmostEqual(CGRect rect1, CGRect rect2) {
    rect1 = CGRectStandardize(rect1);
    rect2 = CGRectStandardize(rect2);
    const CGFloat tolerance = 0.5f;
    
    BOOL originsEqual = fabs(rect1.origin.x - rect2.origin.x) <= tolerance &&
                        fabs(rect1.origin.y - rect2.origin.y) <= tolerance;
    BOOL sizesEqual = fabs(rect1.size.width - rect2.size.width) <= tolerance &&
                      fabs(rect1.size.height - rect2.size.height) <= tolerance;
    return originsEqual && sizesEqual;
}

@implementation DeviceUtil


//设计尺寸转开发尺寸 px -> pt
+ (CGFloat)scale:(NSInteger)value
{
    //weex以750宽为设计尺寸
    return [UIScreen mainScreen].bounds.size.width * 1.0f/750 * value;
}

+ (CGFloat)scaleFloat:(float)value
{
    //weex以750宽为设计尺寸
    return [UIScreen mainScreen].bounds.size.width * 1.0f/750 * value;
}

//字体尺寸转换
+ (NSInteger)font:(NSInteger)font
{
    return [UIScreen mainScreen].bounds.size.width * 1.0f/750 * font;
}

//获取当前控制器
+ (UIViewController *)getTopviewControler {
    //获得当前活动窗口的根视图
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *currentShowingVC = [self findCurrentShowingViewControllerFrom:vc];
    return currentShowingVC;
}

+ (UIViewController *)findCurrentShowingViewControllerFrom:(UIViewController *)vc
{
    //方法1：递归方法 Recursive method
    UIViewController *currentShowingVC;
    if ([vc presentedViewController]) { //注要优先判断vc是否有弹出其他视图，如有则当前显示的视图肯定是在那上面
        // 当前视图是被presented出来的
        UIViewController *nextRootVC = [vc presentedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        UIViewController *nextRootVC = [(UITabBarController *)vc selectedViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else if ([vc isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        UIViewController *nextRootVC = [(UINavigationController *)vc visibleViewController];
        currentShowingVC = [self findCurrentShowingViewControllerFrom:nextRootVC];
        
    } else {
        // 根视图为非导航类
        currentShowingVC = vc;
    }
    
    return currentShowingVC;
}


//url转换
+ (NSString*)urlEncoder:(NSString*)url
{
    url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    return url;
}

//规范化url，删除所有符号连接（比如'/./', '/../' 以及多余的'/'）
+ (NSString*)realUrl:(NSString*)url
{
    if ([url containsString:@"/./"] || [url containsString:@"/../"]) {
        url = [url stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        NSString *last = @"";
        while (![url isEqualToString:last]) {
            last = url;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/[^/]+/\\.\\./" options:NSRegularExpressionCaseInsensitive error:nil];
            url  = [regex stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, url.length) withTemplate:@"/"];
        }
        last = @"";
        while (![url isEqualToString:last]) {
            last = url;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"/\\./+" options:NSRegularExpressionCaseInsensitive error:nil];
            url  = [regex stringByReplacingMatchesInString:url options:0 range:NSMakeRange(0, url.length) withTemplate:@"/"];
        }
    }
    return url;
}

//重写url（传入 WXSDKInstance）
+ (NSString*)rewriteUrl:(NSString*)url mInstance:(WXSDKInstance*)mInstance
{
    NSString* homePage = nil;
    if ([mInstance.viewController isKindOfClass:[eeuiViewController class]]) {
        eeuiViewController *top = (eeuiViewController *)mInstance.viewController;
        if (top && top.url) {
            homePage = top.url;
        }
    }
    return [self rewriteUrl:url homePage:homePage];
}

//重写url（传入homePage）
+ (NSString*)rewriteUrl:(NSString*)url homePage:(NSString*)homePage
{
    if (url.length == 0) {
        return @"";
    }
    if ([url hasPrefix:@"file://file://"]) {
        url = [url substringFromIndex:7];
    }

    if (url == nil || [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"ftp://"] || [url hasPrefix:@"file://"] || [url hasPrefix:@"data:image/"]) {
        NSArray* elts = [url componentsSeparatedByString:@"?"];
        if (elts.count >= 2) {
            NSArray *urls = [elts.lastObject componentsSeparatedByString:@"="];
            for (NSString *str in urls) {
                if ([str isEqualToString:@"_wx_tpl"]) {
                    url = [[urls lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    break;
                }
            }
        }
    }
    if (url.length == 0 || [url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"ftp://"] || [url hasPrefix:@"data:image/"]) {
        return [self realUrl:url];
    }

    if (homePage.length == 0) {
        homePage = [[WeexSDKManager sharedIntstance] weexUrl];
        if ([[[WXSDKManager bridgeMgr] topInstance].viewController isKindOfClass:[eeuiViewController class]]) {
            eeuiViewController *top = (eeuiViewController *)[[WXSDKManager bridgeMgr] topInstance].viewController;
            if (top && top.url) {
                homePage = top.url;
            }
        }
        if (homePage.length == 0) {
            eeuiViewController *top = (eeuiViewController *)[self getTopviewControler];
            if (top && top.url) {
                homePage = top.url;
            }
        }       
    }
    if (homePage.length == 0) {
        return [self realUrl:url];
    }
    
    if ([url hasPrefix:@"/"]) {
        NSString *tempUrl = [NSString stringWithFormat:@"file://%@", [Config getResourcePath:@"bundlejs"]];
        if ([homePage hasPrefix:tempUrl]) {
            url = [NSString stringWithFormat:@"root:/%@", url];
        }
    }
    
    if ([url hasPrefix:@"root:"]) {
        NSInteger fromIndex = [url hasPrefix:@"root://"] ? 7 : 5;
        NSString *tempUrl = [NSString stringWithFormat:@"file://%@", [Config getResourcePath:@"bundlejs"]];
        if ([homePage hasPrefix:tempUrl]) {
            return [self realUrl:[NSString stringWithFormat:@"%@/eeui/%@", tempUrl, [url substringFromIndex:fromIndex]]];
        }else{
            url = [NSString stringWithFormat:@"/%@", [url substringFromIndex:fromIndex]];
        }
    }
    
    if ([url containsString:@"page_cache"]) {
        NSString *filePath = [NSString stringWithFormat:@"file://%@",
                              [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"page_cache"]];
        if ([url hasPrefix:filePath]) {
            url = [url substringFromIndex:filePath.length];
        }
    }
    
    if ([url hasPrefix:@"file://"]) {
        return [self realUrl:url];
    }

    NSURL *URL = [NSURL URLWithString:homePage];
    NSString *scheme = [URL scheme];
    NSString *host = [URL host];
    NSInteger port = [[URL port] integerValue];
    NSString *path = [URL path];

    if (scheme == nil) scheme = @"";
    if (host == nil) host = @"";
    
    if ([url hasPrefix:@"//"]) {
        return [self realUrl:[NSString stringWithFormat:@"%@:%@", scheme, url]];
    }
    NSString *newUrl = [NSString stringWithFormat:@"%@://%@%@", scheme, host, port > 0 && port != 80 ? [NSString stringWithFormat:@":%ld", (long)port] : @""];
    if ([url isAbsolutePath]) {
        NSString *rootPath = [NSString stringWithFormat:@"file://%@", [Config getResourcePath:@"bundlejs"]];
        if ([homePage hasPrefix:rootPath]) {
            newUrl = [rootPath stringByAppendingString:url];
        }else{
            newUrl = [newUrl stringByAppendingString:url];
        }
    } else {
        if ([path isEqualToString:@"/"]) {
            path = @"";
        } else {
            path = [path stringByDeletingLastPathComponent];
        }
        newUrl = [NSString stringWithFormat:@"%@%@/%@", newUrl, path, url];
    }
    return [self realUrl:newUrl];
}

//url添加js后缀
+ (NSString*)suffixUrl:(NSString*)pageType url:(NSString*)url
{
    if ([pageType isEqualToString:@"app"] || [pageType isEqualToString:@"weex"]) {
        NSArray *array = [url componentsSeparatedByString:@"/"];
        NSString *lastUrl = [array lastObject];
        if (!([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"] || [url hasPrefix:@"ftp://"] || [url hasPrefix:@"file://"])
            && ![lastUrl containsString:@"."]) {
            url = [NSString stringWithFormat:@"%@.js", url];
        }
    }
    return url;
}

//根据文本属性获取图片
+ (UIImage*)getIconText:(NSString*)text font:(NSInteger)font color:(NSString*)icolor
{
    NSString *key = @"";
    NSInteger fontSize = font > 0 ? font : 12;
    NSString *color = icolor.length > 0 ? icolor : @"#242424";
    NSArray *list = [text componentsSeparatedByString:@" "];
    if (list.count == 2) {
        key = [WXConvert NSString:list.firstObject];
        NSString *other = [WXConvert NSString:list.lastObject];
        if ([other hasSuffix:@"px"] || [other hasSuffix:@"dp"] || [other hasSuffix:@"sp"] || [other hasSuffix:@"%"]) {
            fontSize = FONT([other integerValue]);
        } else if ([other isEqualToString:@"#"]) {
            color = other;
        }
    } else {
        key = text;
    }
    [TBCityIconFont setFontName:@"eeuiicon"];
    NSString *imgName = [IconFontUtil iconFont:key];

    return [UIImage iconWithInfo:TBCityIconInfoMake(imgName, fontSize, [WXConvert UIColor:color])];
}

//字符串中划线转驼峰写法
+ (NSString *)convertToCamelCaseFromSnakeCase:(NSString *)key
{
    NSMutableString *str = [NSMutableString stringWithString:key];
    while ([str containsString:@"-"]) {
        NSRange range = [str rangeOfString:@"-"];
        if (range.location + 1 < [str length]) {
            char c = [str characterAtIndex:range.location+1];
            [str replaceCharactersInRange:NSMakeRange(range.location, range.length+1) withString:[[NSString stringWithFormat:@"%c",c] uppercaseString]];
        }
    }
    return str;
}

//重设图片大小
+ (UIImage *)imageResize:(UIImage*)img andResizeTo:(CGSize)newSize icon:(NSString *)icon
{
    CGFloat scale = [[UIScreen mainScreen]scale];
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    CGFloat x = 0;
    if (![icon containsString:@"//"] && ![icon hasPrefix:@"data:"]) {
        x = - newSize.width / 12 + scale / 12;
    }
    [img drawInRect:CGRectMake(x, 0, newSize.width, newSize.height)];//有偏移，自己加了参数
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//获取Appboard内容
+ (NSString *)getAppboardContent
{
    if (mAppboardContent == nil) {
        mAppboardContent = [NSMutableDictionary dictionary];
    }
    if (mAppboardWifi == nil) {
        mAppboardWifi = [NSMutableDictionary dictionary];
    }
    [self loadAppboardContent];
    [self loadAppboardUpdate];
    //
    NSString *appboard = @"";
    for (NSString *key in mAppboardWifi) {
        NSString *value = mAppboardWifi[key];
        if (value.length > 0) {
            appboard = [NSString stringWithFormat:@"%@%@;", appboard, value];
        }
    }
    for (NSString *key in mAppboardContent) {
        NSString *temp = mAppboardWifi[key];
        if (temp.length == 0) {
            NSString *value = mAppboardContent[key];
            if (value.length > 0) {
                appboard = [NSString stringWithFormat:@"%@%@;", appboard, value];
            }
        }
    }
    if (appboard.length > 0) {
        if (![appboard hasPrefix:@"// { \"framework\": \"Vue\"}"]) {
            appboard = [NSString stringWithFormat:@"%@%@", @"// { \"framework\": \"Vue\"}\nif(typeof app==\"undefined\"){app=weex}\n", appboard];
        }
    }
    return appboard;
}

//加载assets下的appboard
+ (void)loadAppboardContent
{
    NSString *path = [Config getResourcePath:@"bundlejs/eeui/appboard"];
    NSFileManager * fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    [fileManger fileExistsAtPath:path isDirectory:&isDir];
    if (isDir) {
        NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
        NSString * subPath = nil;
        for (NSString * str in dirArray) {
            if ([str hasSuffix:@".js"]) {
                NSString *key = [NSString stringWithFormat:@"appboard/%@", str];
                NSString *temp = [mAppboardContent objectForKey:key];
                if (temp.length == 0) {
                    subPath  = [Config verifyFile:[path stringByAppendingPathComponent:str]];
                    BOOL issubDir = NO;
                    [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];
                    BOOL isExist = [fileManger fileExistsAtPath:subPath isDirectory:&isDir];
                    if (isExist) {
                        NSData *fileData = [[NSData alloc] initWithContentsOfFile:subPath];
                        temp = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
                        [mAppboardContent setValue:temp forKey:key];
                    }
                }
            }
        }
    }
}

//加载热更新下的appboard
+ (void)loadAppboardUpdate
{
    NSString *path = [Config getSandPath:@"update"];
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = NO;

    NSMutableArray *tempArray = [Config verifyData];
    for (NSString * dirName in tempArray) {
        NSString *tempPath = [NSString stringWithFormat:@"%@/%@/appboard", path, dirName];
        isExist = [myFileManager fileExistsAtPath:tempPath isDirectory:&isDir];
        if (isExist && isDir) {
            NSArray *tmpArray = [myFileManager contentsOfDirectoryAtPath:tempPath error:nil];
            for (NSString * tmpName in tmpArray) {
                if ([tmpName hasSuffix:@".js"]) {
                    NSString *key = [NSString stringWithFormat:@"appboard/%@", tmpName];
                    NSString *temp = [mAppboardContent objectForKey:key];
                    if (temp.length == 0) {
                        NSString *filePath = [NSString stringWithFormat:@"%@/%@", tempPath, tmpName];
                        isExist = [myFileManager fileExistsAtPath:filePath isDirectory:&isDir];
                        if (isExist && !isDir) {
                            NSData *fileData = [[NSData alloc] initWithContentsOfFile:filePath];
                            temp = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
                            [mAppboardContent setValue:temp forKey:key];
                        }
                    }
                }
            }
        }
    }
}

//设置Appboard内容
+ (void)setAppboardContent:(NSString *)key content:(NSString *)content
{
    if (mAppboardContent == nil) {
        mAppboardContent = [NSMutableDictionary dictionary];
    }
    [mAppboardContent setValue:content forKey:key];
}

//清空Appboard内容
+ (void)clearAppboardContent
{
    mAppboardContent = [NSMutableDictionary dictionary];
}

//设置Appboard内容 (WIFI同步)
+ (void)setAppboardWifi:(NSString *)key content:(NSString *)content
{
    if (mAppboardWifi == nil) {
        mAppboardWifi = [NSMutableDictionary dictionary];
    }
    [mAppboardWifi setValue:content forKey:key];
}

//清空Appboard内容 (WIFI同步)
+ (void)clearAppboardWifi
{
    mAppboardWifi = [NSMutableDictionary dictionary];
}

//下载文件
+ (void)downloadScript:(NSString *)url appboard:(NSString *)appboard cache:(NSInteger)cache callback:(void(^)(NSString* path))callback
{
    NSDictionary *data = [WeexSDKManager sharedIntstance].cacheData[url];
    if (data != nil) {
        NSDictionary *data = [WeexSDKManager sharedIntstance].cacheData[url];
        NSInteger time = [data[@"cache_time"] integerValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
        if ([date compare:[NSDate date]] == NSOrderedDescending) {
            callback([NSString stringWithFormat:@"file://%@", data[@"cache_url"]]);
            return;
        }
    }
    //
    NSString *filePath = [NSString stringWithFormat:@"file://%@/",
                          [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"page_cache"]];
    if ([url hasPrefix:filePath]) {
        callback(url);
        return;
    }
    //
    NSString *urlStr = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *downloadTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSString *path = @"/";
            NSString *rootPath = [NSString stringWithFormat:@"file://%@", [Config getResourcePath:@"bundlejs"]];
            if ([url hasPrefix:rootPath]) {
                path = [url substringFromIndex:rootPath.length];
            }else{
                path = [[NSURL URLWithString:url] path];
            }
            if (![path isEqualToString:@"/"]) {
                path = [path stringByDeletingLastPathComponent];
            }
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *filePath =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"page_cache%@", path]];
            if (![fileManager fileExistsAtPath:filePath]) {
                [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            NSString *fullPath = [filePath stringByAppendingPathComponent:[Config MD5ForLower32Bate:url]];
            NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (appboard.length > 0) {
                content = [NSString stringWithFormat:@"%@%@", appboard, content];
            }
            [content writeToFile:fullPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            //
            if (cache > 1000) {
                NSInteger time = [[NSDate date] timeIntervalSince1970] + cache * 1.0f / 1000;
                NSDictionary *saveDic = @{@"cache_url":fullPath, @"cache_time":@(time)};
                [[WeexSDKManager sharedIntstance].cacheData setObject:saveDic forKey:url];
            }
            //
            callback([NSString stringWithFormat:@"file://%@", fullPath]);
        }else{
            callback(nil);
        }
    }];
    [downloadTask resume];
}


// 时间戳—>字符串时间
+ (NSString *)timesFromString:(NSString *)timestamp {
    //时间戳转时间的方法
    NSDate *timeData = [NSDate dateWithTimeIntervalSince1970:[timestamp intValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strTime = [dateFormatter stringFromDate:timeData];
    return strTime;
}

//NSDictionary转NSString
+ (NSString*) dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

//NSString转NSDictionary
+ (NSDictionary*) dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    if ([jsonString isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *) jsonString;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return nil;
    }
    return dic;
}

//数组转换成json串
+ (NSString *)arrayToJson:(NSArray *)array
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];;
}

//判断颜色是不是亮色
+(BOOL) isLightColor:(UIColor*)clr {
    CGFloat components[3];
    [self getRGBComponents:components forColor:clr];
    EELog(@"%f %f %f", components[0], components[1], components[2]);
    CGFloat num = components[0] + components[1] + components[2];
    if(num < 382) {
        return NO;
    }else{
        return YES;
    }
}

//获取RGB值
+ (void)getRGBComponents:(CGFloat [3])components forColor:(UIColor *)color {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char resultingPixel[4];
    CGContextRef context = CGBitmapContextCreate(&resultingPixel, 1, 1, 8, 4, rgbColorSpace, bitmapInfo);
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    for (int component = 0; component < 3; component++) {
        components[component] = resultingPixel[component];
    }
}

+ (NSString *) webCommonStyle
{
    return @"body{background-color:#FFF;color:#000;font-family:Verdana,Arial,Helvetica,sans-serif;font-size:14px;line-height:1.3;scrollbar-3dlight-color:#F0F0EE;scrollbar-arrow-color:#676662;scrollbar-base-color:#F0F0EE;scrollbar-darkshadow-color:#DDD;scrollbar-face-color:#E0E0DD;scrollbar-highlight-color:#F0F0EE;scrollbar-shadow-color:#F0F0EE;scrollbar-track-color:#F5F5F5}td,th{font-family:Verdana,Arial,Helvetica,sans-serif;font-size:14px}.word-wrap{word-wrap:break-word;-ms-word-break:break-all;word-break:break-all;word-break:break-word;-ms-hyphens:auto;-moz-hyphens:auto;-webkit-hyphens:auto;hyphens:auto}.mce-content-body .mce-reset{margin:0;padding:0;border:0;outline:0;vertical-align:top;background:0 0;text-decoration:none;color:#000;font-family:Arial;font-size:11px;text-shadow:none;float:none;position:static;width:auto;height:auto;white-space:nowrap;cursor:inherit;line-height:normal;font-weight:400;text-align:left;-webkit-tap-highlight-color:transparent;-moz-box-sizing:content-box;-webkit-box-sizing:content-box;box-sizing:content-box;direction:ltr;max-width:none}.mce-object{border:1px dotted #3A3A3A;background:#D5D5D5 url(data:image/gif;base64,R0lGODlhEQANALMPAOXl5T8/P29vb7S0tFdXV/39/djY2N3d3crKyu/v7/f39/Ly8p2dnf///zMzMwAAACH5BAEAAA8ALAAAAAARAA0AAARF0MlJq3uutay75lmGNU9pjiNFCsipqhgxmO9HSgFTgtt9O4EBABWa3AiGwvBlfAgWisPOyCslDDSbSHTa+SzgpmdMbkQAADs=) no-repeat center}.mce-preview-object{display:inline-block;position:relative;margin:0 2px 0 2px;line-height:0;border:1px solid gray}.mce-preview-object[data-mce-selected=2] .mce-shim{display:none}.mce-preview-object .mce-shim{position:absolute;top:0;left:0;width:100%;height:100%;background:url(data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7)}figure.align-left{float:left}figure.align-right{float:right}figure.image.align-center{display:table;margin-left:auto;margin-right:auto}figure.image{display:inline-block;border:1px solid gray;margin:0 2px 0 1px;background:#f5f2f0}figure.image img{margin:8px 8px 0 8px}figure.image figcaption{margin:6px 8px 6px 8px;text-align:center}.mce-toc{border:1px solid gray}.mce-toc h2{margin:4px}.mce-toc li{list-style-type:none}.mce-pagebreak{cursor:default;display:block;border:0;width:100%;height:5px;border:1px dashed #666;margin-top:15px;page-break-before:always}@media print{.mce-pagebreak{border:0}}.mce-item-anchor{cursor:default;display:inline-block;-webkit-user-select:all;-webkit-user-modify:read-only;-moz-user-select:all;-moz-user-modify:read-only;user-select:all;user-modify:read-only;width:9px!important;height:9px!important;border:1px dotted #3A3A3A;background:#D5D5D5 url(data:image/gif;base64,R0lGODlhBwAHAIABAAAAAP///yH5BAEAAAEALAAAAAAHAAcAAAIMjGGJmMH9mHQ0AlYAADs=) no-repeat center}.mce-nbsp,.mce-shy{background:#AAA}.mce-shy::after{content:'-'}.mce-match-marker{background:#AAA;color:#fff}.mce-match-marker-selected{background:#39f;color:#fff}.mce-spellchecker-word{border-bottom:2px solid rgba(208,2,27,.5);cursor:default}.mce-spellchecker-grammar{border-bottom:2px solid green;cursor:default}.mce-item-table,.mce-item-table caption,.mce-item-table td,.mce-item-table th{border:1px dashed #BBB}td[data-mce-selected],th[data-mce-selected]{background-color:#2276d2!important}.mce-edit-focus{outline:1px dotted #333}.mce-content-body [contentEditable=false] [contentEditable=true]:focus{outline:2px solid #2276d2}.mce-content-body [contentEditable=false] [contentEditable=true]:hover{outline:2px solid #2276d2}.mce-content-body [contentEditable=false][data-mce-selected]{outline:2px solid #2276d2}.mce-content-body [data-mce-selected=inline-boundary]{background:#bfe6ff}.mce-content-body .mce-item-anchor[data-mce-selected]{background:#D5D5D5 url(data:image/gif;base64,R0lGODlhBwAHAIABAAAAAP///yH5BAEAAAEALAAAAAAHAAcAAAIMjGGJmMH9mHQ0AlYAADs=) no-repeat center}.mce-content-body hr{cursor:default}.mce-content-body table{-webkit-nbsp-mode:normal}.ephox-snooker-resizer-bar{background-color:#2276d2;opacity:0}.ephox-snooker-resizer-cols{cursor:col-resize}.ephox-snooker-resizer-rows{cursor:row-resize}.ephox-snooker-resizer-bar.ephox-snooker-resizer-bar-dragging{opacity:.2}";
}

static NSInteger isNotchedScreen = -1;
+ (BOOL)isNotchedScreen {
    if (@available(iOS 11, *)) {
        if (isNotchedScreen < 0) {
            if (@available(iOS 12.0, *)) {
                /*
                 检测方式解释/测试要点：
                 1. iOS 11 与 iOS 12 可能行为不同，所以要分别测试。
                 2. 与触发 [QMUIHelper isNotchedScreen] 方法时的进程有关，例如 https://github.com/Tencent/QMUI_iOS/issues/482#issuecomment-456051738 里提到的 [NSObject performSelectorOnMainThread:withObject:waitUntilDone:NO] 就会导致较多的异常。
                 3. iOS 12 下，在非第2点里提到的情况下，iPhone、iPad 均可通过 UIScreen -_peripheryInsets 方法的返回值区分，但如果满足了第2点，则 iPad 无法使用这个方法，这种情况下要依赖第4点。
                 4. iOS 12 下，不管是否满足第2点，不管是什么设备类型，均可以通过一个满屏的 UIWindow 的 rootViewController.view.frame.origin.y 的值来区分，如果是非全面屏，这个值必定为20，如果是全面屏，则可能是24或44等不同的值。但由于创建 UIWindow、UIViewController 等均属于较大消耗，所以只在前面的步骤无法区分的情况下才会使用第4点。
                 5. 对于第4点，经测试与当前设备的方向、是否有勾选 project 里的 General - Hide status bar、当前是否处于来电模式的状态栏这些都没关系。
                 */
                SEL peripheryInsetsSelector = NSSelectorFromString([NSString stringWithFormat:@"_%@%@", @"periphery", @"Insets"]);
                __block UIEdgeInsets peripheryInsets = UIEdgeInsetsZero;
                [self performSelector:peripheryInsetsSelector withPrimitiveReturnValue:&peripheryInsets arguments:nil];
                if (peripheryInsets.bottom <= 0) {
                    
                    if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(dispatch_get_main_queue())) == 0) {
                        //当前为主线程
                        UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
                        peripheryInsets = window.safeAreaInsets;
                        if (peripheryInsets.bottom <= 0) {
                            UIViewController *viewController = [UIViewController new];
                            window.rootViewController = viewController;
                            if (CGRectGetMinY(viewController.view.frame) > 20) {
                                peripheryInsets.bottom = 1;
                            }
                        }
                    }else{
                        dispatch_semaphore_t signal = dispatch_semaphore_create(0);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
                            peripheryInsets = window.safeAreaInsets;
                            if (peripheryInsets.bottom <= 0) {
                                UIViewController *viewController = [UIViewController new];
                                window.rootViewController = viewController;
                                if (CGRectGetMinY(viewController.view.frame) > 20) {
                                    peripheryInsets.bottom = 1;
                                }
                            }
                            
                            dispatch_semaphore_signal(signal);
                        });
                        dispatch_semaphore_wait(signal, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
                    }
                }
                isNotchedScreen = peripheryInsets.bottom > 0 ? 1 : 0;
            } else {
                isNotchedScreen = [self is58InchScreen] ? 1 : 0;
            }
        }
    } else {
        isNotchedScreen = 0;
    }
    
    return isNotchedScreen > 0;
}
+ (void)performSelector:(SEL)selector withPrimitiveReturnValue:(void *)returnValue arguments:(void *)firstArgument, ... {

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[UIScreen mainScreen] methodSignatureForSelector:selector]];
    [invocation setTarget:[UIScreen mainScreen]];
    [invocation setSelector:selector];
    
    if (firstArgument) {
        va_list valist;
        va_start(valist, firstArgument);
        [invocation setArgument:firstArgument atIndex:2];// 0->self, 1->_cmd
        
        void *currentArgument;
        NSInteger index = 3;
        while ((currentArgument = va_arg(valist, void *))) {
            [invocation setArgument:currentArgument atIndex:index];
            index++;
        }
        va_end(valist);
    }
    
    [invocation invoke];
    
    if (returnValue) {
        [invocation getReturnValue:returnValue];
    }
}

static NSInteger is58InchScreen = -1;
+ (BOOL)is58InchScreen {
    if (is58InchScreen < 0) {
        // Both iPhone XS and iPhone X share the same actual screen sizes, so no need to compare identifiers
        // iPhone XS 和 iPhone X 的物理尺寸是一致的，因此无需比较机器 Identifier
        is58InchScreen = (DEVICE_WIDTH == self.screenSizeFor58Inch.width && DEVICE_HEIGHT == self.screenSizeFor58Inch.height) ? 1 : 0;
    }
    return is58InchScreen > 0;
}
+ (CGSize)screenSizeFor58Inch {
    return CGSizeMake(375, 812);
}

// 获取安全区域高度（顶部和底部）
+ (NSDictionary *)getSafeAreaInsets {
    __block CGFloat topInset = 0;
    __block CGFloat bottomInset = 0;
    
    if (NSThread.isMainThread) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (@available(iOS 11.0, *)) {
            topInset = window.safeAreaInsets.top;
            bottomInset = window.safeAreaInsets.bottom;
        } else {
            // iOS 11以下，使用状态栏高度作为顶部高度
            topInset = [UIApplication sharedApplication].statusBarFrame.size.height;
        }
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindow *window = [UIApplication sharedApplication].keyWindow;
            if (@available(iOS 11.0, *)) {
                topInset = window.safeAreaInsets.top;
                bottomInset = window.safeAreaInsets.bottom;
            } else {
                // iOS 11以下，使用状态栏高度作为顶部高度
                topInset = [UIApplication sharedApplication].statusBarFrame.size.height;
            }
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    }
    
    // 获取屏幕尺寸
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    // 返回包含顶部、底部安全区域高度和屏幕尺寸的字典
    return @{
        @"top": @(topInset),
        @"bottom": @(bottomInset),
        @"width": @(screenSize.width),
        @"height": @(screenSize.height)
    };
}

+ (BOOL)isCurrentWindowFullscreen {
    __block BOOL isFullscreen = YES;
    
    void (^evaluateBlock)(void) = ^{
        UIWindow *window = eeuiActiveKeyWindow();
        if (window == nil) {
            isFullscreen = YES;
            return;
        }
        
        UIScreen *screen = window.screen ?: UIScreen.mainScreen;
        
        if (@available(iOS 13.0, *)) {
            UIWindowScene *windowScene = window.windowScene;
            if (windowScene != nil) {
                UIScreen *sceneScreen = windowScene.screen ?: screen;
                CGRect sceneBounds = windowScene.coordinateSpace.bounds;
                CGRect screenBounds = sceneScreen.coordinateSpace.bounds;
                isFullscreen = eeuiRectsAlmostEqual(sceneBounds, screenBounds);
                return;
            }
        }
        
        CGRect windowFrame = [window convertRect:window.bounds toCoordinateSpace:screen.coordinateSpace];
        CGRect screenBounds = screen.coordinateSpace.bounds;
        isFullscreen = eeuiRectsAlmostEqual(windowFrame, screenBounds);
    };
    
    if (NSThread.isMainThread) {
        evaluateBlock();
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            evaluateBlock();
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
    }
    
    return isFullscreen;
}

+ (NSString *)getDeviceModelName
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    
    // 设备型号对照表
    NSDictionary *deviceNamesByCode = @{
        // iPhone
        @"iPhone1,1": @"iPhone",
        @"iPhone1,2": @"iPhone 3G",
        @"iPhone2,1": @"iPhone 3GS",
        @"iPhone3,1": @"iPhone 4",
        @"iPhone3,2": @"iPhone 4",
        @"iPhone3,3": @"iPhone 4",
        @"iPhone4,1": @"iPhone 4S",
        @"iPhone5,1": @"iPhone 5",
        @"iPhone5,2": @"iPhone 5",
        @"iPhone5,3": @"iPhone 5c",
        @"iPhone5,4": @"iPhone 5c",
        @"iPhone6,1": @"iPhone 5s",
        @"iPhone6,2": @"iPhone 5s",
        @"iPhone7,1": @"iPhone 6 Plus",
        @"iPhone7,2": @"iPhone 6",
        @"iPhone8,1": @"iPhone 6s",
        @"iPhone8,2": @"iPhone 6s Plus",
        @"iPhone8,4": @"iPhone SE",
        @"iPhone9,1": @"iPhone 7",
        @"iPhone9,3": @"iPhone 7",
        @"iPhone9,2": @"iPhone 7 Plus",
        @"iPhone9,4": @"iPhone 7 Plus",
        @"iPhone10,1": @"iPhone 8",
        @"iPhone10,4": @"iPhone 8",
        @"iPhone10,2": @"iPhone 8 Plus",
        @"iPhone10,5": @"iPhone 8 Plus",
        @"iPhone10,3": @"iPhone X",
        @"iPhone10,6": @"iPhone X",
        @"iPhone11,2": @"iPhone XS",
        @"iPhone11,4": @"iPhone XS Max",
        @"iPhone11,6": @"iPhone XS Max",
        @"iPhone11,8": @"iPhone XR",
        @"iPhone12,1": @"iPhone 11",
        @"iPhone12,3": @"iPhone 11 Pro",
        @"iPhone12,5": @"iPhone 11 Pro Max",
        @"iPhone12,8": @"iPhone SE (2nd generation)",
        @"iPhone13,1": @"iPhone 12 mini",
        @"iPhone13,2": @"iPhone 12",
        @"iPhone13,3": @"iPhone 12 Pro",
        @"iPhone13,4": @"iPhone 12 Pro Max",
        @"iPhone14,2": @"iPhone 13 Pro",
        @"iPhone14,3": @"iPhone 13 Pro Max",
        @"iPhone14,4": @"iPhone 13 mini",
        @"iPhone14,5": @"iPhone 13",
        @"iPhone14,6": @"iPhone SE (3rd generation)",
        @"iPhone14,7": @"iPhone 14",
        @"iPhone14,8": @"iPhone 14 Plus",
        @"iPhone15,2": @"iPhone 14 Pro",
        @"iPhone15,3": @"iPhone 14 Pro Max",
        @"iPhone15,4": @"iPhone 15",
        @"iPhone15,5": @"iPhone 15 Plus",
        @"iPhone16,1": @"iPhone 15 Pro",
        @"iPhone16,2": @"iPhone 15 Pro Max",
        @"iPhone17,1": @"iPhone 16 Pro",
        @"iPhone17,2": @"iPhone 16 Pro Max",
        @"iPhone17,3": @"iPhone 16",
        @"iPhone17,4": @"iPhone 16 Plus",
        @"iPhone17,5": @"iPhone SE (4th generation)",
        @"iPhone18,1": @"iPhone 17 Pro",
        @"iPhone18,2": @"iPhone 17 Pro Max",
        @"iPhone18,3": @"iPhone 17",
        @"iPhone18,4": @"iPhone 17 Air",
        
        // iPod
        @"iPod1,1": @"iPod touch",
        @"iPod2,1": @"iPod touch (2nd generation)",
        @"iPod3,1": @"iPod touch (3rd generation)",
        @"iPod4,1": @"iPod touch (4th generation)",
        @"iPod5,1": @"iPod touch (5th generation)",
        @"iPod7,1": @"iPod touch (6th generation)",
        @"iPod9,1": @"iPod touch (7th generation)",
        
        // iPad
        @"iPad1,1": @"iPad",
        @"iPad2,1": @"iPad 2",
        @"iPad2,2": @"iPad 2",
        @"iPad2,3": @"iPad 2",
        @"iPad2,4": @"iPad 2",
        @"iPad2,5": @"iPad mini",
        @"iPad2,6": @"iPad mini",
        @"iPad2,7": @"iPad mini",
        @"iPad3,1": @"iPad 3",
        @"iPad3,2": @"iPad 3",
        @"iPad3,3": @"iPad 3",
        @"iPad3,4": @"iPad 4",
        @"iPad3,5": @"iPad 4",
        @"iPad3,6": @"iPad 4",
        @"iPad4,1": @"iPad Air",
        @"iPad4,2": @"iPad Air",
        @"iPad4,3": @"iPad Air",
        @"iPad4,4": @"iPad mini 2",
        @"iPad4,5": @"iPad mini 2",
        @"iPad4,6": @"iPad mini 2",
        @"iPad4,7": @"iPad mini 3",
        @"iPad4,8": @"iPad mini 3",
        @"iPad4,9": @"iPad mini 3",
        @"iPad5,1": @"iPad mini 4",
        @"iPad5,2": @"iPad mini 4",
        @"iPad5,3": @"iPad Air 2",
        @"iPad5,4": @"iPad Air 2",
        @"iPad6,3": @"iPad Pro (9.7-inch)",
        @"iPad6,4": @"iPad Pro (9.7-inch)",
        @"iPad6,7": @"iPad Pro (12.9-inch)",
        @"iPad6,8": @"iPad Pro (12.9-inch)",
        @"iPad6,11": @"iPad (5th generation)",
        @"iPad6,12": @"iPad (5th generation)",
        @"iPad7,1": @"iPad Pro (12.9-inch) (2nd generation)",
        @"iPad7,2": @"iPad Pro (12.9-inch) (2nd generation)",
        @"iPad7,3": @"iPad Pro (10.5-inch)",
        @"iPad7,4": @"iPad Pro (10.5-inch)",
        @"iPad7,5": @"iPad (6th generation)",
        @"iPad7,6": @"iPad (6th generation)",
        @"iPad7,11": @"iPad (7th generation)",
        @"iPad7,12": @"iPad (7th generation)",
        @"iPad8,1": @"iPad Pro (11-inch)",
        @"iPad8,2": @"iPad Pro (11-inch)",
        @"iPad8,3": @"iPad Pro (11-inch)",
        @"iPad8,4": @"iPad Pro (11-inch)",
        @"iPad8,5": @"iPad Pro (12.9-inch) (3rd generation)",
        @"iPad8,6": @"iPad Pro (12.9-inch) (3rd generation)",
        @"iPad8,7": @"iPad Pro (12.9-inch) (3rd generation)",
        @"iPad8,8": @"iPad Pro (12.9-inch) (3rd generation)",
        @"iPad8,9": @"iPad Pro (11-inch) (2nd generation)",
        @"iPad8,10": @"iPad Pro (11-inch) (2nd generation)",
        @"iPad8,11": @"iPad Pro (12.9-inch) (4th generation)",
        @"iPad8,12": @"iPad Pro (12.9-inch) (4th generation)",
        @"iPad11,1": @"iPad mini (5th generation)",
        @"iPad11,2": @"iPad mini (5th generation)",
        @"iPad11,3": @"iPad Air (3rd generation)",
        @"iPad11,4": @"iPad Air (3rd generation)",
        @"iPad11,6": @"iPad (8th generation)",
        @"iPad11,7": @"iPad (8th generation)",
        @"iPad12,1": @"iPad (9th generation)",
        @"iPad12,2": @"iPad (9th generation)",
        @"iPad13,1": @"iPad Air (4th generation)",
        @"iPad13,2": @"iPad Air (4th generation)",
        @"iPad13,4": @"iPad Pro (11-inch) (3rd generation)",
        @"iPad13,5": @"iPad Pro (11-inch) (3rd generation)",
        @"iPad13,6": @"iPad Pro (11-inch) (3rd generation)",
        @"iPad13,7": @"iPad Pro (11-inch) (3rd generation)",
        @"iPad13,8": @"iPad Pro (12.9-inch) (5th generation)",
        @"iPad13,9": @"iPad Pro (12.9-inch) (5th generation)",
        @"iPad13,10": @"iPad Pro (12.9-inch) (5th generation)",
        @"iPad13,11": @"iPad Pro (12.9-inch) (5th generation)",
        @"iPad13,16": @"iPad Air (5th generation)",
        @"iPad13,17": @"iPad Air (5th generation)",
        @"iPad13,18": @"iPad (10th generation)",
        @"iPad13,19": @"iPad (10th generation)",
        @"iPad14,1": @"iPad mini (6th generation)",
        @"iPad14,2": @"iPad mini (6th generation)",
        @"iPad14,3": @"iPad Pro (11-inch) (4th generation)",
        @"iPad14,4": @"iPad Pro (11-inch) (4th generation)",
        @"iPad14,5": @"iPad Pro (12.9-inch) (6th generation)",
        @"iPad14,6": @"iPad Pro (12.9-inch) (6th generation)",
        @"iPad14,8": @"iPad Air (11-inch) (M2)",
        @"iPad14,9": @"iPad Air (11-inch) (M2)",
        @"iPad14,10": @"iPad Air (13-inch) (M2)",
        @"iPad14,11": @"iPad Air (13-inch) (M2)",
        @"iPad15,3": @"iPad Air (11-inch) (M3)",
        @"iPad15,4": @"iPad Air (11-inch) (M3)",
        @"iPad15,5": @"iPad Air (13-inch) (M3)",
        @"iPad15,6": @"iPad Air (13-inch) (M3)",
        @"iPad15,7": @"iPad (A16)",
        @"iPad15,8": @"iPad (A16)",
        @"iPad16,1": @"iPad mini (A17 Pro)",
        @"iPad16,2": @"iPad mini (A17 Pro)",
        @"iPad16,3": @"iPad Pro (11-inch) (M4)",
        @"iPad16,4": @"iPad Pro (11-inch) (M4)",
        @"iPad16,5": @"iPad Pro (13-inch) (M4)",
        @"iPad16,6": @"iPad Pro (13-inch) (M4)",
        @"iPad17,1": @"iPad Pro (11-inch) (M5)",
        @"iPad17,2": @"iPad Pro (11-inch) (M5)",
        @"iPad17,3": @"iPad Pro (13-inch) (M5)",
        @"iPad17,4": @"iPad Pro (13-inch) (M5)",
        
        // Apple TV
        @"AppleTV5,3": @"Apple TV HD",
        @"AppleTV6,2": @"Apple TV 4K",
        @"AppleTV11,1": @"Apple TV 4K (2nd generation)",
        @"AppleTV14,1": @"Apple TV 4K (3rd generation)",
        
        // Apple Watch
        @"Watch1,1": @"Apple Watch (1st generation) 38mm",
        @"Watch1,2": @"Apple Watch (1st generation) 42mm",
        @"Watch2,3": @"Apple Watch Series 2 38mm",
        @"Watch2,4": @"Apple Watch Series 2 42mm",
        @"Watch2,6": @"Apple Watch Series 1 38mm",
        @"Watch2,7": @"Apple Watch Series 1 42mm",
        @"Watch3,1": @"Apple Watch Series 3 38mm",
        @"Watch3,2": @"Apple Watch Series 3 42mm",
        @"Watch3,3": @"Apple Watch Series 3 38mm",
        @"Watch3,4": @"Apple Watch Series 3 42mm",
        @"Watch4,1": @"Apple Watch Series 4 40mm",
        @"Watch4,2": @"Apple Watch Series 4 44mm",
        @"Watch4,3": @"Apple Watch Series 4 40mm",
        @"Watch4,4": @"Apple Watch Series 4 44mm",
        @"Watch5,1": @"Apple Watch Series 5 40mm",
        @"Watch5,2": @"Apple Watch Series 5 44mm",
        @"Watch5,3": @"Apple Watch Series 5 40mm",
        @"Watch5,4": @"Apple Watch Series 5 44mm",
        @"Watch5,9": @"Apple Watch SE 40mm",
        @"Watch5,10": @"Apple Watch SE 44mm",
        @"Watch5,11": @"Apple Watch SE 40mm",
        @"Watch5,12": @"Apple Watch SE 44mm",
        @"Watch6,1": @"Apple Watch Series 6 40mm",
        @"Watch6,2": @"Apple Watch Series 6 44mm",
        @"Watch6,3": @"Apple Watch Series 6 40mm",
        @"Watch6,4": @"Apple Watch Series 6 44mm",
        @"Watch6,6": @"Apple Watch Series 7 41mm",
        @"Watch6,7": @"Apple Watch Series 7 45mm",
        @"Watch6,8": @"Apple Watch Series 7 41mm",
        @"Watch6,9": @"Apple Watch Series 7 45mm",
        @"Watch6,10": @"Apple Watch SE (2nd generation) 40mm",
        @"Watch6,11": @"Apple Watch SE (2nd generation) 44mm",
        @"Watch6,12": @"Apple Watch SE (2nd generation) 40mm",
        @"Watch6,13": @"Apple Watch SE (2nd generation) 44mm",
        @"Watch6,14": @"Apple Watch Series 8 41mm",
        @"Watch6,15": @"Apple Watch Series 8 45mm",
        @"Watch6,16": @"Apple Watch Series 8 41mm",
        @"Watch6,17": @"Apple Watch Series 8 45mm",
        @"Watch6,18": @"Apple Watch Ultra",
        @"Watch7,3": @"Apple Watch Series 9 41mm",
        @"Watch7,4": @"Apple Watch Series 9 45mm",
        @"Watch7,5": @"Apple Watch Ultra 2",
        @"Watch7,8": @"Apple Watch Series 10 42mm",
        @"Watch7,9": @"Apple Watch Series 10 46mm",
        @"Watch7,10": @"Apple Watch Series 10 42mm",
        @"Watch7,11": @"Apple Watch Series 10 46mm",
        @"Watch8,1": @"Apple Watch Ultra 3 (49mm)",
        @"Watch8,2": @"Apple Watch Ultra 3 (49mm)",
        
        // HomePod
        @"AudioAccessory1,1": @"HomePod",
        @"AudioAccessory1,2": @"HomePod mini",
        @"AudioAccessory5,1": @"HomePod (2nd generation)",
        @"AudioAccessory6,1": @"HomePod mini (2nd generation)",
        
        // 模拟器
        @"i386": @"iPhone Simulator",
        @"x86_64": @"iPhone Simulator",
        @"arm64": @"iPhone Simulator"
    };
    
    NSString *deviceName = deviceNamesByCode[platform];
    
    if (!deviceName) {
        // 未知设备，返回平台名称
        deviceName = platform;
    }
    
    return deviceName;
}

@end
