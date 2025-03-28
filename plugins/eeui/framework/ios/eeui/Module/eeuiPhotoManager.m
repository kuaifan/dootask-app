//
//  eeuiPhotoManager.m
//  eeui
//
//  Created on 2025/03/26.
//

#import "eeuiPhotoManager.h"
#import <Photos/Photos.h>

@implementation eeuiPhotoManager

static eeuiPhotoManager *instance = nil;

+ (eeuiPhotoManager *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[eeuiPhotoManager alloc] init];
    });
    return instance;
}

/**
 * 获取相册最新图片
 * 同时返回缩略图和原图的路径及相关信息
 */
- (void)getLatestPhoto:(WXKeepAliveCallback)callback {
    // 检查相册访问权限
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        // 用户拒绝了相册权限
        if (callback) {
            callback(@{@"status":@"error", @"error":@"没有相册访问权限"}, NO);
        }
        return;
    }
    
    // 请求权限（如果还未请求）
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authStatus) {
        if (authStatus == PHAuthorizationStatusAuthorized) {
            // 获取相册所有照片，按照创建时间降序排列
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            if (@available(iOS 9, *)) {
                fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary;
            } else {
                // Fallback on earlier versions
            } // 仅用户相册
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
            
            // 检查是否有照片
            if (fetchResult.count > 0) {
                // 获取第一张（最新的）照片
                PHAsset *asset = fetchResult.firstObject;
                
                // 创建要返回的结果字典
                NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
                resultDict[@"status"] = @"success";
                resultDict[@"created"] = @([asset.creationDate timeIntervalSince1970]);
                
                // 使用信号量替代dispatch_group进行同步，避免可能的不平衡问题
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                
                // 创建计数器，用于跟踪完成状态
                __block int completionCount = 0;
                
                // 1. 获取缩略图
                dispatch_async(queue, ^{
                    [self getThumbnailImage:asset withCompletion:^(NSDictionary *thumbResult) {
                        @synchronized (resultDict) {
                            if (thumbResult) {
                                resultDict[@"thumbnail"] = thumbResult;
                            }
                            completionCount++;
                            // 当两个任务都完成时，发送信号
                            if (completionCount == 2) {
                                dispatch_semaphore_signal(semaphore);
                            }
                        }
                    }];
                });
                
                // 2. 获取原图
                dispatch_async(queue, ^{
                    [self getOriginalImage:asset withCompletion:^(NSDictionary *originalResult) {
                        @synchronized (resultDict) {
                            if (originalResult) {
                                resultDict[@"original"] = originalResult;
                            }
                            completionCount++;
                            // 当两个任务都完成时，发送信号
                            if (completionCount == 2) {
                                dispatch_semaphore_signal(semaphore);
                            }
                        }
                    }];
                });
                
                // 在后台等待所有任务完成
                dispatch_async(queue, ^{
                    // 设置一个合理的超时时间（10秒）
                    long timeout = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
                    
                    // 即使超时也要返回结果，避免回调永不执行
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            if (timeout == 0) {
                                // 正常完成
                                callback(resultDict, NO);
                            } else {
                                // 超时，但返回已获取的结果
                                if (![resultDict objectForKey:@"thumbnail"] && ![resultDict objectForKey:@"original"]) {
                                    // 如果两个都没获取到，返回错误
                                    callback(@{@"status":@"error", @"error":@"获取图片超时"}, NO);
                                } else {
                                    // 返回部分结果
                                    callback(resultDict, NO);
                                }
                            }
                        }
                    });
                });
            } else {
                // 相册中没有照片
                if (callback) {
                    callback(@{@"status":@"error", @"error":@"相册中没有照片"}, NO);
                }
            }
        } else {
            // 用户拒绝了相册权限
            if (callback) {
                callback(@{@"status":@"error", @"error":@"没有相册访问权限"}, NO);
            }
        }
    }];
}

