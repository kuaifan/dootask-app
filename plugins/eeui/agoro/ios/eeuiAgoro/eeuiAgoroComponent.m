//
//  eeuiAgoroComponent.m
//  fzqDatepicker
//
//  Created by Hitosea-005 on 2021/4/12.
//

#import "eeuiAgoroComponent.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

@interface eeuiAgoroComponent()

@property (nonatomic, strong)UIView *subView;
@property (nonatomic, strong)AgoraRtcVideoCanvas *caves;
@property (nonatomic, strong)AgoraRtcVideoCanvas *localCaves;
@property (nonatomic, weak  )AgoraRtcEngineKit *enginKit;
@property (nonatomic, assign)NSInteger uuid;
@property (nonatomic, copy) NSDictionary *attr;

@end

@implementation eeuiAgoroComponent

//Tips: 不能导出同步方法，因为主线程线程会等待
WX_PlUGIN_EXPORT_COMPONENT(eeuiAgoro-com, eeuiAgoroComponent)
WX_EXPORT_METHOD(@selector(animate))//导出方法

-(instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance{
    self = [super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance];
    if (self) {
        //初始化不会渲染视图 必须到viewdidload中渲染才会生效
        self.attr = attributes;
        [self addListen];
    }
    return self;
}

//初始化完成调用
-(void)viewDidLoad{
    [super viewDidLoad];
    NSInteger uuid = [self.attr[@"uuid"] integerValue];
    
    //如何向前端发送时间
    [self fireEvent:@"load" params:@{@"uuid":@(uuid)}];
    
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)animate{
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)addListen{
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stream:) name:@"agoroStream" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(joinstream:) name:@"joinStream" object:nil];
    
}

//升级属性时需要手动渲染 nodejs只提供交互不提供渲染服务
-(void)updateAttributes:(NSDictionary *)attributes{
    [super updateAttributes:attributes];
    self.color = attributes[@"color"];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)stream:(NSNotification *)notification {
    NSDictionary *params = (NSDictionary *)notification.object;
    /*
     NSDictionary *params = @{
         @"uuid": @(uid),
         @"object": self.engkit,
     };
     */
    NSInteger uid = [params[@"uuid"] integerValue];
    if ([self.attr[@"uuid"] integerValue] != uid) {
        return;
    }
    
    AgoraRtcEngineKit *constKit = (AgoraRtcEngineKit *)params[@"object"];
    
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = uid;
    videoCanvas.view = self.view;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    self.localCaves = videoCanvas;
    [constKit setupLocalVideo:videoCanvas];
    
    [constKit startPreview];
}

- (void)joinstream:(NSNotification *)notification {
    NSDictionary *params = (NSDictionary *)notification.object;
    
    NSInteger uid = [params[@"uuid"] integerValue];
    if ([self.attr[@"uuid"] integerValue] != uid || self.caves != nil) {
        return;
    }
    AgoraRtcEngineKit *constKit = (AgoraRtcEngineKit *)params[@"object"];
    
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = uid;
    videoCanvas.view = self.view;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    [constKit setupRemoteVideo:videoCanvas];
    self.caves = videoCanvas;
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"agoroStream" object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"joinStream" object:nil];
   
    
}

@end
