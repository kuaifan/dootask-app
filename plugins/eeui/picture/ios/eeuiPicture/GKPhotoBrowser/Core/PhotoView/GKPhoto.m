//
//  GKPhoto.m
//  GKPhotoBrowser
//
//  Created by QuintGao on 2020/6/16.
//  Copyright © 2020 QuintGao. All rights reserved.
//

#import "GKPhoto.h"

@interface GKPhoto()

@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, assign) PHImageRequestID videoRequestID;

@end

@implementation GKPhoto

- (instancetype)init {
    if (self = [super init]) {
        self.autoPlay = YES;
    }
    return self;
}

- (BOOL)isVideo {
    return !self.isLivePhoto && (self.videoUrl || self.videoAsset);
}

- (BOOL)isLivePhoto {
    if (self.imageAsset) {
        return self.imageAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive;
    }
    return _isLivePhoto;
}

- (void)getImage:(void (^)(NSData * _Nullable, UIImage * _Nullable, NSError * _Nullable))completion {
    if (!self.imageAsset) {
        NSError *error = [NSError errorWithDomain:@"com.browser.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"没有图片资源"}];
        completion(nil, nil, error);
        return;
    }
    __weak __typeof(self) weakSelf = self;
    if (self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        self.imageRequestID = 0;
    }
    
    PHAsset *asset = self.imageAsset;
    if (asset && asset.mediaType == PHAssetMediaTypeImage) {
        // Gif
        if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
            self.imageRequestID = [self loadImageDataWithAsset:asset completion:^(NSData * _Nullable data, NSError * _Nullable error) {
                __strong __typeof(weakSelf) self = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageRequestID = 0;
                    !completion ?: completion(data, nil, error);
                });
            }];
        }else {
            CGFloat width = UIScreen.mainScreen.bounds.size.width * 2;
            self.imageRequestID = [self loadImageWithAsset:asset photoWidth:width completion:^(UIImage * _Nullable image, NSError * _Nullable error) {
                __strong __typeof(weakSelf) self = weakSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageRequestID = 0;
                    !completion ?: completion(nil, image, error);
                });
            }];
        }
    }else {
        NSError *error = [NSError errorWithDomain:@"com.browser.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"不是图片资源"}];
        !completion ?: completion(nil, nil, error);
    }
}

- (void)getVideo:(void (^)(NSURL * _Nullable, NSError * _Nullable))completion {
    if (!self.isVideo) {
        NSError *error = [NSError errorWithDomain:@"com.browser.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"不是视频资源"}];
        completion(nil, error);
        return;
    }
    __weak __typeof(self) weakSelf = self;
    if (self.videoRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.videoRequestID];
        self.videoRequestID = 0;
    }
    
    PHAsset *asset = self.videoAsset;
    if (asset && asset.mediaType == PHAssetMediaTypeVideo) {
        self.videoRequestID = [self loadVideoWithAsset:asset completion:^(NSURL * _Nonnull url, NSError * _Nullable error) {
            __strong __typeof(weakSelf) self = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.videoUrl = url;
                self.videoRequestID = 0;
                !completion ?: completion(url, error);
            });
        }];
    }else {
        if (self.videoUrl) {
            !completion ?: completion(self.videoUrl, nil);
        }else {
            NSError *error = [NSError errorWithDomain:@"com.browser.error" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"没有视频资源"}];
            !completion ?: completion(nil, error);
        }
    }
}

#pragma mark - Private
- (PHImageRequestID)loadImageDataWithAsset:(PHAsset *)asset completion:(void(^)(NSData *, NSError *))completion {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.synchronous = YES;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        NSError *error = info[PHImageErrorKey];
        BOOL complete = ![info[PHImageCancelledKey] boolValue] && !error && ![info[PHImageResultIsDegradedKey] boolValue];
        if (complete && imageData) {
            !completion ?: completion(imageData, nil);
        }else {
            !completion ?: completion(nil, error);
        }
    }];
    
    return requestID;
}

- (PHImageRequestID)loadImageWithAsset:(PHAsset *)asset photoWidth:(CGFloat)photoWidth completion:(void(^)(UIImage *, NSError *))completion {
    CGFloat scale = 2.0;
    if (UIScreen.mainScreen.bounds.size.width > 700) {
        scale = 1.5;
    }
    CGFloat aspectRatio = asset.pixelWidth / (CGFloat)asset.pixelHeight;
    CGFloat pixelWidth = photoWidth * scale;
    // 超宽图片
    if (aspectRatio > 1.8) {
        pixelWidth = pixelWidth * aspectRatio;
    }
    // 超高图片
    if (aspectRatio < 0.2) {
        pixelWidth = pixelWidth * 0.5;
    }
    CGFloat pixelHeight = pixelWidth / aspectRatio;
    CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.synchronous = YES;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        NSError *error = [info objectForKey:PHImageErrorKey];
        BOOL cancelled = [[info objectForKey:PHImageCancelledKey] boolValue];
        if (!cancelled && result) {
            !completion ? : completion(result, nil);
        }
        // Download image from iCloud / 从iCloud下载图片
        if ([info objectForKey:PHImageResultIsInCloudKey] && !result) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                UIImage *resultImage = [UIImage imageWithData:imageData];
                NSError *error = info[PHImageErrorKey];
                if (resultImage) {
                    !completion ?: completion(resultImage, nil);
                }else {
                    !completion ?: completion(nil, error);
                }
            }];
        }else {
            if (!result && error) {
                !completion ?: completion(nil, error);
            }
        }
    }];
    return requestID;
}

- (PHImageRequestID)loadVideoWithAsset:(PHAsset *)asset completion:(nonnull void (^)(NSURL * _Nullable, NSError * _Nullable))completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    
    PHImageRequestID requestID = [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:options resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
        NSError *error = [info objectForKey:PHImageErrorKey];
        if (error && !urlAsset) {
            !completion ?: completion(nil, error);
        }else {
            !completion ?: completion(urlAsset.URL, nil);
        }
    }];
    return requestID;
}

@end
