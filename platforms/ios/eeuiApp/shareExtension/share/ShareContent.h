//
//  ShareContent.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ShareContentType){
    shareContentTypeText = 0,
    shareContentTypeImage,
    shareContentTypeVideo,
    shareContentTypeOther
};

@interface ShareContent : NSObject

@property (nonatomic, strong)NSURL *fileUrl;
@property (nonatomic, assign)BOOL isDir;

@property (nonatomic, assign)ShareContentType shareType;

@end