/**
 * 获取缩略图
 * 该方法根据提供的PHAsset生成缩略图，并保存至临时目录
 * 对于普通图片保持原始宽高比，确保最小边为300像素
 * 对于长宽比超过5:1的图片，截取中间部分以避免图片过长或过宽
 *
 * @param asset PHAsset对象，表示要处理的图片资源
 * @param completion 完成回调，返回包含以下信息的字典：
 *                   - path: 缩略图的临时文件路径
 *                   - base64: 图片的base64编码（带前缀，可直接用于显示）
 *                   - width: 缩略图宽度
 *                   - height: 缩略图高度
 *                   - size: 文件大小（字节）
 */
- (void)getThumbnailImage:(PHAsset *)asset withCompletion:(void (^)(NSDictionary *))completion {
    // 获取照片的缩略图
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    
    // 计算等比缩放的尺寸，确保最小边为300像素
    CGFloat minSize = 300.0f;
    CGSize targetSize;
    PHImageContentMode contentMode;
    
    // 根据资产的宽高比例计算目标尺寸
    CGFloat assetWidth = asset.pixelWidth;
    CGFloat assetHeight = asset.pixelHeight;
    CGFloat aspectRatio = assetWidth / assetHeight;
    
    // 判断是否为极端长宽比（超过5:1或1:5）
    if (aspectRatio >= 5.0 || aspectRatio <= 0.2) {
        // 对于超长或超宽的图片，保持1:1到5:1之间的比例，并截取中间部分
        contentMode = PHImageContentModeAspectFill;
        
        if (aspectRatio >= 5.0) {
            // 非常宽的图片
            targetSize = CGSizeMake(minSize * 5, minSize);
        } else {
            // 非常高的图片
            targetSize = CGSizeMake(minSize, minSize * 5);
        }
    } else {
        // 普通长宽比，保持原始比例
        contentMode = PHImageContentModeAspectFit;
        
        if (aspectRatio >= 1.0) {
            // 横向图片或正方形
            targetSize = CGSizeMake(minSize * aspectRatio, minSize);
        } else {
            // 纵向图片
            targetSize = CGSizeMake(minSize, minSize / aspectRatio);
        }
    }
    
    // 临时存储路径
    NSString *tempDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"thumb_%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    
    // 获取缩略图
    [[PHImageManager defaultManager] requestImageForAsset:asset
                                               targetSize:targetSize
                                              contentMode:contentMode
                                                  options:options
                                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            // 创建一个没有Alpha通道的新图像，避免不必要的文件大小和内存占用
            UIGraphicsBeginImageContextWithOptions(result.size, YES, result.scale); // YES表示不透明
            [result drawInRect:CGRectMake(0, 0, result.size.width, result.size.height)];
            UIImage *imageWithoutAlpha = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // 保存缩略图到临时目录
            NSData *imageData = UIImageJPEGRepresentation(imageWithoutAlpha ?: result, 0.7);
            BOOL success = [imageData writeToFile:filePath atomically:YES];
            
            if (success) {
                // 获取图片尺寸和大小信息
                CGSize imageSize = result.size;
                NSInteger fileSize = [imageData length];
                
                // 将图片转换为Base64字符串，让网页能够直接显示
                NSString *base64Image = [imageData base64EncodedStringWithOptions:0];
                NSString *base64ImageUrl = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64Image];
                
                // 返回成功结果
                NSDictionary *thumbResult = @{
                    @"path": filePath,
                    @"base64": base64ImageUrl,
                    @"width": @(imageSize.width),
                    @"height": @(imageSize.height),
                    @"size": @(fileSize),
                };
                
                completion(thumbResult);
            } else {
                completion(nil);
            }
        } else {
            completion(nil);
        }
    }];
}

