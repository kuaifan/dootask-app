//
//  eeuiUmengAnalyticsModule.m
//

#import "eeuiUmengAnalyticsModule.h"
#import <UMCommon/MobClick.h>
#import <WeexPluginLoader/WeexPluginLoader.h>

@implementation eeuiUmengAnalyticsModule

WX_PlUGIN_EXPORT_MODULE(eeuiUmengAnalytics, eeuiUmengAnalyticsModule)
WX_EXPORT_METHOD(@selector(onPageStart:))
WX_EXPORT_METHOD(@selector(onPageEnd:))
WX_EXPORT_METHOD(@selector(onEvent:))
WX_EXPORT_METHOD(@selector(onEventWithLabel:eventLabel:))
WX_EXPORT_METHOD(@selector(onEventWithMap:parameters:))
WX_EXPORT_METHOD(@selector(onEventObject:parameters:))
WX_EXPORT_METHOD(@selector(onEventWithMapAndCount:parameters:eventNum:))
WX_EXPORT_METHOD(@selector(registerPreProperties:))
WX_EXPORT_METHOD(@selector(unregisterPreProperty:))
WX_EXPORT_METHOD(@selector(getPreProperties:))
WX_EXPORT_METHOD(@selector(clearPreProperties))
WX_EXPORT_METHOD(@selector(setFirstLaunchEvent:))
WX_EXPORT_METHOD(@selector(profileSignInWithPUID:))
WX_EXPORT_METHOD(@selector(profileSignInWithPUIDWithProvider:puid:))
WX_EXPORT_METHOD(@selector(profileSignOff))


- (void)onEvent:(NSString *)eventId {
    if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
        return;
    }
    [MobClick event:eventId];
}

- (void)onEventWithLabel:(NSString *)eventId eventLabel:(NSString *)eventLabel {
    if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
        return;
    }
    if ([eventLabel isKindOfClass:[NSNull class]]) {
        eventLabel = nil;
    }
    [MobClick event:eventId label:eventLabel];

}

- (void)onEventWithMap:(NSString *)eventId parameters:(NSDictionary *)parameters {
    if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
        return;
    }
    if (parameters == nil && [parameters isKindOfClass:[NSNull class]]) {
        parameters = nil;
    }
    [MobClick event:eventId attributes:parameters];
}

- (void)onEventObject:(NSString *)eventId parameters:(NSDictionary *)parameters {
    if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
        return;
    }
    if (parameters == nil && [parameters isKindOfClass:[NSNull class]]) {
        parameters = nil;
    }
    [MobClick event:eventId attributes:parameters];
}

- (void)onEventWithMapAndCount:(NSString *)eventId parameters:(NSDictionary *)parameters eventNum:(int)eventNum {
    if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
        return;
    }
    if (parameters == nil && [parameters isKindOfClass:[NSNull class]]) {
        parameters = nil;
    }

    [MobClick event:eventId attributes:parameters counter:eventNum];
}

- (void)onPageStart:(NSString *)pageName {
    if (pageName == nil || [pageName isKindOfClass:[NSNull class]]) {
        return;
    }
    [MobClick beginLogPageView:pageName];
}

- (void)onPageBegin:(NSString *)pageName {
    if (pageName == nil || [pageName isKindOfClass:[NSNull class]]) {
        return;
    }
    [MobClick beginLogPageView:pageName];
}

- (void)onPageEnd:(NSString *)pageName {
    if (pageName == nil || [pageName isKindOfClass:[NSNull class]]) {
        return;
    }
    [MobClick endLogPageView:pageName];
}

- (void)profileSignInWithPUID:(NSString *)puid {
    if (puid == nil || [puid isKindOfClass:[NSNull class]]) {
        return;
    }
    [MobClick profileSignInWithPUID:puid];
}

- (void)profileSignInWithPUIDWithProvider:(NSString *)provider puid:(NSString *)puid {
    if (provider == nil && [provider isKindOfClass:[NSNull class]]) {
        provider = nil;
    }
    if (puid == nil || [puid isKindOfClass:[NSNull class]]) {
        return;
    }

    [MobClick profileSignInWithPUID:puid provider:provider];
}

- (void)profileSignOff {
    [MobClick profileSignOff];
}


- (void)registerPreProperties:(NSDictionary *)property {

    if (property == nil && [property isKindOfClass:[NSNull class]]) {
        property = nil;
    }

    [MobClick registerPreProperties:property];
}

- (void)unregisterPreProperty:(NSString *)propertyName {

    if (propertyName == nil && [propertyName isKindOfClass:[NSNull class]]) {
        propertyName = nil;
    }
    [MobClick unregisterPreProperty:propertyName];

}


- (void)getPreProperties:(WXModuleCallback)callback {
    NSString *jsonString = nil;
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[MobClick getPreProperties]
                                                       options:kNilOptions //TODO: NSJSONWritingPrettyPrinted  // kNilOptions
                                                         error:&error];
    if ([jsonData length] && (error == nil)) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        jsonString = @"";
    }

    callback(@[jsonString]);

}

- (void)clearPreProperties {
    [MobClick clearPreProperties];

}

- (void)setFirstLaunchEvent:(NSArray *)eventList {
    if (eventList == nil && [eventList isKindOfClass:[NSNull class]]) {
        eventList = nil;
    }
    [MobClick setFirstLaunchEvent:eventList];
}

@end
