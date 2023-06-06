//
//  UserModel.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UserModel : NSObject
@property (nonatomic, strong)NSString *type;
@property (nonatomic, strong)NSString *name;
@property (nonatomic, strong)NSString *avatar;
@property (nonatomic, assign)NSInteger user_id;

@property (nonatomic, assign)BOOL select;

@end

NS_ASSUME_NONNULL_END
