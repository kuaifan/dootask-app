//
//  ZLShowMultimedia.m
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/15.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import "ZLShowMultimedia.h"

//图片之间的间距
#define zlKSpacing 10


@interface ZLShowMultimedia ()<UIScrollViewDelegate,ZLMediaViewDelegate>
{
    UIScrollView  *_scrollView;
    
    UILabel       *_pageLabel;
    // 一开始的状态栏
    BOOL _statusBarHiddenInited;
}
@end

@implementation ZLShowMultimedia


- (void)loadView
{
    _statusBarHiddenInited = [UIApplication sharedApplication].isStatusBarHidden;
    // 隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    self.view = [[UIView alloc] init];
    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.backgroundColor = [UIColor blackColor];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 1.创建UIScrollView
    [self createScrollView];
    
    
}
- (void)createScrollView
{
    CGRect frame = self.view.bounds;
    frame.origin.x -= zlKSpacing;
    frame.size.width += (2 * zlKSpacing);
    _scrollView = [[UIScrollView alloc] initWithFrame:frame];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.contentSize = CGSizeMake(frame.size.width * self.infos.count, 0);
    [self.view addSubview:_scrollView];
    _scrollView.contentOffset = CGPointMake(_currentIndex * frame.size.width, 0);
    
    
    CGFloat barHeight = 94;
    CGFloat barY = self.view.frame.size.height - barHeight;
    _pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, barY, self.view.frame.size.width, barHeight)];
    _pageLabel.textColor = [UIColor whiteColor];
    _pageLabel.textAlignment = NSTextAlignmentCenter;
    _pageLabel.font=[UIFont systemFontOfSize:20];
    _pageLabel.text=[NSString stringWithFormat:@"%ld / %lu",(long)self.currentIndex+1,(unsigned long)self.infos.count];
    _pageLabel.alpha=0;
    [self.view addSubview:_pageLabel];
    
    
    for (int i=0; i<self.infos.count; i++) {
        // 调整当期页的frame
        CGRect bounds = _scrollView.bounds;
        CGRect mediaViewFrame = bounds;
        mediaViewFrame.size.width -= (2 * zlKSpacing);
        mediaViewFrame.origin.x = (bounds.size.width * i) + zlKSpacing;
        
        ZLMediaView *mediaView = [[ZLMediaView alloc]initWithFrame:mediaViewFrame];
        mediaView.tag = 1000 + i;
        mediaView.info=[self.infos objectAtIndex:i];
        mediaView.mediaViewDelegate=self;
        [_scrollView addSubview:mediaView];
    }

}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    _pageLabel.alpha=1;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _pageLabel.text=[NSString stringWithFormat:@"%d / %lu",(int)(scrollView.contentOffset.x/scrollView.frame.size.width)+1,(unsigned long)self.infos.count];
    [UIView animateWithDuration:2 animations:^{
        self->_pageLabel.alpha=0;
        
    }];
    
    [self showMedias:(int)(scrollView.contentOffset.x/scrollView.frame.size.width)];
}

-(void)showMedias:(NSInteger)index
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switchPhoto" object:nil];
    //显示
    ZLMediaView *mediaView = (ZLMediaView *)[self.view viewWithTag:1000 + index];
    [mediaView showMedia];
}





-(void)show
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.view];
    [window.rootViewController addChildViewController:self];
    
  
    [self showMedias:self.currentIndex];
}

//缩小动画开始
-(void)mediaViewSingleTap:(ZLMediaView *)mediaView
{
    [UIApplication sharedApplication].statusBarHidden = _statusBarHiddenInited;
    self.view.backgroundColor = [UIColor clearColor];
    
    [_pageLabel removeFromSuperview];
}
//缩小动画完成
-(void)mediaViewDidEndZoom:(ZLMediaView *)mediaView
{
    for (int i=0; i<self.infos.count; i++) {
        // 这里必须把所有的播放器注销掉
        ZLMediaView *mediaView = (ZLMediaView *)[self.view viewWithTag:1000+i];
        [mediaView dissMedia];
    }
    
    
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}
-(void)mediaViewImageFinishLoad:(ZLMediaView *)mediaView
{
    NSLog(@"加载完成");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
