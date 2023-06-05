//
//  ChatModel.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import <Foundation/Foundation.h>

@interface ChatModel : NSObject

@property (nonatomic, copy)NSString *nickName;
@property (nonatomic, copy)NSString *avatar;
@property (nonatomic, copy)NSString *type;

@property (nonatomic, assign)BOOL isSelect;

@end


