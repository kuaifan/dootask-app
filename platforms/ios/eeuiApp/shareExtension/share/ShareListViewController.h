//
//  ShareListViewController.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/1.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DootaskShareResult) {
    DootaskShareResultCancel = 0,
    DootaskShareResultFail,
    DootaskShareResultSuccess
} ;

NS_ASSUME_NONNULL_BEGIN

@interface ShareListViewController : UIViewController

@property (nonatomic, copy) void (^completionCallback)(DootaskShareResult);

@end

NS_ASSUME_NONNULL_END
