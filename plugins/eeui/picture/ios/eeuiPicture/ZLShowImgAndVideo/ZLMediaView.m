//
//  ZLMediaView.m
//  ZLhowImgAndVideo
//
//  Created by ZhenwenLi on 2018/5/15.
//  Copyright © 2018年 lizhenwen. All rights reserved.
//

#import "ZLMediaView.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
//#import "UIImage+GIF.h"
#import "UIImage+ZLGIF.h"
@interface ZLMediaView ()
{
    BOOL _doubleTap;
    UIImageView *_imageView;
    ZLMediaLoadingView *_mediaLoadingView;
    //视频播放器
    AVPlayer *_player;
    //播放视图
    AVPlayerLayer *playerLayer;
    //第一次显示
    BOOL _firstShow;
    
    UIView   *tabBarView;
    UIButton *playBut;
    UIProgressView *_progress;
}

@end

@implementation ZLMediaView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        // 图片
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_imageView];
        
        // 进度条
        _mediaLoadingView = [[ZLMediaLoadingView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        
        
        //第一次显示
        _firstShow=YES;
        
        playBut = [UIButton buttonWithType:UIButtonTypeCustom];
        playBut.frame=CGRectMake(0, 0, 66, 66);
        playBut.backgroundColor=[UIColor clearColor];
        playBut.center=CGPointMake(frame.size.width/2.0, frame.size.height/2.0);
        [playBut setImage:[UIImage imageNamed:@"PlayButtonOverlayLarge"] forState:UIControlStateNormal];
        [playBut addTarget:self action:@selector(onPlayBut) forControlEvents:UIControlEventTouchUpInside];
        
        tabBarView = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-90, frame.size.width, 40)];
        tabBarView.backgroundColor=[UIColor clearColor];
        
        UILabel *lab1=[[UILabel alloc]initWithFrame:CGRectMake(10, 0, 40, 40)];
        lab1.text=@"00:00";
        lab1.textColor=[UIColor whiteColor];
        lab1.font=[UIFont systemFontOfSize:11];
        lab1.tag=90;
        [tabBarView addSubview:lab1];

        UILabel *lab2=[[UILabel alloc]initWithFrame:CGRectMake(frame.size.width-50, 0, 40, 40)];
        lab2.text=@"00:00";
        lab2.textColor=[UIColor whiteColor];
        lab2.font=[UIFont systemFontOfSize:11];
        lab2.tag=91;
        lab2.textAlignment=NSTextAlignmentRight;
        [tabBarView addSubview:lab2];
        
        _progress=[[UIProgressView alloc]initWithFrame:CGRectMake(50, 19, frame.size.width-100, 2)];
        _progress.progress=0.0;
        _progress.trackTintColor=[UIColor grayColor];
        _progress.progressTintColor=[UIColor whiteColor];
        [tabBarView addSubview:_progress];
        
        
        
        
        // 属性
        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        // 监听点击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTap.delaysTouchesBegan = YES;
        singleTap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTap];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchPhoto) name:@"switchPhoto" object:nil];
    }
    return self;
}

-(void)switchPhoto
{
    if (_player) {
        [_player pause];
        playBut.hidden=NO;
        tabBarView.hidden=YES;
    }
}

-(void)onPlayBut
{//播放 视频音频
    if (_player) {
        playBut.hidden=YES;
        _progress.progress=0;
        tabBarView.hidden=NO;
        //播放
        [_player seekToTime:CMTimeMakeWithSeconds(0, 1)];//设置播放位置1000 为帧率
        [_player play];
    }
}

