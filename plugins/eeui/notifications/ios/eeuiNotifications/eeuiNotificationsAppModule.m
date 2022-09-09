//
//  eeuiNotificationsAppModule.m
//  Pods
//

#import "eeuiNotificationsAppModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <UserNotifications/UserNotifications.h>

@interface eeuiNotificationsAppModule ()

@end

@implementation eeuiNotificationsAppModule

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(eeuiNotifications, eeuiNotificationsAppModule)
WX_EXPORT_METHOD(@selector(notify:))
WX_EXPORT_METHOD(@selector(clearId:))
WX_EXPORT_METHOD(@selector(clearTitle:))
WX_EXPORT_METHOD(@selector(clearAll))
WX_EXPORT_METHOD(@selector(getPermissionStatus:))
WX_EXPORT_METHOD(@selector(gotoSet))
WX_EXPORT_METHOD(@selector(setBadge:))

//通知
- (void)notify:(NSDictionary *)params {
    int id = params[@"id"] ? [params[@"id"] intValue] : arc4random() % 100;
    int badge = params[@"badge"] ? [params[@"badge"] intValue] : 0;
    NSString *title = params[@"title"] ? [WXConvert NSString:params[@"title"]] : @"";
    NSString *subtitle = params[@"subtitle"] ? [WXConvert NSString:params[@"subtitle"]] : @"";
    NSString *body = params[@"body"] ? [WXConvert NSString:params[@"body"]] : @"";
    //
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        // 标题
        content.title = title;
        content.subtitle = subtitle;
        // 内容
        content.body = body;
        // 声音
        content.sound = [UNNotificationSound defaultSound];
        //content.sound = [UNNotificationSound soundNamed:@"Alert_ActivityGoalAttained_Salient_Haptic.caf"];
        // 角标
        content.badge = @(badge);
        // 多少秒后发送,可以将固定的日期转化为时间
        NSTimeInterval time = [[NSDate dateWithTimeIntervalSinceNow:1] timeIntervalSinceNow];
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:time repeats:NO];
        // 添加通知的标识符，可以用于移除，更新等操作
        NSString *identifier = [NSString stringWithFormat:@"%d", id];//@"noticeId";
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        //
        [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
            // NSLog(@"成功添加推送");
        }];
    } else {
        UILocalNotification *notif = [[UILocalNotification alloc] init];
        // 发出推送的日期
        notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];
        // 推送的标题
        if (@available(iOS 8.2, *)) {
            notif.alertTitle = title;
        } else {
            // Fallback on earlier versions
        }
        // 推送的内容
        notif.alertBody = body;
        // 可以添加特定信息
        notif.userInfo = @{@"noticeId": @(id)};
        // 角标
        notif.applicationIconBadgeNumber = badge;
        // 提示音
        notif.soundName = UILocalNotificationDefaultSoundName;
        // 每周循环提醒
        notif.repeatInterval = NSCalendarUnitWeekOfYear;
        //
        [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    }
}

//根据ID清除指定通知
- (void)clearId:(NSString *)id {
    NSString *noticeId = [NSString stringWithFormat:@"%@", id];
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removePendingNotificationRequestsWithIdentifiers:@[noticeId]];
    } else {
        NSArray *array = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *localNotification in array) {
            NSDictionary *userInfo = localNotification.userInfo;
            NSString *obj = [userInfo objectForKey:@"noticeId"];
            if ([obj isEqualToString:noticeId]) {
                [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            }
        }
    }
}

//根据标题清除指定通知
- (void)clearTitle:(NSString *)title {
    __block NSString *noticeId = @"";
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *_Nonnull requests) {
            for (UNNotificationRequest *req in requests) {
                if (req.content && [title isEqualToString:req.content.title]) {
                    noticeId = req.identifier;
                }
            }
        }];
    } else {
        NSArray *array = [[UIApplication sharedApplication] scheduledLocalNotifications];
        for (UILocalNotification *localNotification in array) {
            if (@available(iOS 8.2, *)) {
                NSString *alertTitle = localNotification.alertTitle;
                if ([alertTitle isEqualToString:title]) {
                    NSDictionary *userInfo = localNotification.userInfo;
                    noticeId = [userInfo objectForKey:@"noticeId"];
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    if (noticeId.length > 0) {
        [self clearId:noticeId];
    }
}

//清除所有通知
- (void)clearAll {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeAllPendingNotificationRequests];
    } else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
}

- (void)getPermissionStatus:(WXModuleCallback)completion{
    if (@available(iOS 10 , *)){
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined){
                // 未选择
                completion(@(false));
            }else if (settings.authorizationStatus == UNAuthorizationStatusDenied){
                // 没权限
                completion(@(false));
            }else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized){
                // 已授权
                //[self requestNotification];
                completion(@(true));
            }
        }];
    }
    else if (@available(iOS 8 , *))
    {
        UIUserNotificationSettings * setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
        if (setting.types == UIUserNotificationTypeNone) {
            // 没权限
            completion(@(false));
        }else{
            // 已授权
            //[self requestNotification];
            completion(@(true));
        }
    }
    else{
        UIRemoteNotificationType type = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        if (type == UIUserNotificationTypeNone)
        {
            // 没权限
            completion(@(false));
        }
    }
}

- (void)gotoSet{
    if (UIApplicationOpenSettingsURLString != NULL) {
        UIApplication *application = [UIApplication sharedApplication];
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            if (@available(iOS 10.0, *)) {
                [application openURL:URL options:@{} completionHandler:nil];
            } else {
                // Fallback on earlier versions
                [application openURL:URL];
            }
        } else {
            [application openURL:URL];
        }
    }
}

- (void)setBadge:(int)number{
    [UIApplication sharedApplication].applicationIconBadgeNumber = number;
    
}

@end