/**
 * 获取原图
 * 该方法根据提供的PHAsset获取原图，并保存至临时目录
 *
 * @param asset PHAsset对象，表示要处理的图片资源
 * @param completion 完成回调，返回包含以下信息的字典：
 *                   - path: 原图的临时文件路径
 *                   - width: 原图宽度
 *                   - height: 原图高度
 *                   - size: 文件大小（字节）
 */
- (void)getOriginalImage:(PHAsset *)asset withCompletion:(void (^)(NSDictionary *))completion {
    // 配置图片请求选项
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; // 使用高质量模式
    options.resizeMode = PHImageRequestOptionsResizeModeNone; // 不调整大小
    options.networkAccessAllowed = YES; // 允许从iCloud下载图片
    options.version = PHImageRequestOptionsVersionCurrent;
    
    // 临时存储路径
    NSString *tempDir = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"original_%@.jpg", [[NSUUID UUID] UUIDString]];
    NSString *filePath = [tempDir stringByAppendingPathComponent:fileName];
    
    // 请求原始图片数据
    [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                      options:options
                                                resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (imageData) {
            // 获取原始图片
            UIImage *originalImage = [UIImage imageWithData:imageData];
            
            // 根据方向修正图片（如果需要）并去除Alpha通道
            UIGraphicsBeginImageContextWithOptions(originalImage.size, YES, originalImage.scale); // YES表示不透明
            [originalImage drawInRect:(CGRect){0, 0, originalImage.size}];
            UIImage *imageWithoutAlpha = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            // 保存原始图片，稍微压缩以避免文件过大
            NSData *jpegData = UIImageJPEGRepresentation(imageWithoutAlpha ?: originalImage, 0.95);
            BOOL success = [jpegData writeToFile:filePath atomically:YES];
            
            if (success) {
                // 获取图片尺寸和大小信息
                CGSize imageSize = originalImage.size;
                NSInteger fileSize = [jpegData length];
                
                // 返回成功结果
                NSDictionary *originalResult = @{
                    @"path": filePath,
                    @"width": @(imageSize.width),
                    @"height": @(imageSize.height),
                    @"size": @(fileSize),
                };
                
                completion(originalResult);
            } else {
                completion(nil);
            }
        } else {
            // 如果获取图片数据失败，尝试使用备用方法获取图片
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                       targetSize:PHImageManagerMaximumSize
                                                      contentMode:PHImageContentModeAspectFit
                                                          options:options
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if (result) {
                    // 创建不带Alpha通道的图像
                    UIGraphicsBeginImageContextWithOptions(result.size, YES, result.scale); // YES表示不透明
                    [result drawInRect:CGRectMake(0, 0, result.size.width, result.size.height)];
                    UIImage *imageWithoutAlpha = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    // 保存图片到临时目录
                    NSData *imageData = UIImageJPEGRepresentation(imageWithoutAlpha ?: result, 0.95);
                    BOOL success = [imageData writeToFile:filePath atomically:YES];
                    
                    if (success) {
                        // 获取图片尺寸和大小信息
                        CGSize imageSize = result.size;
                        NSInteger fileSize = [imageData length];
                        
                        // 返回成功结果
                        NSDictionary *originalResult = @{
                            @"path": filePath,
                            @"width": @(imageSize.width),
                            @"height": @(imageSize.height),
                            @"size": @(fileSize),
                        };
                        
                        completion(originalResult);
                    } else {
                        completion(nil);
                    }
                } else {
                    completion(nil);
                }
            }];
        }
    }];
}

/**
 * 上传图片到指定URL
 * 该方法将图片文件以multipart/form-data格式上传到指定URL
 *
 * @param params 包含以下参数的字典：
 *              - url: (必需) 上传的目标URL地址
 *              - path: (必需) 图片文件的本地路径
 *              - fieldName: (可选) 表单字段名，默认为"file"
 *              - data: (可选) 附加表单数据，必须是字典类型，键值会被转换为表单字段
 *              - headers: (可选) 自定义HTTP请求头，必须是字典类型
 * 
 * @param callback 回调函数，会返回上传结果，包含以下信息：
 *                - 成功: {status: "success", statusCode: HTTP状态码, data: 服务器响应数据}
 *                - 失败: {status: "error", error: 错误信息}
 */
