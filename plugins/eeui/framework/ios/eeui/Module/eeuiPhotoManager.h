//
//  eeuiPhotoManager.h
//  eeui
//
//  Created on 2025/03/26.
//

#import <Foundation/Foundation.h>
#import "WeexSDK.h"

@interface eeuiPhotoManager : NSObject

+ (eeuiPhotoManager *)sharedInstance;

/**
 * 获取相册最新图片
 * 同时返回缩略图和原图的路径及相关信息
 */
- (void)getLatestPhoto:(WXKeepAliveCallback)callback;

/**
 * 上传图片到指定URL
 * @param params 参数字典，包含url和path
 * @param callback 回调
 */
- (void)uploadPhoto:(NSDictionary *)params callback:(WXKeepAliveCallback)callback;

@end
