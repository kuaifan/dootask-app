//
//  ShareViewController.m
//  shareExtension
//
//  Created by Hitosea-005 on 2023/5/31.
//

#import "ShareViewController.h"
#import "ShareListViewController.h"
#import "DeviceUtil.h"

#define MXWeakify(var) \
    __weak typeof(var) weak##var = var

#define MXStrongifyAndReturnIfNil(var) \
    if (!weak##var) \
    { \
        return; \
    } \
    typeof(var) var = weak##var

@interface ShareViewController ()

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    ShareListViewController *vc = [ShareListViewController new];
    
    if (@available(iOS 13.0, *)) {
        vc.modalInPresentation = YES;
    } else {
        // Fallback on earlier versions
        vc.modalInPopover = YES;
    }
    
    MXWeakify(self);
    
    vc.completionCallback = ^(DootaskShareResult resulte){
        MXStrongifyAndReturnIfNil(self);
        
        switch (resulte) {
            case DootaskShareResultCancel:
                [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXUserCancelErrorDomain" code:4201 userInfo:nil]];
                [self dismiss];
                break;
                
            case DootaskShareResultFail:
                [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"MXFailureErrorDomain" code:500 userInfo:nil]];
                [self dismiss];
                break;
            case DootaskShareResultSuccess:
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                [self dismiss];
                break;

        }
    };
    
    [self presentViewController:vc animated:YES completion:nil];
    
//    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    SLComposeSheetConfigurationItem *item = [[SLComposeSheetConfigurationItem alloc] init];
    item.title = @"标题";
    item.value = @"value";
    item.valuePending = YES;
    
    
    return @[];
}
- (void)dismiss
{
    [self dismissViewControllerAnimated:true completion:^{
        [self.presentingViewController dismissViewControllerAnimated:false completion:nil];
        
        // 使用正常的方式完成扩展并退出，避免崩溃
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
        
        // 强制清理内存
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        if (@available(iOS 13.0, *)) {
            [NSProcessInfo.processInfo performExpiringActivityWithReason:@"Cleanup" usingBlock:^(BOOL expired) {
                exit(0); // 正常退出进程
            }];
        } else {
            // iOS 13之前的版本
            dispatch_async(dispatch_get_main_queue(), ^{
                exit(0);
            });
        }
    }];
}

@end
