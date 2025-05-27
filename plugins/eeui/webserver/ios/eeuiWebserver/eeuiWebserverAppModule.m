//
//  eeuiWebserverAppModule.m
//  Pods
//

#import "eeuiWebserverAppModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface eeuiWebserverAppModule ()

@end

@implementation eeuiWebserverAppModule

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(eeuiWebserver, eeuiWebserverAppModule)
WX_EXPORT_METHOD(@selector(startWebServer:port:callback:))
WX_EXPORT_METHOD(@selector(stopWebServer:))
WX_EXPORT_METHOD(@selector(getServerStatus:))

//启动本地HTTP服务器
- (void)startWebServer:(NSString*)directoryPath port:(id)port callback:(WXModuleKeepAliveCallback)callback
{
    // 去掉 "file://" 前缀
    if ([directoryPath hasPrefix:@"file://"]) {
        directoryPath = [directoryPath substringFromIndex:7];
    }

    // 转换端口号
    NSUInteger portNumber = [WXConvert NSInteger:port];

    // 检查服务器是否已经在运行
    if (self.webServer && self.webServer.isRunning) {
        if (callback != nil) {
            callback(@{
                @"success": @NO,
                @"message": @"服务器已经在运行中"
            }, NO);
        }
        return;
    }
    
    // 检查目录是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (![fileManager fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory) {
        if (callback != nil) {
            callback(@{
                @"success": @NO,
                @"message": @"指定的目录不存在或不是有效目录"
            }, NO);
        }
        return;
    }
    
    // 创建并配置WebServer
    self.webServer = [[GCDWebServer alloc] init];
    
    // 添加目录处理器
    [self.webServer addGETHandlerForBasePath:@"/"
                               directoryPath:directoryPath
                               indexFilename:@"index.html"
                                    cacheAge:3600
                          allowRangeRequests:YES];
    
    // 添加Keep-Alive心跳接口
    [self.webServer addHandlerForMethod:@"GET"
                                   path:@"/_keepalive"
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
    BOOL success = [self.webServer startWithPort:portNumber bonjourName:nil];
    
    if (success) {
        NSString *serverURL = self.webServer.serverURL.absoluteString;
        NSString *localIP = [self getLocalIPAddress];
        NSUInteger port = self.webServer.port;
        
        if (callback != nil) {
            callback(@{
                @"success": @YES,
                @"message": @"服务器启动成功",
                @"url": serverURL,
                @"ip": localIP ?: @"",
                @"port": @(port),
                @"keepaliveUrl": [NSString stringWithFormat:@"%@_keepalive", serverURL]
            }, NO);
        }
    } else {
        if (callback != nil) {
            callback(@{
                @"success": @NO,
                @"message": @"启动服务器失败，端口可能被占用"
            }, NO);
        }
    }
}


//停止HTTP服务器
- (void)stopWebServer:(WXModuleKeepAliveCallback)callback
{
    if (self.webServer && self.webServer.isRunning) {
        [self.webServer stop];
        self.webServer = nil;
        
        if (callback != nil) {
            callback(@{
                @"success": @YES,
                @"message": @"服务器已停止"
            }, NO);
        }
    } else {
        if (callback != nil) {
            callback(@{
                @"success": @NO,
                @"message": @"服务器未运行"
            }, NO);
        }
    }
}

//获取服务器状态
- (void)getServerStatus:(WXModuleKeepAliveCallback)callback
{
    if (self.webServer && self.webServer.isRunning) {
        NSString *serverURL = self.webServer.serverURL.absoluteString;
        NSString *localIP = [self getLocalIPAddress];
        NSUInteger port = self.webServer.port;
        
        if (callback != nil) {
            callback(@{
                @"isRunning": @YES,
                @"url": serverURL,
                @"ip": localIP ?: @"",
                @"port": @(port)
            }, NO);
        }
    } else {
        if (callback != nil) {
            callback(@{
                @"isRunning": @NO
            }, NO);
        }
    }
}

//获取本地IP地址
- (NSString*)getLocalIPAddress
{
    NSString *address = @"error";
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
    return address;
}

@end
