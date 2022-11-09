//
//  UIImage+ZLGIF.m
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/16.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import "UIImage+ZLGIF.h"

@implementation UIImage (ZLGIF)
+ (UIImage *)zl_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
        
    }
    //获取数据源
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // 获取图片数量(如果传入的是gif图的二进制，那么获取的是图片帧数)
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            duration += [self sd_frameDurationAtIndex:i source:source];
            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];
            CGImageRelease(image);
            
        }
        // 如果上面的计算播放时间方法没有成功，就按照下面方法计算
        // 计算一次播放的总时间：每张图播放1/10秒 * 图片总数
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
            
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
        
    }
    CFRelease(source);
    return animatedImage;
    
}
//************************************** //计算每帧需要播放的时间
+ (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    float frameDuration = 0.1f;
    // 获取这一帧的属性字典
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    // 从字典中获取这一帧持续的时间
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
        
    } else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
            
        }
        
    }
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
        
    }
    CFRelease(cfFrameProperties);
    return frameDuration;
    
}
//**************************************
+ (UIImage *)sd_animatedGIFNamed:(NSString *)name {
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale > 1.0f) {
        NSString *retinaPath = [[NSBundle mainBundle] pathForResource:[name stringByAppendingString:@"@2x"] ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:retinaPath];
        if (data) {
            return [UIImage zl_animatedGIFWithData:data];
            
        }
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"]; data = [NSData dataWithContentsOfFile:path];
        if (data) {
            return [UIImage zl_animatedGIFWithData:data];
            
        }
        return [UIImage imageNamed:name];
        
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data) {
            return [UIImage zl_animatedGIFWithData:data];
            
        }
        return [UIImage imageNamed:name];
        
    }
    
}
//**************************************
/**
 1.取较大的缩放比例值，用这个值让宽高等比缩放
 2.调整位置，使缩放后的图居中
 3.遍历self.images， 将每张图缩放后导出，放到数组中
 4.使用上面的数组创建animatedImage并返回 */
- (UIImage *)sd_animatedImageByScalingAndCroppingToSize:(CGSize)size {
    if (CGSizeEqualToSize(self.size, size) || CGSizeEqualToSize(size, CGSizeZero))
    {
        return self;
        
    }
    CGSize scaledSize = size;
    CGPoint thumbnailPoint = CGPointZero;
    CGFloat widthFactor = size.width / self.size.width;
    CGFloat heightFactor = size.height / self.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = self.size.width * scaleFactor;
    scaledSize.height = self.size.height * scaleFactor;
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5;
        
    } else if (widthFactor < heightFactor)
    {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
        
    }
    NSMutableArray *scaledImages = [NSMutableArray array];
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    for (UIImage *image in self.images)
    {
        [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [scaledImages addObject:newImage];
        
    }
    UIGraphicsEndImageContext();
    return [UIImage animatedImageWithImages:scaledImages duration:self.duration];
    
}
    
@end
