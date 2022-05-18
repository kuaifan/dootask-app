//
//  eeuiUmengPushModule.m
//

#import "eeuiUmengPushModule.h"
#import "eeuiUmengManager.h"
#import <UMCommon/MobClick.h>
#import <WeexPluginLoader/WeexPluginLoader.h>

@implementation eeuiUmengPushModule

WX_PlUGIN_EXPORT_MODULE(eeuiUmengPush, eeuiUmengPushModule)
WX_EXPORT_METHOD_SYNC(@selector(deviceToken))
WX_EXPORT_METHOD(@selector(setDisplayNotificationNumber:))  //仅android
WX_EXPORT_METHOD(@selector(setNotificaitonOnForeground:))   //仅android
WX_EXPORT_METHOD(@selector(disable:)) //仅android
WX_EXPORT_METHOD(@selector(enable:)) //仅android
WX_EXPORT_METHOD(@selector(addTag:response:))
WX_EXPORT_METHOD(@selector(deleteTag:response:))
WX_EXPORT_METHOD(@selector(listTag:))
WX_EXPORT_METHOD(@selector(addAlias:type:response:))
WX_EXPORT_METHOD(@selector(addExclusiveAlias:type:response:))
WX_EXPORT_METHOD(@selector(deleteAlias:type:response:))

- (NSDictionary*)deviceToken
{
    return [[eeuiUmengManager sharedIntstance] token];
}

- (void) setDisplayNotificationNumber:(WXModuleCallback)completion
{

}

- (void) setNotificaitonOnForeground:(WXModuleCallback)completion
{

}

- (void) disable:(WXModuleCallback)completion
{

}

- (void) enable:(WXModuleCallback)completion
{

}

- (void) addTag:(NSString *)tag response:(WXModuleCallback)completion
{
    [UMessage addTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
        [self handleResponse:responseObject remain:remain error:error completion:completion];
    }];
}

- (void) deleteTag:(NSString *)tag response:(WXModuleCallback)completion
{
    [UMessage deleteTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
        [self handleResponse:responseObject remain:remain error:error completion:completion];
    }];
}

- (void) listTag:(WXModuleCallback)completion
{
    [UMessage getTags:^(NSSet * _Nonnull responseTags, NSInteger remain, NSError * _Nonnull error) {
        [self handleGetTagResponse:responseTags remain:remain error:error completion:completion];
    }];
}

- (void) addAlias:(NSString *)name type:(NSString *)type response:(WXModuleCallback)completion
{
    [UMessage addAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
        [self handleAliasResponse:responseObject error:error completion:completion];
    }];
}

- (void) addExclusiveAlias:(NSString *)name type:(NSString *)type response:(WXModuleCallback)completion
{
    [UMessage setAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
        [self handleAliasResponse:responseObject error:error completion:completion];
    }];
}

- (void) deleteAlias:(NSString *)name type:(NSString *)type response:(WXModuleCallback)completion
{
    [UMessage removeAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
        [self handleAliasResponse:responseObject error:error completion:completion];
    }];
}

- (NSString *)checkErrorMessage:(NSInteger)code
{
    switch (code) {
        case 1:
            return @"响应出错";
            break;
        case 2:
            return @"操作失败";
            break;
        case 3:
            return @"参数非法";
            break;
        case 4:
            return @"条件不足(如:还未获取device_token，添加tag是不成功的)";
            break;
        case 5:
            return @"服务器限定操作";
            break;
        default:
            break;
    }
    return nil;
}

- (void)handleResponse:(id  _Nonnull)responseObject remain:(NSInteger)remain error:(NSError * _Nonnull)error completion:(WXModuleCallback)completion
{
    if (completion) {
        if (error) {
            NSString *msg = [self checkErrorMessage:error.code];
            if (msg.length == 0) {
                msg = error.localizedDescription;
            }
            completion(@{
                    @"status": @"error",
                    @"remain": @(remain),
                    @"code": @(error.code)
            });
        } else {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *retDict = responseObject;
                if ([retDict[@"success"] isEqualToString:@"ok"]) {
                    completion(@{
                            @"status": @"success",
                            @"remain": @(remain),
                            @"code": @200
                    });
                } else {
                    completion(@{
                            @"status": @"error",
                            @"remain": @(remain),
                            @"code": @-1
                    });
                }
            } else {
                completion(@{
                        @"status": @"error",
                        @"remain": @(remain),
                        @"code": @-1
                });
            }
        }
    }
}

- (void)handleGetTagResponse:(NSSet * _Nonnull)responseTags remain:(NSInteger)remain error:(NSError * _Nonnull)error completion:(WXModuleCallback)completion
{
    if (completion) {
        if (error) {
            NSString *msg = [self checkErrorMessage:error.code];
            if (msg.length == 0) {
                msg = error.localizedDescription;
            }
            completion(@{
                    @"status": @"error",
                    @"remain": @(remain),
                    @"lists": @[]
            });
        } else {
            if ([responseTags isKindOfClass:[NSSet class]]) {
                NSArray *retList = responseTags.allObjects;
                completion(@{
                        @"status": @"success",
                        @"remain": @(remain),
                        @"lists": retList
                });
            } else {
                completion(@{
                        @"status": @"error",
                        @"remain": @(remain),
                        @"lists": @[]
                });
            }
        }
    }
}

- (void)handleAliasResponse:(id  _Nonnull)responseObject error:(NSError * _Nonnull)error completion:(WXModuleCallback)completion
{
    if (completion) {
        if (error) {
            NSString *msg = [self checkErrorMessage:error.code];
            if (msg.length == 0) {
                msg = error.localizedDescription;
            }
            completion(@{
                    @"status": @"error",
                    @"code": @(error.code),
            });
        } else {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *retDict = responseObject;
                if ([retDict[@"success"] isEqualToString:@"ok"]) {
                    completion(@{
                            @"status": @"success",
                            @"code": @200,
                    });
                } else {
                    completion(@{
                            @"status": @"error",
                            @"code": @-1,
                    });
                }
            } else {
                completion(@{
                        @"status": @"error",
                        @"code": @-1,
                });
            }
        }
    }
}

@end