-(void)showMedia
{
    if (_firstShow) {
        //如果是第一次显示
        if (_info.isLocal) {//如果是本地文件：
            //如果是图片
            if (_info.type == ZLMediaInfoTypePhoto) {
                _imageView.image=self.info.image;
                [self adjustFrame];
            }else if (_info.type == ZLMediaInfoTypeVideo||_info.type==ZLMediaInfoTypeAudio){
                //如果是本地视频：
                // 直接显示进度条
                [_mediaLoadingView showLoading];
                [self addSubview:_mediaLoadingView];
                
                
                [self addSubview:playBut];
                [self addSubview:tabBarView];
                
                _progress.progress=0;
                tabBarView.hidden=NO;
                playBut.hidden=YES;
                
                //第一步，初始化小图：
                _imageView.frame=self.bounds;
                
                if (_info.type==ZLMediaInfoTypeVideo) {
                    _imageView.image=self.info.insetsImageView.image;
                    __unsafe_unretained ZLMediaView *mediaView = self;
                    CGSize imgSize=self.bounds.size;
                    
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_async(globalQueue, ^{
                        //子线程异步执行下载任务，防止主线程卡顿
//                        UIImage *img=[mediaView firstFrameWithVideoURL:[NSURL URLWithString:mediaView.info.url] size:imgSize];
                        UIImage *img=[mediaView getVideoPreViewImage:[NSURL fileURLWithPath:mediaView.info.url]];
                        dispatch_queue_t mainQueue = dispatch_get_main_queue();
                        //异步返回主线程，根据获取的数据，更新UI
                        dispatch_async(mainQueue, ^{
                            self->_imageView.image=img;
                        });
                    });
                }else{
                    if (self.info.image) {
                        _imageView.image=self.info.image;
                    }else{
                        _imageView.image=self.info.insetsImageView.image;
                    }
                }
                
                // 加载网络视频
                NSURL *movieUrl = [NSURL fileURLWithPath:_info.url];
                
                // 创建 AVPlayer 播放器
                _player = [AVPlayer playerWithURL:movieUrl];
                
                // 将 AVPlayer 添加到 AVPlayerLayer 上
                playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
                
                // 设置播放页面大小
                playerLayer.frame = _imageView.bounds;
                // 设置画面缩放模式
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                // 在视图上添加播放器
                [_imageView.layer addSublayer:playerLayer];
                _player.volume=1;
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                
                // 开始播放
                [_player play];
                
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
                [self addProgressObserver];
                [self addObserverToPlayerItem:_player.currentItem];
                
                
                _firstShow=NO;
                
                
            }else if (_info.type == ZLMediaInfoTypeGif){
                //如果是gig
                UIImage *image=[UIImage zl_animatedGIFWithData:[NSData dataWithContentsOfFile:_info.url]];
                
                
                _imageView.image=image;
                
                
                [self adjustFrame];
            }
        }else{
            
            if (_info.type == ZLMediaInfoTypePhoto) {
                //设置初始小图
                _imageView.image=self.info.insetsImageView.image;
                
                // 直接显示进度条
                [_mediaLoadingView showLoading];
                [self addSubview:_mediaLoadingView];
                self.scrollEnabled = NO;
                
                __unsafe_unretained ZLMediaView *mediaView = self;
                __unsafe_unretained ZLMediaLoadingView *loading = _mediaLoadingView;
                
                [_imageView sd_setImageWithURL:[NSURL URLWithString:_info.url] placeholderImage:self.info.insetsImageView.image options:SDWebImageRetryFailed|SDWebImageLowPriority|SDWebImageProgressiveDownload progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                    if (receivedSize > kMinProgress) {
                        loading.progress = (float)receivedSize/expectedSize;
                    }
                } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    [mediaView photoDidFinishLoadWithImage:image];
                }];
            }else if (_info.type == ZLMediaInfoTypeVideo||_info.type == ZLMediaInfoTypeAudio){
                //网络视频
                // 直接显示进度条
                [self addSubview:_mediaLoadingView];
                [_mediaLoadingView showLoading];
                
                
                
                [self addSubview:playBut];
                [self addSubview:tabBarView];
                
                _progress.progress=0;
                tabBarView.hidden=NO;
                playBut.hidden=YES;

                //第一步，初始化小图：
                _imageView.frame=self.bounds;
                
                
                if (_info.type==ZLMediaInfoTypeVideo) {
                    _imageView.image=self.info.insetsImageView.image;
                    __unsafe_unretained ZLMediaView *mediaView = self;
                    CGSize imgSize=self.bounds.size;
                    
                    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_async(globalQueue, ^{
                        //子线程异步执行下载任务，防止主线程卡顿
                        UIImage *img=[mediaView firstFrameWithVideoURL:[NSURL URLWithString:mediaView.info.url] size:imgSize];
                        dispatch_queue_t mainQueue = dispatch_get_main_queue();
                        //异步返回主线程，根据获取的数据，更新UI
                        dispatch_async(mainQueue, ^{
                            self->_imageView.image=img;
                        });
                    });
                }else{
                    if (self.info.image) {
                        _imageView.image=self.info.image;
                    }else{
                        _imageView.image=self.info.insetsImageView.image;
                    }
                }
                

                // 加载网络视频
                NSURL *movieUrl = [NSURL URLWithString:_info.url];
                
                // 创建 AVPlayer 播放器
                _player = [AVPlayer playerWithURL:movieUrl];
                
                // 将 AVPlayer 添加到 AVPlayerLayer 上
                playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
                
                // 设置播放页面大小
                playerLayer.frame = _imageView.bounds;
                
                // 设置画面缩放模式
                playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                // 在视图上添加播放器
                [_imageView.layer addSublayer:playerLayer];
                
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                
                _player.volume=1;
                // 开始播放
                [_player play];
                
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
                [self addProgressObserver];
                [self addObserverToPlayerItem:_player.currentItem];
                
                _firstShow=NO;
                
            }else if (_info.type == ZLMediaInfoTypeGif){
                NSLog(@"======>>>>>>>>>>>>>>>");
                //如果是gig
                _imageView.image=_info.insetsImageView.image;
                [self adjustFrame];
                __unsafe_unretained ZLMediaView *mediaView = self;
                
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); dispatch_async(globalQueue, ^{
                    //子线程异步执行下载任务，防止主线程卡顿
                    NSData *data=[NSData dataWithContentsOfURL:[NSURL URLWithString:mediaView.info.url]];
                    dispatch_queue_t mainQueue = dispatch_get_main_queue();
                    //异步返回主线程，根据获取的数据，更新UI
                    dispatch_async(mainQueue, ^{
                        self->_imageView.image=[UIImage zl_animatedGIFWithData:data];
                        
                        [mediaView adjustFrame];
                    });
                });
                
            }
        }
        
        
        
    }else{
        if (_info.type == ZLMediaInfoTypePhoto||_info.type == ZLMediaInfoTypeGif) {
            [self adjustFrame];
        }else if (_info.type == ZLMediaInfoTypeVideo||_info.type == ZLMediaInfoTypeAudio){
            [self onPlayBut];
        }
        
        
        
    }
}
// 播放完成通知
- (void)playbackFinished:(NSNotification *)notification{
    tabBarView.hidden=YES;
    playBut.hidden=NO;
}
#pragma mark - KVO
- (void)addProgressObserver{
    AVPlayerItem *playerItem =_player.currentItem;
    //这里设置每秒执行一次
    __weak __typeof(self) weakself = self;
    id timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        [weakself setTimeTotal:total :current];
    }];
    NSLog(@"[][]%@",timeObserver);
}
-(void)setTimeTotal:(float)total :(float)current
{
    UILabel *lab1=(UILabel *)[self viewWithTag:90];
    UILabel *lab2=(UILabel *)[self viewWithTag:91];
    
    lab2.text=[self timeStr:total];
    lab1.text=[self timeStr:current];
    
    _progress.progress=current/total;
}
-(NSString *)timeStr:(float)s
{
    NSInteger index=(NSInteger)s;
    if (s-(NSInteger)s>=0.5) {
        index+=1;
    }
    
    if (index<60) {
        return [[NSString stringWithFormat:@"00:%2ld",(long)index] stringByReplacingOccurrencesOfString:@" " withString:@"0"];
    }else if (index/60<60){
        return [[NSString stringWithFormat:@"%2ld:%2ld",index/60,index%60] stringByReplacingOccurrencesOfString:@" " withString:@"0"];
    }else{
        return @"59:59";
    }
}



