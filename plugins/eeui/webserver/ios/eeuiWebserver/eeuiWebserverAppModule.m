//
//  eeuiWebserverAppModule.m
//  Pods
//

#import "eeuiWebserverAppModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

// 使用静态变量保存webServer，避免app重启时丢失
static GCDWebServer *sharedWebServer = nil;

@interface eeuiWebserverAppModule ()

@end

@implementation eeuiWebserverAppModule

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(eeuiWebserver, eeuiWebserverAppModule)
WX_EXPORT_METHOD(@selector(startWebServer:port:callback:))
WX_EXPORT_METHOD(@selector(stopWebServer:))
WX_EXPORT_METHOD(@selector(getServerStatus:))
WX_EXPORT_METHOD(@selector(getLocalIPAddress:))

//启动本地HTTP服务器
- (void)startWebServer:(NSString*)directoryPath port:(id)port callback:(WXModuleKeepAliveCallback)callback
{
    // 去掉 "file://" 前缀
    if ([directoryPath hasPrefix:@"file://"]) {
        directoryPath = [directoryPath substringFromIndex:7];
    }

    // 转换端口号
    NSUInteger portNumber = [WXConvert NSInteger:port];

    // 检查是否已有运行的服务器
    if (sharedWebServer) {
        @try {
            if ([sharedWebServer isRunning]) {
                // 服务器已存在，返回已存在状态和服务信息
                NSString *serverURL = sharedWebServer.serverURL.absoluteString;
                NSUInteger port = sharedWebServer.port;
                
                if (callback != nil) {
                    callback(@{
                        @"status": @"exists",
                        @"message": @"服务器已存在",
                        @"url": serverURL,
                        @"port": @(port)
                    }, NO);
                }
                return;
            }
        } @catch (NSException *exception) {
            NSLog(@"检查旧服务器时出错: %@", exception);
            sharedWebServer = nil;
        }
    }
    
    // 检查目录是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory) {
        if (callback != nil) {
            callback(@{
                @"status": @"error",
                @"message": @"指定的目录不存在或不是有效目录"
            }, NO);
        }
        return;
    }
    
    // 创建并配置WebServer
    sharedWebServer = [[GCDWebServer alloc] init];
    
    // 添加目录处理器
    [sharedWebServer addGETHandlerForBasePath:@"/"
                               directoryPath:directoryPath
                               indexFilename:@"index.html"
                                    cacheAge:3600
                          allowRangeRequests:YES];
    
    // 添加Keep-Alive心跳接口
    [sharedWebServer addHandlerForMethod:@"GET"
                                   path:@"/__keepalive__"
                           requestClass:[GCDWebServerRequest class]
                           processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSDictionary* response = @{
            @"status": @"alive",
            @"timestamp": @([[NSDate date] timeIntervalSince1970])
        };
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
    }];
    
    // 尝试启动服务器
    BOOL success = [sharedWebServer startWithPort:portNumber bonjourName:nil];
    
    if (success) {
        NSString *serverURL = sharedWebServer.serverURL.absoluteString;
        NSUInteger port = sharedWebServer.port;
        
        if (callback != nil) {
            callback(@{
                @"status": @"success",
                @"message": @"服务器启动成功",
                @"url": serverURL,
                @"port": @(port)
            }, NO);
        }
    } else {
        if (callback != nil) {
            callback(@{
                @"status": @"error",
                @"message": @"启动服务器失败，端口可能被占用"
            }, NO);
        }
    }
}


//停止HTTP服务器
- (void)stopWebServer:(WXModuleKeepAliveCallback)callback
{
    BOOL wasRunning = NO;
    
    if (sharedWebServer) {
        @try {
            wasRunning = [sharedWebServer isRunning];
            if (wasRunning) {
                [sharedWebServer stop];
            }
        } @catch (NSException *exception) {
            NSLog(@"停止服务器时出错: %@", exception);
        }
        sharedWebServer = nil;
    }

    if (callback == nil) {
        return;
    }
    
    if (wasRunning) {
        callback(@{
            @"status": @"success",
            @"message": @"服务器已停止"
        }, NO);
    } else {
        callback(@{
            @"status": @"error",
            @"message": @"服务器未运行"
        }, NO);
    }
}

//获取服务器状态
- (void)getServerStatus:(WXModuleKeepAliveCallback)callback
{
    BOOL isRunning = NO;
    NSString *serverURL = nil;
    NSUInteger port = 0;
    
    if (sharedWebServer) {
        @try {
            isRunning = [sharedWebServer isRunning];
            if (isRunning) {
                serverURL = sharedWebServer.serverURL.absoluteString;
                port = sharedWebServer.port;
            }
        } @catch (NSException *exception) {
            NSLog(@"获取服务器状态时出错: %@", exception);
            isRunning = NO;
        }
    }

    if (callback == nil) {
        return;
    }
    
    if (isRunning && serverURL) {
        callback(@{
            @"status": @"success",
            @"message": @"服务器正在运行",
            @"url": serverURL,
            @"port": @(port)
        }, NO);
    } else {
        callback(@{
            @"status": @"error",
            @"message": @"服务器未运行"
        }, NO);
    }
}

//获取本地IP地址
- (void) getLocalIPAddress:(WXModuleKeepAliveCallback)callback
{
    if (callback == nil) {
        return;
    }

    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // 获取当前所有的网络接口信息
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // 检查是否为IPv4地址
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // WiFi连接
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    break;
                } else if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"]) {
                    // 蜂窝网络连接
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    
    if (address == nil || address.length == 0) {
        callback(@{
            @"status": @"error",
            @"message": @"获取本地IP地址失败"
        }, NO);
    } else {
        callback(@{
            @"status": @"success",
            @"message": @"获取本地IP地址成功",
            @"ip": address
        }, NO);
    }
}

@end
