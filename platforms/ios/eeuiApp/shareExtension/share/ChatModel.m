//
//  ChatModel.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import "ChatModel.h"

@implementation ChatModel

-(void)setValue:(id)value forUndefinedKey:(NSString *)key{
    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"dialog_id"];
    }
}

@end