#pragma mark 加载完毕
- (void)photoDidFinishLoadWithImage:(UIImage *)image
{
    if (image) {
        _info.image = image;
        _imageView.image=image;
        self.scrollEnabled = YES;
        
        [_mediaLoadingView removeFromSuperview];
        
        if ([self.mediaViewDelegate respondsToSelector:@selector(mediaViewImageFinishLoad:)]) {
            [self.mediaViewDelegate mediaViewImageFinishLoad:self];
        }
    } else {
        [_mediaLoadingView showFailure];
    }
    
    // 设置缩放比例
    [self adjustFrame];
}













#pragma mark 调整frame
- (void)adjustFrame
{
    if (_imageView.image == nil) return;
    
    // 基本尺寸参数
    CGSize boundsSize = self.bounds.size;
    CGFloat boundsWidth = boundsSize.width;
    CGFloat boundsHeight = boundsSize.height;
    
    CGSize imageSize = _imageView.image.size;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    
    // 设置伸缩比例
    CGFloat minScale = boundsWidth / imageWidth;
    if (minScale > 1) {
        minScale = 1.0;
    }
    CGFloat maxScale = 3.0;
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];
    }
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;
    
    CGRect imageFrame = CGRectMake(0, 0, boundsWidth, imageHeight * boundsWidth / imageWidth);
    // 内容尺寸
    self.contentSize = CGSizeMake(0, imageFrame.size.height);
    
    // y值
    if (imageFrame.size.height < boundsHeight) {
        imageFrame.origin.y = floorf((boundsHeight - imageFrame.size.height) / 2.0);
    } else {
        imageFrame.origin.y = 0;
    }
    
    if (_firstShow) {
        _firstShow = NO; // 已经显示过了
        
        _imageView.frame = [_info.insetsImageView convertRect:_info.insetsImageView.bounds toView:nil];
        
        [UIView animateWithDuration:0.3 animations:^{
            self->_imageView.frame = imageFrame;
        } completion:^(BOOL finished) {
            // 设置底部的小图片
           
        }];
    }else{
        _imageView.frame = imageFrame;
    }
}


