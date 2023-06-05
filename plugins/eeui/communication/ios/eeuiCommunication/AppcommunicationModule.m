//
//  AppcommunicationModule.m
//  Pods
//

#import "AppcommunicationModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import "AppCommunication.h"

@interface AppcommunicationModule ()

@end

@implementation AppcommunicationModule
WX_PlUGIN_EXPORT_MODULE(eeuiCommunication, AppcommunicationModule)
WX_EXPORT_METHOD(@selector(call::))
WX_EXPORT_METHOD(@selector(mail:::))
WX_EXPORT_METHOD(@selector(sms:::))


- (void)call:(NSString *)phone :(WXModuleCallback)callback{
    [[AppCommunication singletonManger] call:phone :^(id error,id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}


- (void)mail:(NSArray *)mail :(NSDictionary*)params :(WXModuleCallback)callback{
    [[AppCommunication singletonManger] mail:mail :params :^(id error,id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

- (void)sms:(NSArray *)phone :(NSString *)text :(WXModuleCallback)callback{
    [[AppCommunication singletonManger] sms:phone :text :^(id error,id result) {
        if (error) {
            if (callback) {
                callback(error);
            }
        } else {
            if (callback) {
                callback(result);
            }
        }
    }];
}

@end
