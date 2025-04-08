//
//  eeuiNavMaskManager.m
//  eeui
//

#import "eeuiNavMaskManager.h"

@interface NavMaskInfo : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UIView *bottomView;

@end

@implementation NavMaskInfo
@end

@interface eeuiNavMaskManager()

@property (nonatomic, strong) NSMutableArray<NavMaskInfo *> *maskList;
@property (nonatomic, assign) NSInteger maskCounter;

@end

@implementation eeuiNavMaskManager

+ (instancetype)sharedIntstance {
    static eeuiNavMaskManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[eeuiNavMaskManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maskList = [NSMutableArray array];
        _maskCounter = 0;
    }
    return self;
}

- (NSString *)addNavMask:(NSString *)color {
    // 递增计数器生成唯一名称
    _maskCounter++;
    NSString *name = [NSString stringWithFormat:@"navMask_%ld", (long)_maskCounter];
    
    // 创建遮罩信息对象
    NavMaskInfo *maskInfo = [[NavMaskInfo alloc] init];
    maskInfo.name = name;
    
    // 解析颜色
    UIColor *uiColor = [self colorWithHexString:color];
    maskInfo.color = uiColor;
    
    // 获取主窗口
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        NSArray<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes.allObjects;
        for (UIScene *scene in scenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    if (!keyWindow) {
        return name;
    }
    
    // 创建顶部状态栏遮罩
    CGFloat topHeight = 0;
    if (@available(iOS 11.0, *)) {
        topHeight = keyWindow.safeAreaInsets.top;
    } else {
        topHeight = 20;
    }
    
    if (topHeight > 0) {
        UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, keyWindow.bounds.size.width, topHeight)];
        topView.backgroundColor = uiColor;
        // 设置初始透明度为0，准备淡入动画
        topView.alpha = 0.0;
        [keyWindow addSubview:topView];
        
        // 添加淡入动画
        [UIView animateWithDuration:0.15 animations:^{
            topView.alpha = 1.0;
        }];
        
        maskInfo.topView = topView;
    }
    
    // 创建底部安全区域遮罩
    CGFloat bottomHeight = 0;
    if (@available(iOS 11.0, *)) {
        bottomHeight = keyWindow.safeAreaInsets.bottom;
    }
    
    if (bottomHeight > 0) {
        UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, keyWindow.bounds.size.height - bottomHeight, keyWindow.bounds.size.width, bottomHeight)];
        bottomView.backgroundColor = uiColor;
        // 设置初始透明度为0，准备淡入动画
        bottomView.alpha = 0.0;
        [keyWindow addSubview:bottomView];
        
        // 添加淡入动画
        [UIView animateWithDuration:0.15 animations:^{
            bottomView.alpha = 1.0;
        }];
        
        maskInfo.bottomView = bottomView;
    }
    
    // 保存遮罩信息
    [_maskList addObject:maskInfo];
    
    return name;
}

- (void)removeNavMask:(NSString *)name {
    if (name == nil) {
        [self removeNavMask];
        return;
    }
    
    NavMaskInfo *targetMask = nil;
    for (NavMaskInfo *maskInfo in _maskList) {
        if ([maskInfo.name isEqualToString:name]) {
            targetMask = maskInfo;
            break;
        }
    }
    
    if (targetMask) {
        [self removeMaskViews:targetMask];
        [_maskList removeObject:targetMask];
    }
}

- (void)removeNavMask {
    // 移除最后添加的遮罩
    if (_maskList.count > 0) {
        NavMaskInfo *lastMask = [_maskList lastObject];
        [self removeMaskViews:lastMask];
        [_maskList removeLastObject];
    }
}

- (void)removeAllNavMasks {
    for (NavMaskInfo *maskInfo in _maskList) {
        [self removeMaskViews:maskInfo];
    }
    [_maskList removeAllObjects];
}

#pragma mark - Helper Methods

- (void)removeMaskViews:(NavMaskInfo *)maskInfo {
    // 移除顶部视图（带淡出动画）
    if (maskInfo.topView) {
        [UIView animateWithDuration:0.15 animations:^{
            maskInfo.topView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [maskInfo.topView removeFromSuperview];
                maskInfo.topView = nil;
            }
        }];
    }
    
    // 移除底部视图（带淡出动画）
    if (maskInfo.bottomView) {
        [UIView animateWithDuration:0.15 animations:^{
            maskInfo.bottomView.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [maskInfo.bottomView removeFromSuperview];
                maskInfo.bottomView = nil;
            }
        }];
    }
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    // 默认颜色
    if (!hexString || hexString.length == 0) {
        return [UIColor clearColor];
    }
    
    // 去除字符串中的空格和#前缀
    NSString *colorString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([colorString hasPrefix:@"#"]) {
        colorString = [colorString substringFromIndex:1];
    }
    
    // 处理简写形式 #RGB，转换为 #RRGGBB
    if (colorString.length == 3) {
        NSString *r = [colorString substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [colorString substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [colorString substringWithRange:NSMakeRange(2, 1)];
        colorString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
    }
    
    // 处理 RGBA 格式
    CGFloat alpha = 1.0;
    if (colorString.length == 8) {
        NSString *alphaHex = [colorString substringWithRange:NSMakeRange(6, 2)];
        unsigned int alphaInt;
        [[NSScanner scannerWithString:alphaHex] scanHexInt:&alphaInt];
        alpha = alphaInt / 255.0;
        colorString = [colorString substringToIndex:6];
    }
    
    // 标准 RGB 颜色解析
    if (colorString.length == 6) {
        unsigned int rgbValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&rgbValue];
        
        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                              green:((rgbValue & 0x00FF00) >> 8) / 255.0
                               blue:(rgbValue & 0x0000FF) / 255.0
                              alpha:alpha];
    }
    
    // 无法解析，返回透明色
    return [UIColor clearColor];
}

@end
