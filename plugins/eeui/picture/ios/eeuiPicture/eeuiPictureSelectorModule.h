#import <Foundation/Foundation.h>
#import "WeexSDK.h"

@interface eeuiPictureSelectorModule : NSObject <WXModuleProtocol>

- (void)create:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback;
- (void)compressImage:(NSDictionary*)params callback:(WXModuleKeepAliveCallback)callback;
- (void)picturePreview:(NSInteger)index paths:(NSArray*)paths callback:(WXModuleKeepAliveCallback)callback;
- (void)videoPreview:(NSString*)path;
- (void)deleteCache;

@end
