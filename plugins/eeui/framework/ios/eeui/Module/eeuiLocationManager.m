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
                                           userInfo:@{NSLocalizedDescriptionKey: @"定位服务未开启"}];
            self.locationCompletion(nil, error);
        }
        return;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
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
                                               userInfo:@{NSLocalizedDescriptionKey: @"没有定位权限"}];
                self.locationCompletion(nil, error);
            }
            break;
        }
    }
}

- (BOOL)hasLocationPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
            status == kCLAuthorizationStatusAuthorizedAlways);
}

- (void)startUpdatingLocation {
    self.isRequestingLocation = YES;
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
            [self startUpdatingLocation];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            if (self.locationCompletion) {
                NSError *error = [NSError errorWithDomain:@"LocationError"
                                                   code:-2
                                               userInfo:@{NSLocalizedDescriptionKey: @"没有定位权限"}];
                self.locationCompletion(nil, error);
            }
            break;
        }
            
        default:
            break;
    }
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