- (void)uploadPhoto:(NSDictionary *)params callback:(WXKeepAliveCallback)callback {
    // 检查params是否为字典类型
    if (!params || ![params isKindOfClass:[NSDictionary class]]) {
        if (callback) {
            callback(@{@"status": @"error", @"error": @"参数格式错误"}, NO);
        }
        return;
    }
    
    // 获取必要参数
    NSString *urlString = params[@"url"];
    NSString *path = params[@"path"];
    
    // 获取可选参数 - 表单字段名
    NSString *fieldName = params[@"fieldName"];
    if (!fieldName || [fieldName isEqualToString:@""]) {
        fieldName = @"file"; // 默认使用"file"作为字段名
    }
    
    // 获取可选参数 - 附加表单数据
    NSDictionary *formData = nil;
    if (params[@"data"] && [params[@"data"] isKindOfClass:[NSDictionary class]]) {
        formData = params[@"data"];
    }
    
    // 获取可选参数 - 自定义请求头
    NSDictionary *headers = nil;
    if (params[@"headers"] && [params[@"headers"] isKindOfClass:[NSDictionary class]]) {
        headers = params[@"headers"];
    }
    
    // 参数验证
    if (!urlString || !path || [urlString isEqualToString:@""] || [path isEqualToString:@""]) {
        if (callback) {
            callback(@{@"status": @"error", @"error": @"参数错误，请提供有效的URL和图片路径"}, NO);
        }
        return;
    }
    
    // 检查文件是否存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        if (callback) {
            callback(@{@"status": @"error", @"error": @"图片文件不存在"}, NO);
        }
        return;
    }
    
    // 读取图片数据
    NSData *imageData = [NSData dataWithContentsOfFile:path];
    if (!imageData) {
        if (callback) {
            callback(@{@"status": @"error", @"error": @"图片数据读取失败"}, NO);
        }
        return;
    }
    
    // 创建请求
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    // 创建唯一的boundary
    NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    // 设置自定义请求头
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]] && ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]])) {
                [request setValue:[obj description] forHTTPHeaderField:key];
            }
        }];
    }
    
    // 准备请求体数据
    NSMutableData *body = [NSMutableData data];
    
    // 添加其他表单数据
    if (formData) {
        [formData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isKindOfClass:[NSString class]]) {
                NSString *value = [obj description]; // 将任何类型转换为字符串
                [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"%@\r\n", value] dataUsingEncoding:NSUTF8StringEncoding]];
            }
        }];
    }
    
    // 添加图片数据
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fieldName, [path lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:imageData];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 结束标记
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 设置请求体
    [request setHTTPBody:body];
    
    // 创建会话配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    // 创建上传任务
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:body
                                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(@{@"status": @"error", @"error": error.localizedDescription}, NO);
                }
            });
            return;
        }
        
        // 检查HTTP响应状态码
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(@{@"status": @"error", @"error": [NSString stringWithFormat:@"服务器返回错误状态码: %ld", (long)httpResponse.statusCode]}, NO);
                }
            });
            return;
        }
        
        // 尝试解析响应数据
        id jsonObject = nil;
        NSString *responseString = nil;
        
        if (data) {
            NSError *jsonError = nil;
            jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (!jsonObject) {
                // 如果不是JSON，尝试作为字符串读取
                responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
        
        // 准备回调结果
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        result[@"status"] = @"success";
        result[@"statusCode"] = @(httpResponse.statusCode);
        
        if (jsonObject) {
            result[@"data"] = jsonObject;
        } else if (responseString) {
            result[@"data"] = responseString;
        }
        
        // 回调结果
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(result, NO);
            }
        });
    }];
    
    // 启动上传任务
    [uploadTask resume];
}

@end
