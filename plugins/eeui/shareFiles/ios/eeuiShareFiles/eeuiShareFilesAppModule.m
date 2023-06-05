//
//  eeuiShareFilesAppModule.m
//  Pods
//

#import "eeuiShareFilesAppModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <MMWormhole.h>

@interface eeuiShareFilesAppModule ()

@property (nonatomic, strong)MMWormhole *shareWormhole;

@end

@implementation eeuiShareFilesAppModule

WX_PlUGIN_EXPORT_MODULE(eeuiShareFiles, eeuiShareFilesAppModule)

WX_EXPORT_METHOD(@selector(setShareStorage:value:))
WX_EXPORT_METHOD(@selector(shareFileWithGroupID:subPath:))
WX_EXPORT_METHOD_SYNC(@selector(getShareStorage:callback:))


- (void)shareFileWithGroupID:(NSString *)GroupID subPath:(NSString *)subPath{
    NSLog(@"initShare:%@====%@",GroupID,subPath);
    self.shareWormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier:GroupID optionalDirectory:subPath];
}

- (void)setShareStorage:(NSString *)key value:(id)value {
    NSLog(@"setShare:%@====%@",key,value);
    [self.shareWormhole passMessageObject:value identifier:key];
}

- (void)getShareStorage:(NSString *)key callback:(WXModuleCallback)callback {
    id result = [self.shareWormhole messageWithIdentifier:key];
    NSLog(@"getShare:%@",result);
    if(!result) {
        result = @"";
    }
    
    callback?callback(result):nil;
}


@end