#pragma mark - 手势处理
- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    _doubleTap = NO;
    [self performSelector:@selector(hide) withObject:nil afterDelay:0.3];
}
-(void)dissMedia
{
    if (_player) {
        //移除监听
        [self removeObserverFromPlayerItem:_player.currentItem];
        
        [_player pause];
        _player = nil;
    }
    [_progress removeFromSuperview];
    //移除进度显示
    [tabBarView removeFromSuperview];
    //移除播放按钮
    [playBut removeFromSuperview];
    // 移除进度条
    [_mediaLoadingView removeFromSuperview];
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)hide
{
    if (_doubleTap) return;
    
    if (_player) {
        //移除监听
        [self removeObserverFromPlayerItem:_player.currentItem];
        
        [_player pause];
        _player = nil;
    }
    if (playerLayer) {
        [playerLayer removeFromSuperlayer];
    }
    
    [_progress removeFromSuperview];
    //移除进度显示
    [tabBarView removeFromSuperview];
    //移除播放按钮
    [playBut removeFromSuperview];
    // 移除进度条
    [_mediaLoadingView removeFromSuperview];
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.contentOffset = CGPointZero;
    
    // 清空底部的小图
    CGFloat duration = 0.15;
    __unsafe_unretained ZLMediaView *mediaView = self;
    [UIView animateWithDuration:duration + 0.1 animations:^{
        self->_imageView.frame = [self.info.insetsImageView convertRect:self.info.insetsImageView.bounds toView:nil];
        // 通知代理
        if ([mediaView.mediaViewDelegate respondsToSelector:@selector(mediaViewSingleTap:)]) {
            [mediaView.mediaViewDelegate mediaViewSingleTap:self];
        }
    } completion:^(BOOL finished) {
        // 通知代理
        if ([mediaView.mediaViewDelegate respondsToSelector:@selector(mediaViewDidEndZoom:)]) {
            [mediaView.mediaViewDelegate mediaViewDidEndZoom:self];
        }
    }];
}


- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    _doubleTap = YES;
    if (_info.type==ZLMediaInfoTypePhoto) {//如果是图片放大缩小
        CGPoint touchPoint = [tap locationInView:self];
        if (self.zoomScale == self.maximumZoomScale) {
            [self setZoomScale:self.minimumZoomScale animated:YES];
        } else {
            [self zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
        }
    }else if (_info.type == ZLMediaInfoTypeVideo||_info.type == ZLMediaInfoTypeAudio){
        //如果是视频播放暂停
        if (tabBarView.hidden) {
            [_player play];
            tabBarView.hidden=NO;
            playBut.hidden=YES;
        }else{
            [_player pause];
            tabBarView.hidden=YES;
            playBut.hidden=NO;
        }
    }
}

- (void)dealloc
{
    // 取消请求
    [_imageView sd_setImageWithURL:[NSURL URLWithString:@"file:///abc"]];
    if (_player) {
        [_player pause];
        _player = nil;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (_info.type == ZLMediaInfoTypePhoto||_info.type == ZLMediaInfoTypeGif) {
        return _imageView;
    }
    return nil;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (_info.type == ZLMediaInfoTypePhoto||_info.type == ZLMediaInfoTypeGif) {
        CGRect imageViewFrame = _imageView.frame;
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        if (imageViewFrame.size.height > screenBounds.size.height) {
            imageViewFrame.origin.y = 0.0f;
        } else {
            imageViewFrame.origin.y = (screenBounds.size.height - imageViewFrame.size.height) / 2.0;
        }
        _imageView.frame = imageViewFrame;
    }
    
}
#pragma mark ---- 获取图片第一帧
- (UIImage *)firstFrameWithVideoURL:(NSURL *)url size:(CGSize)size {
    // 获取视频第一帧
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(size.width, size.height);
    NSError *error = nil;
    CGImageRef img = [generator copyCGImageAtTime:CMTimeMake(0, 10) actualTime:NULL error:&error];
    {
        return [UIImage imageWithCGImage:img];
        
    }
    return nil;
}

// 获取视频第一帧
- (UIImage*) getVideoPreViewImage:(NSURL *)path
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;  
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}



/**
 *  给AVPlayerItem添加监控
 *  @param playerItem AVPlayerItem对象
 */
- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem{
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserverFromPlayerItem:(AVPlayerItem *)playerItem{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}
/**
 *  通过KVO监控播放器状态
 *  @param keyPath 监控属性
 *  @param object  监视器
 *  @param change  状态改变
 *  @param context 上下文
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void*)context{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
            NSLog(@"开始播放,视频总长度:%.2f",CMTimeGetSeconds(playerItem.duration));
        }else if(status == AVPlayerStatusUnknown){
            NSLog(@"%@",@"AVPlayerStatusUnknown");
        }else if (status == AVPlayerStatusFailed){
            NSLog(@"%@",@"AVPlayerStatusFailed");
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
//        if (self.currentTime < (startSeconds + durationSeconds + 8)) {
//            self.viewLogin.hidden  = YES;
//            if ([self.btnPause.titleLabel.text isEqualToString:@"暂停"]) {
//                [_player play];
//            }
//        }else{
//            self.viewLogin.hidden = NO;
//        }
//        self.slider.bufferValue = totalBuffer/self.totalTime;
        _mediaLoadingView.hidden=NO;
        _mediaLoadingView.progress=totalBuffer/CMTimeGetSeconds(playerItem.duration);
//        if (totalBuffer>=CMTimeGetSeconds(playerItem.duration)) {
//
//            NSLog(@"==============================");
//            _mediaLoadingView.hidden=YES;
//            _mediaLoadingView.progress=0;
//        }
//        NSLog(@"缓冲：%f-------%f",totalBuffer,CMTimeGetSeconds(playerItem.duration));
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){

    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){

    }
}



@end
