//
//  eeuiPictureBridge.m
//  eeuiApp
//
//  Created by 高一 on 2019/1/6.
//

#import "eeuiPictureBridge.h"
#import "eeuiPictureSelectorModule.h"

@interface eeuiPictureBridge ()

@property (nonatomic, strong) eeuiPictureSelectorModule *picture;

@end

@implementation eeuiPictureBridge

- (void)initialize
{
    if (self.picture == nil) {
        self.picture = [[eeuiPictureSelectorModule alloc] init];
    }
}

- (void)create:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback
{
    [self.picture create:params callback:callback];
}

- (void)compressImage:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback
{
    [self.picture compressImage:params callback:callback];
}

- (void)picturePreview:(NSInteger)index paths:(NSArray*)paths callback:(WXModuleKeepAliveCallback)callback
{
    [self.picture picturePreview:index paths:paths callback:callback];
}

- (void)videoPreview:(NSString*)path
{
    [self.picture videoPreview:path];
}

- (void)deleteCache
{
    [self.picture deleteCache];
}

@end
