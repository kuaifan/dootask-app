//
//  ChatCell.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/1.
//

#import <UIKit/UIKit.h>
#import "ChatModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface ChatCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *userNickLabel;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;


@property (nonatomic, strong)ChatModel *chatModel;

@end

NS_ASSUME_NONNULL_END
