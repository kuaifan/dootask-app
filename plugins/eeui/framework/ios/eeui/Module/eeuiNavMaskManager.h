//
//  eeuiNavMaskManager.h
//  eeui
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface eeuiNavMaskManager : NSObject

/**
 * 单例方法
 */
+ (instancetype)sharedIntstance;

/**
 * 添加导航遮罩层
 * @param color 遮罩层颜色
 * @return 返回遮罩层标识名称
 */
- (NSString *)addNavMask:(NSString *)color;

/**
 * 移除导航遮罩层
 * @param name 遮罩层标识名称，不传则移除最后一个添加的遮罩
 */
- (void)removeNavMask:(nullable NSString *)name;

/**
 * 移除最后添加的导航遮罩层
 */
- (void)removeNavMask;

/**
 * 移除所有导航遮罩层
 */
- (void)removeAllNavMasks;

@end

NS_ASSUME_NONNULL_END
