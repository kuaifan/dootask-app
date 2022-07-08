//
//  AppCommunication.m
//


#import "AppCommunication.h"
#import <MessageUI/MessageUI.h>
#import "UINavigationController+FDFullscreenPopGesture.h"

@interface AppCommunication ()

@property(nonatomic, strong)AppCallback mailback;
@property(nonatomic, strong)AppCallback smsback;

@end

@implementation AppCommunication

+ (AppCommunication *)singletonManger{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)call:(NSString *)phone :(AppCallback)callback{
    if (phone == nil || [phone isEqualToString:@""]) {
        callback(@{@"error":@{@"msg":@"CALL_INVALID_ARGUMENT",@"code":@101040}},nil);
        return;
    }
    NSString *allString = @"tel://";
    allString = [allString stringByAppendingString:phone];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:allString]];
    callback(nil,nil);
}


- (void)mail:(NSArray *)mail :(NSDictionary*)params :(AppCallback)callback{
    self.mailback = callback;
    if (mail == nil || [mail isEqual:@[]]) {
        callback(@{@"error":@{@"msg":@"MAIL_INVALID_ARGUMENT",@"code":@103040}},nil);
        return;
    }
    
    Class messageClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    //判断是否有短信功能
    if (messageClass != nil) {
        //有发送功能要做的事情
        
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        mailController.mailComposeDelegate = self;
        //拼接并设置短信内容
        
        [mailController setSubject:params[@"subject"]];
        
        //设置发送给谁
        [mailController setMessageBody:params[@"body"] isHTML:NO];
        [mailController setToRecipients:mail];
        if (mailController) {
            //推到发送试图控制器
            [[self getCurrentVC] presentViewController:mailController animated:YES completion:^{
                
            }];

        }else{
             callback(@{@"error":@{@"msg":@"SEND_MAIL_PERMISSION_DENIED",@"code":@103040}},nil);
        }
    }

}

- (void)sms:(NSArray *)phone :(NSString *)text :(AppCallback)callback{
    self.smsback = callback;
    if (phone == nil || [phone isEqual:@[]]) {
        
        callback(@{@"error":@{@"msg":@"SMS_INVALID_ARGUMENT",@"code":@102040}},nil);
        return;
    }
    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    
    //判断是否有短信功能
    if (messageClass != nil) {
        //有发送功能要做的事情
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
        UIViewController *rootViewController = messageController.viewControllers.firstObject;
        rootViewController.fd_prefersNavigationBarHidden = YES;
        messageController.messageComposeDelegate = self;
        //拼接并设置短信内容
        NSString *messageContent = text;
        messageController.body = messageContent;
        
        //设置发送给谁
        messageController.recipients = phone;
        
        //推到发送试图控制器
        [[self getCurrentVC] presentViewController:messageController animated:YES completion:nil];
        // [[[[messageController viewControllers] lastObject] navigationItem] setTitle:@"新消息"];//修改短信界面标题
    }else{
        callback(@{@"error":@{@"msg":@"SEND_SMS_PERMISSION_DENIED ",@"code":@1}},nil);
    }

}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    NSString *tipContent;
   switch (result) {
            case MessageComposeResultCancelled:
       {
               tipContent = @"Cancelled";
           
              break;
       }
          case MessageComposeResultFailed:
       {
            tipContent = @"Failed";
             break;
       }
         case MessageComposeResultSent:
       {
             tipContent = @"Sent";
             break;
       }
         default:
             break;
     }
    self.smsback(nil,@{@"result":tipContent});
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error{
    NSString *tipContent;
    

    switch (result) {
        case MFMailComposeResultCancelled:
        {
            tipContent = @"Cancelled";
            
            break;
        }
        case MFMailComposeResultSaved:
        {
            tipContent = @"Saved";
            break;
        }
        case MFMailComposeResultSent:
        {
            tipContent = @"Sent";
            break;
        }
            
        case MFMailComposeResultFailed:
        {
            tipContent = @"Failed";
            
        }
        default:
            break;
    }
    
    self.mailback(nil,@{@"result":tipContent});
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}

@end
