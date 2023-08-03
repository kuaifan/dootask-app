//
//  ChatModel.h
//
//
//  Created by JSONConverter on 2023/06/09.
//  Copyright © 2023年 JSONConverter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MJExtension/MJExtension.h>

@class ChatModelData;
@class ChatModelDataExtend;

@interface ChatModel: NSObject
@property (nonatomic, strong) NSArray<ChatModelData *> *data;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, assign) NSInteger ret;
@end

@interface ChatModelData: NSObject
@property (nonatomic, strong) ChatModelDataExtend *extend;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *url;

@property (nonatomic, assign) BOOL select;
@end

@interface ChatModelDataExtend: NSObject
@property (nonatomic, assign) int upload_file_id;
@property (nonatomic, assign) int dialog_ids;
@property (nonatomic, copy) NSString *text_type;
@property (nonatomic, assign) int reply_id;
@end
