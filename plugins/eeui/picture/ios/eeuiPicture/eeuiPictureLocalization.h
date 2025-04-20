//
//  eeuiPictureLocalization.h
//  eeuiPicture
//
//  Created on 2025-04-20.
//  Copyright 2025 WeexEEUI. All rights reserved.
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

/**
 设置当前使用的语言
 @param language 语言代码，可选值:
                'zh-Hans' (简体中文)
                'zh-Hant' (繁体中文)
                'zh-HK' (香港繁体)
                'en' (英语)
                'en-GB' (英式英语)
                'ja' (日语)
                'ko' (韩语)
                'de' (德语)
                'id' (印尼语)
                'fr' (法语)
                'ru' (俄语)
                传入 nil 则使用系统语言
 */
+ (void)setCurrentLanguage:(NSString * _Nullable)language;

/**
 获取当前使用的语言
 @return 当前语言代码
 */
+ (NSString *)currentLanguage;

/**
 获取支持的语言列表
 @return 支持的语言代码数组
 */
+ (NSArray<NSString *> *)supportedLanguages;

@end

NS_ASSUME_NONNULL_END
