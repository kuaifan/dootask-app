//
//  ChatCell.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/1.
//

#import "ChatCell.h"

@implementation ChatCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.userImageView.layer.cornerRadius = 24;
}

-(void)setChatModel:(ChatModel *)chatModel{
    _chatModel = chatModel;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
