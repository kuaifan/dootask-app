//
//  ZLMediaLoadingView.h
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/16.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import "ZLMediaProgressView.h"

#define kMinProgress 0.0001

@interface ZLMediaLoadingView : UIView
{
    UILabel *_failureLabel;
    ZLMediaProgressView *_progressView;
}

@property (nonatomic) float progress;

- (void)showLoading;
- (void)showFailure;

@end
