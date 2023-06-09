//
//  ChatModel.m
//
//
//  Created by JSONConverter on 2023/06/09.
//  Copyright © 2023年 JSONConverter. All rights reserved.
//

#import "ChatModel.h"

@implementation ChatModel 
+ (NSDictionary *)mj_objectClassInArray {
    return @{@"data": [ChatModelData class]};
}

@end

@implementation ChatModelData 
@end

@implementation ChatModelDataExtend 
@end
