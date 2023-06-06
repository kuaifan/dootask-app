//
//  UserModel.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/6.
//

#import "UserModel.h"

@implementation UserModel
-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"user_id"];
    }
}
@end
