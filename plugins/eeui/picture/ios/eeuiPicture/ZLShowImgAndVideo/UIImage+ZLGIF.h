//
//  UIImage+ZLGIF.h
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/16.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ZLGIF)
//加载保存在本地的gif图片
+ (UIImage *)sd_animatedGIFNamed:(NSString *)name;
//获取到图片的data后重新构造一张可以播放的图片
+ (UIImage *)zl_animatedGIFWithData:(NSData *)data;
//图片按照指定的尺寸缩放
- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end
