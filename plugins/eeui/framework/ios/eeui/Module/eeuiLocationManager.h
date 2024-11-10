#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LocationCompletion)(CLLocation * _Nullable location, NSError * _Nullable error);
typedef void(^AuthorizationCompletion)(BOOL hasPermission);

@interface eeuiLocationManager : NSObject

+ (instancetype)shared;

// 获取位置（包含权限请求）
- (void)requestLocationWithCompletion:(LocationCompletion)completion;

// 异步检查定位权限
- (void)checkLocationPermission:(AuthorizationCompletion)completion;

@end

NS_ASSUME_NONNULL_END
