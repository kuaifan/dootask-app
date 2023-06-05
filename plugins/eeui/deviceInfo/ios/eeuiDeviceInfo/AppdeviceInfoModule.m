//
//  AppdeviceInfoModule.m
//  Pods
//

#import "AppdeviceInfoModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import "AppDeviceInfo.h"
#import "AppDeviceNetwork.h"
#import "AppVibration.h"
#import "AppScreen.h"
#import "AppVolume.h"
#import "AppBattery.h"

@interface AppdeviceInfoModule ()

@end

@implementation AppdeviceInfoModule

WX_PlUGIN_EXPORT_MODULE(eeuiDeviceInfo, AppdeviceInfoModule)

WX_EXPORT_METHOD(@selector(info:))
WX_EXPORT_METHOD(@selector(netStatus:))
WX_EXPORT_METHOD(@selector(setVibrate::))

WX_EXPORT_METHOD(@selector(screenInfo:))
WX_EXPORT_METHOD(@selector(getBrightness:))
WX_EXPORT_METHOD(@selector(setBrightness::))
WX_EXPORT_METHOD(@selector(getOrientation:))

WX_EXPORT_METHOD(@selector(setVolume::))
WX_EXPORT_METHOD(@selector(getVolume:))

WX_EXPORT_METHOD(@selector(batteryStatus:))

- (void)info:(WXModuleCallback)callback{
    [[AppDeviceInfo singletonManger] info:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)netStatus:(WXModuleCallback)callback{
    [[AppDeviceNetwork singletonManger] status:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)setVibrate:(NSNumber *)time :(WXModuleCallback)callback{
    [[AppVibration singletonManger] vibrate:time :^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)screenInfo:(WXModuleCallback)callback{
    [[AppScreen singletonManger] info:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)getBrightness:(WXModuleCallback)callback{
    [[AppScreen singletonManger] getBrightness:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)setBrightness:(NSNumber *)brightness :(WXModuleCallback)callback{
    [[AppScreen singletonManger] setBrightness:brightness :^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)getOrientation:(WXModuleCallback)callback{
    [[AppScreen singletonManger] getOrientation:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)getVolume:(WXModuleCallback)callback{
    [[AppVolume singletonManger] get:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)setVolume:(NSNumber *)volume :(WXModuleCallback)callback{
    [[AppVolume singletonManger] set:volume :^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

- (void)batteryStatus:(WXModuleCallback)callback{
    [[AppBattery singletonManger] status:^(id error, id result) {
        if (callback) {
            if (error) {
                callback(error);
            } else {
                callback(result);
            }
        }
    }];
}

@end
