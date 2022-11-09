//
//  ZLMediaInfo.h
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/15.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum ZLMediaInfoType {
    ZLMediaInfoTypePhoto = 0,
    ZLMediaInfoTypeVideo,
    ZLMediaInfoTypeGif,
    ZLMediaInfoTypeAudio
}ZLMediaInfoType;


@interface ZLMediaInfo : NSObject
//是否是本地文件 默认为NO
@property(nonatomic,assign)BOOL      isLocal;
//是否是图片
@property(nonatomic,assign)ZLMediaInfoType  type;
//图片、视频url链接
@property(nonatomic,strong)NSString  *url;
//缩略图地址
@property(nonatomic,strong)NSString  *thumbnailUrl;
//本地图片
@property(nonatomic,strong)UIImage   *image;
//本地视频路径
@property(nonatomic,strong)NSString  *localVideoUrl;
//小图image view
@property(nonatomic,strong)UIImageView *insetsImageView;

@end
