#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LocationCompletion)(CLLocation * _Nullable location, NSError * _Nullable error);

@interface eeuiLocationManager : NSObject

+ (instancetype)shared;

// 获取位置（包含权限请求）
- (void)requestLocationWithCompletion:(LocationCompletion)completion;

// 检查是否有定位权限
- (BOOL)hasLocationPermission;

@end

NS_ASSUME_NONNULL_END
