//
//  PathNavigationView.h
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import <UIKit/UIKit.h>

@protocol NavigationViewDelegate <NSObject>

- (void)selectWithArray:(NSArray *)pathArray;

@end

@interface PathNavigationView : UIView

@property (nonatomic, weak)id<NavigationViewDelegate> delegate;
@property (nonatomic, strong)NSMutableArray *navArray;

-(instancetype)initWithArray:(NSArray *)pathArray;
@end


