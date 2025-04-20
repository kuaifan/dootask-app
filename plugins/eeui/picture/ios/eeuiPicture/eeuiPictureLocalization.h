//
//  eeuiPictureLocalization.h
//  eeuiPicture
//
//  Created on 2025-04-20.
//  Copyright © 2025 WeexEEUI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface eeuiPictureLocalization : NSObject

/**
 获取本地化字符串
 @param key 本地化字符串键
 @return 本地化后的字符串
 */
+ (NSString *)localizedStringForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
