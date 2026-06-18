#import "WPLRegister.h"

#import <WeexSDK/WXSDKEngine.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>

@implementation WPRegister

+ (void)registerPlugins
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (uint32_t imageIndex = 0; imageIndex < _dyld_image_count(); imageIndex++) {
            [self registerPluginsInImageAtIndex:imageIndex];
        }
    });
}

+ (void)registerPluginsInImageAtIndex:(uint32_t)imageIndex
{
    unsigned long byteCount = 0;
#if defined(__LP64__)
    const struct mach_header_64 *header = (const struct mach_header_64 *)_dyld_get_image_header(imageIndex);
    const uint64_t *entries = (const uint64_t *)getsectiondata(header, "__DATA", "WeexPlugin", &byteCount);
#else
    const struct mach_header *header = _dyld_get_image_header(imageIndex);
    const uint32_t *entries = (const uint32_t *)getsectiondata(header, "__DATA", "WeexPlugin", &byteCount);
#endif
    if (entries == NULL || byteCount == 0) {
        return;
    }

    NSUInteger count = byteCount / sizeof(void *);
    for (NSUInteger index = 0; index < count; index++) {
        const char *entry = (const char *)entries[index];
        if (entry == NULL) {
            continue;
        }

        NSString *configuration = [NSString stringWithUTF8String:entry];
        NSArray<NSString *> *parts = [configuration componentsSeparatedByString:@"&"];
        if (parts.count != 3) {
            continue;
        }

        NSString *type = parts[0];
        NSString *jsName = parts[1];
        NSString *className = parts[2];
        Class clazz = NSClassFromString(className);
        if ([type isEqualToString:@"module"] && clazz != Nil) {
            [WXSDKEngine registerModule:jsName withClass:clazz];
        } else if ([type isEqualToString:@"component"] && clazz != Nil) {
            [WXSDKEngine registerComponent:jsName withClass:clazz];
        } else if ([type isEqualToString:@"protocol"] && clazz != Nil) {
            Protocol *protocol = NSProtocolFromString(jsName);
            if (protocol != nil) {
                [WXSDKEngine registerHandler:[[clazz alloc] init] withProtocol:protocol];
            }
        }
    }
}

@end
