//
//  PathNavigationView.m
//  ShareExtension
//
//  Created by Hitosea-005 on 2023/6/5.
//

#import "PathNavigationView.h"
#import <Masonry.h>
#import "NavCell.h"
@interface PathNavigationView()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>
@property (nonatomic, strong)UICollectionView *navItem;
@property (nonatomic, strong)NSMutableArray *navArray;

@end

@implementation PathNavigationView

-(instancetype)initWithArray:(NSArray *)pathArray {
    self = [super init];
    if (self) {
        self.navArray = [pathArray mutableCopy];
        [self baseInit];
        [self monitorData];
    }
    
    return self;
}

- (void)baseInit{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.navItem = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.navItem.delegate = self;
    self.navItem.dataSource = self;
    self.navItem.backgroundColor = UIColor.yellowColor;
    [self.navItem registerNib:[UINib nibWithNibName:@"NavCell" bundle:nil] forCellWithReuseIdentifier:@"NavCell"];
    [self addSubview:self.navItem];
    
    [self.navItem mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.bottom.equalTo(self);
    }];
    
}

- (void)monitorData {
    self.navArray = [@[@"short", @"longlong11111", @"midem22", @"11", @"asasdasdasdadasdasdasdasdasdasassaaaaasdasdasdasdasdasdaaaaaasdasdasdasdasdsdsdasdasdasd"] mutableCopy];
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NavCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"NavCell" forIndexPath:indexPath];
    NSString *title = self.navArray[indexPath.row];
    cell.dirLabel.text = title;
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.navArray.count;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *title = self.navArray[indexPath.row];
    CGFloat width = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 30) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]} context:nil].size.width;
    
    return CGSizeMake(width+31, 30);
}

@end
