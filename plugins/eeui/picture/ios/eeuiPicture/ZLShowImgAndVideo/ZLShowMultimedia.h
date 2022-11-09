//
//  ZLShowMultimedia.h
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/15.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ZLMediaInfo.h"
#import "ZLMediaView.h"


@interface ZLShowMultimedia : UIViewController

@property(nonatomic,strong)NSArray    *infos;
@property(nonatomic,assign)NSInteger  currentIndex;

-(void)show;

@end
