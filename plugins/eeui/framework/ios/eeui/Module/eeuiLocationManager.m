#import "eeuiLocationManager.h"

@interface eeuiLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) LocationCompletion locationCompletion;
@property (nonatomic, copy) AuthorizationCompletion authorizationCompletion;
@property (nonatomic, assign) BOOL isRequestingLocation;
@property (nonatomic, assign) BOOL isWaitingForPermission;

@end

@implementation eeuiLocationManager

+ (instancetype)shared {
    static eeuiLocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[eeuiLocationManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.isRequestingLocation = NO;
        self.isWaitingForPermission = NO;
    }
    return self;
}

- (void)requestLocationWithCompletion:(LocationCompletion)completion {
    self.locationCompletion = completion;
    self.isWaitingForPermission = YES;
    
    // 直接请求权限，在回调中处理
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)checkLocationPermission:(AuthorizationCompletion)completion {
    self.authorizationCompletion = completion;
    
    // 触发权限状态检查
    if (@available(iOS 14.0, *)) {
        [self handleAuthorizationStatus:self.locationManager.authorizationStatus];
    } else {
        [self locationManager:self.locationManager
            didChangeAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

- (void)startUpdatingLocation {
    self.isRequestingLocation = YES;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
// iOS 14及以上版本使用此方法
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    if (@available(iOS 14.0, *)) {
        [self handleAuthorizationStatus:manager.authorizationStatus];
    }
}

// iOS 14以下版本使用此方法
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self handleAuthorizationStatus:status];
}

- (void)handleAuthorizationStatus:(CLAuthorizationStatus)status {
    // 如果只是检查权限
    if (!self.isWaitingForPermission) {
        BOOL hasPermission = (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                             status == kCLAuthorizationStatusAuthorizedAlways);
        if (self.authorizationCompletion) {
            self.authorizationCompletion(hasPermission);
            self.authorizationCompletion = nil;
        }
        return;
    }
    
    // 处理定位请求
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 在后台线程检查定位服务状态
        if (![CLLocationManager locationServicesEnabled]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.locationCompletion) {
                    NSError *error = [NSError errorWithDomain:@"LocationError"
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey: @"UNAVAILABLE"}];
                    self.locationCompletion(nil, error);
                    self.isWaitingForPermission = NO;
                }
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case kCLAuthorizationStatusNotDetermined:
                    // 等待用户授权
                    break;
                    
                case kCLAuthorizationStatusAuthorizedWhenInUse:
                case kCLAuthorizationStatusAuthorizedAlways:
                    [self startUpdatingLocation];
                    break;
                    
                case kCLAuthorizationStatusDenied:
                case kCLAuthorizationStatusRestricted: {
                    if (self.locationCompletion) {
                        NSError *error = [NSError errorWithDomain:@"LocationError"
                                                           code:-2
                                                       userInfo:@{NSLocalizedDescriptionKey: @"PERMISSION DENIED"}];
                        self.locationCompletion(nil, error);
                        self.isWaitingForPermission = NO;
                    }
                    break;
                }
            }
        });
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.isRequestingLocation) return;
    
    self.isRequestingLocation = NO;
    self.isWaitingForPermission = NO;
    [manager stopUpdatingLocation];
    
    CLLocation *location = locations.lastObject;
    if (self.locationCompletion) {
        self.locationCompletion(location, nil);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (!self.isRequestingLocation) return;
    
    self.isRequestingLocation = NO;
    self.isWaitingForPermission = NO;
    [manager stopUpdatingLocation];
    
    if (self.locationCompletion) {
        self.locationCompletion(nil, error);
    }
}

@end
