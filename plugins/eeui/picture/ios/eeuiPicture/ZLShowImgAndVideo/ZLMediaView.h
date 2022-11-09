//
//  ZLMediaView.h
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/15.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZLMediaInfo.h"
#import "ZLMediaLoadingView.h"

@class ZLMediaView;

@protocol ZLMediaViewDelegate <NSObject>

//图片加载完成
- (void)mediaViewImageFinishLoad:(ZLMediaView *)mediaView;
- (void)mediaViewSingleTap:(ZLMediaView *)mediaView;
- (void)mediaViewDidEndZoom:(ZLMediaView *)mediaView;

@end

@interface ZLMediaView : UIScrollView<UIScrollViewDelegate>
//媒体特征
@property(nonatomic,strong)ZLMediaInfo *info;
//代理
@property(nonatomic,assign)id<ZLMediaViewDelegate>mediaViewDelegate;

-(void)showMedia;
-(void)dissMedia;

@end
