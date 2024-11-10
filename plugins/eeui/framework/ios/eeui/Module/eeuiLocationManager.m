#import "eeuiLocationManager.h"

@interface eeuiLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) LocationCompletion locationCompletion;
@property (nonatomic, assign) BOOL isRequestingLocation;

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
    }
    return self;
}

- (void)requestLocationWithCompletion:(LocationCompletion)completion {
    self.locationCompletion = completion;
    
    // 检查定位服务是否可用
    if (![CLLocationManager locationServicesEnabled]) {
        if (self.locationCompletion) {
            NSError *error = [NSError errorWithDomain:@"LocationError"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"UNAVAILABLE"}];
            self.locationCompletion(nil, error);
        }
        return;
    }
    
    // iOS 14及以上版本
    if (@available(iOS 14.0, *)) {
        CLAuthorizationStatus status = self.locationManager.authorizationStatus;
        [self handleAuthorizationStatus:status];
    } else {
        // iOS 14以下版本
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)handleAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            // 请求权限
            [self.locationManager requestWhenInUseAuthorization];
            break;
            
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            // 已有权限，直接开始定位
            [self startUpdatingLocation];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            // 无权限
            if (self.locationCompletion) {
                NSError *error = [NSError errorWithDomain:@"LocationError"
                                                   code:-2
                                               userInfo:@{NSLocalizedDescriptionKey: @"PERMISSION DENIED"}];
                self.locationCompletion(nil, error);
            }
            break;
        }
    }
}

- (BOOL)hasLocationPermission {
    if (@available(iOS 14.0, *)) {
        CLAuthorizationStatus status = self.locationManager.authorizationStatus;
        return (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                status == kCLAuthorizationStatusAuthorizedAlways);
    } else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        return (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
                status == kCLAuthorizationStatusAuthorizedAlways);
    }
}

- (void)startUpdatingLocation {
    self.isRequestingLocation = YES;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
// iOS 14及以上版本使用此方法
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager  API_AVAILABLE(ios(14.0)) {
    [self handleAuthorizationStatus:manager.authorizationStatus];
}

// iOS 14以下版本使用此方法
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self handleAuthorizationStatus:status];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (!self.isRequestingLocation) return;
    
    self.isRequestingLocation = NO;
    [manager stopUpdatingLocation];
    
    CLLocation *location = locations.lastObject;
    if (self.locationCompletion) {
        self.locationCompletion(location, nil);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (!self.isRequestingLocation) return;
    
    self.isRequestingLocation = NO;
    [manager stopUpdatingLocation];
    
    if (self.locationCompletion) {
        self.locationCompletion(nil, error);
    }
}

@end
