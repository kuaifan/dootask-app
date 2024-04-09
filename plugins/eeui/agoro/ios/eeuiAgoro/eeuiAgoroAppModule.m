//
//  eeuiAgoroAppModule.m
//  Pods
//

#import "eeuiAgoroAppModule.h"
#import "eeuiAgoroComponent.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

@interface eeuiAgoroAppModule () <AgoraRtcEngineDelegate>

@property (nonatomic, strong)AgoraRtcEngineKit *engkit;
@property (nonatomic, weak  )eeuiAgoroComponent *localCom;
// @property (strong, nonatomic) NSMutableArray<VideoSession *> *videoSessions;
@property (nonatomic, copy  )WXModuleKeepAliveCallback retBlock;
@property (nonatomic, copy  )WXModuleKeepAliveCallback statusBlock;
@property (nonatomic, copy  )WXModuleKeepAliveCallback localStatusBlock;
@property (nonatomic, strong)NSMutableArray<NSNumber *> * waitArray;

@end

@implementation eeuiAgoroAppModule

@synthesize weexInstance;

WX_PlUGIN_EXPORT_MODULE(eeuiAgoro, eeuiAgoroAppModule)
WX_EXPORT_METHOD(@selector(initialWithParam:callback:))
WX_EXPORT_METHOD(@selector(blindLocal:))
WX_EXPORT_METHOD(@selector(blindRemote:))
WX_EXPORT_METHOD(@selector(jointChanel:callback:))
WX_EXPORT_METHOD(@selector(breadcast))
WX_EXPORT_METHOD(@selector(leaveChannel))
WX_EXPORT_METHOD(@selector(destroy))
WX_EXPORT_METHOD(@selector(statusCallback:))
WX_EXPORT_METHOD(@selector(localStatusCallback:))
// 其他操作
WX_EXPORT_METHOD_SYNC(@selector(switchCamera))
WX_EXPORT_METHOD_SYNC(@selector(enableVideo:))
WX_EXPORT_METHOD_SYNC(@selector(enableAudio:))
WX_EXPORT_METHOD_SYNC(@selector(adjustRecording:))
WX_EXPORT_METHOD_SYNC(@selector(localVideo:))
WX_EXPORT_METHOD_SYNC(@selector(localAudio:))
WX_EXPORT_METHOD_SYNC(@selector(muteAllRemoteVideo:))
WX_EXPORT_METHOD_SYNC(@selector(muteAllRemoteAudioStreams:))
WX_EXPORT_METHOD_SYNC(@selector(muteRemoteAudioStream:volume:))
WX_EXPORT_METHOD_SYNC(@selector(muteRemoteVideoStream:mute:))


/// 初始化
/// - Parameters:
///   - params: 初始化参数
///   - callback: 回调函数
- (void)initialWithParam:(NSDictionary *)params callback:(WXModuleKeepAliveCallback)callback {
    
    if (self.engkit) {
        return;
    }
    
    NSString *paramid = params[@"id"];
    
    self.retBlock = callback;
    self.engkit = [AgoraRtcEngineKit sharedEngineWithAppId:paramid delegate:self];
    
//    self.engkit.delegate = self;
    // Default mode is disableVideo
    
    // Set up the configuration such as dimension, frame rate, bit rate and orientation
    [self.engkit setChannelProfile:AgoraChannelProfileCommunication];
    [self.engkit enableVideo];
    AgoraVideoEncoderConfiguration *encoderConfiguration =
    [[AgoraVideoEncoderConfiguration alloc] initWithSize:AgoraVideoDimension960x720
                                               frameRate:AgoraVideoFrameRateFps30
                                                 bitrate:AgoraVideoBitrateStandard
                                         orientationMode:AgoraVideoOutputOrientationModeAdaptative
                                              mirrorMode:AgoraVideoMirrorModeAuto];
    [self.engkit setVideoEncoderConfiguration:encoderConfiguration];
    
    [self.engkit setClientRole:AgoraClientRoleBroadcaster];
    
    [self.engkit setLogFile:[self loggerFile]];    // VideoSession *localSession = [VideoSession localSession];
}

- (NSString *)loggerFile{
    
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [path stringByAppendingString:@"/agorasdk.log"];
}

- (void)statusCallback:(WXModuleKeepAliveCallback)callback {
    self.statusBlock = callback;
}
- (void)localStatusCallback:(WXModuleKeepAliveCallback)callback {
    self.localStatusBlock = callback;
}

- (void)jointChanel:(NSDictionary *)params callback:(WXModuleKeepAliveCallback)callback {
    
    NSString *token = params[@"token"];
    NSString *channelID = params[@"channel"];
    NSInteger uuid = [params[@"uuid"] integerValue];
    
    int ret = [self.engkit joinChannelByToken:token channelId:channelID info:nil uid:uuid joinSuccess:^(NSString *channel, NSUInteger uid, NSInteger elapsed) {
        // Join channel "demoChannel1"
        callback(@{@"channel": channel, @"uuid":@(uid), @"elapsed":@(elapsed)}, YES);
    }];
    // The UID database is maintained by your app to track which users joined which channels. If not assigned (or set to 0), the SDK will allocate one and returns it in joinSuccessBlock callback. The App needs to record and maintain the returned value as the SDK does not maintain it.
    NSLog(@"%d", ret);
       
    // [self.engkit setEnableSpeakerphone:YES];
       
}

- (void)breadcast{
    
    if (self.waitArray.count > 0) {
        for (NSNumber * number in self.waitArray) {
            NSDictionary *params = @{
                @"uuid": number,
                @"object": self.engkit
            };
            
            [NSNotificationCenter.defaultCenter postNotificationName:@"joinStream" object:params userInfo:nil];
        }
        
        [self.waitArray removeAllObjects];
    }
}

- (void)leaveChannel{
    __weak typeof(self) weakself = self;
    [self.engkit leaveChannel:^(AgoraChannelStats * _Nonnull state) {
        
        weakself.localStatusBlock ? weakself.localStatusBlock(@-1, YES): nil;
        
    }];
    
}

- (void)blindLocal:(NSInteger)uid {
    [self.engkit setupLocalVideo:nil];
    
    NSDictionary *params = @{
        @"uuid": @(uid),
        @"object": self.engkit,
    };
    
    [NSNotificationCenter.defaultCenter postNotificationName:@"agoroStream" object:params userInfo:nil];
    
}

- (void)blindRemote:(NSInteger)uid {
    NSDictionary *params = @{
        @"uuid": @(uid),
        @"object": self.engkit,
    };
    [NSNotificationCenter.defaultCenter postNotificationName:@"joinStream" object:params userInfo:nil];
    
}

- (void)destroy{
    [AgoraRtcEngineKit destroy];
    self.engkit = nil;
    self.localStatusBlock = nil;
    self.statusBlock = nil;
}

- (int)switchCamera {
    return [self.engkit switchCamera];
}

- (int)enableVideo:(BOOL)enable {
    if (enable) {
        [self.engkit startPreview];
        return [self.engkit enableLocalVideo:enable];
    } else {
        [self.engkit stopPreview];
        return [self.engkit enableLocalVideo:enable];
    }
}

- (int)enableAudio:(BOOL)enable {
    return [self.engkit enableLocalAudio:enable];
}

- (int)adjustRecording:(int)volume{
    
    return [self.engkit adjustRecordingSignalVolume:volume];
}

- (int)localVideo:(BOOL)mute{
    if (mute) {
        [self.engkit startPreview];
        
    } else {
        [self.engkit stopPreview];
    }
    
    return [self.engkit muteLocalVideoStream:mute];
}

- (int)localAudio:(BOOL)mute{
    return [self.engkit muteLocalAudioStream:mute];
}

- (int)muteAllRemoteVideo:(BOOL)mute{
    return [self.engkit muteAllRemoteVideoStreams:mute];
}

- (int)muteAllRemoteAudio:(BOOL)mute{
    return [self.engkit muteAllRemoteAudioStreams:mute];
}

- (int)muteRemoteAudioStream:(NSUInteger)uid volume:(int)volume{
    return [self.engkit adjustUserPlaybackSignalVolume:uid volume:volume];
}

- (int)muteRemoteVideoStream:(NSUInteger)uid mute:(BOOL)mute{
    return [self.engkit muteRemoteVideoStream:uid mute:mute];
}

#pragma mark - AgoraRtcEngineDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
//    if (self.remoteVideo.hidden) {
//        self.remoteVideo.hidden = NO;
//    }
//
//    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
//    videoCanvas.uid = uid;
//    // Since we are making a simple 1:1 video chat app, for simplicity sake, we are not storing the UIDs. You could use a mechanism such as an array to store the UIDs in a channel.
//
//    videoCanvas.view = self.remoteVideo;
//    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
//    [self.agoraKit setupRemoteVideo:videoCanvas];
//    // Bind remote video stream to view
//    [self.agoraKit startPreview];
    
    NSLog(@"didJoinedOfUid:%ld",uid);
    NSDictionary *params = @{
        @"uuid": [NSNumber numberWithInteger:uid],
        @"action": @"joint",
    };
    
    // [self.waitArray addObject:@(uid)];
    self.retBlock ? self.retBlock(params, YES): nil;
    
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine localVideoStateChangedOfState:(AgoraVideoLocalState)state error:(AgoraLocalVideoStreamError)error sourceType:(AgoraVideoSourceType)sourceType{
    self.statusBlock?self.statusBlock(@{@"uuid": @"me", @"status": @(state), @"type":@"video"}, YES): nil;
}
-(void)rtcEngine:(AgoraRtcEngineKit *)engine localAudioStateChanged:(AgoraAudioLocalState)state error:(AgoraAudioLocalError)error {
    self.statusBlock?self.statusBlock(@{@"uuid": @"me", @"status": @(state), @"type":@"audio"}, YES): nil;
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStateChangedOfUid:(NSUInteger)uid state:(AgoraVideoRemoteState)state reason:(AgoraVideoRemoteReason)reason elapsed:(NSInteger)elapsed
{
    NSLog(@"remoteVideoStateChangedOfUid %@ %@ %@", @(uid), @(state), @(reason));
    self.statusBlock?self.statusBlock(@{@"uuid": @(uid), @"status": @(state), @"type":@"video"}, YES): nil;
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine remoteAudioStateChangedOfUid:(NSUInteger)uid state:(AgoraAudioRemoteState)state reason:(AgoraAudioRemoteReason)reason elapsed:(NSInteger)elapsed{
    NSLog(@"remoteAudioStateChangedOfUid %@ %@ %@", @(uid), @(state), @(reason));
    self.statusBlock?self.statusBlock(@{@"uuid": @(uid), @"status": @(state), @"type":@"audio"}, YES): nil;
}

/// Callback to handle an user offline event.
/// @param engine - RTC engine instance
/// @param uid - user id
/// @param reason - why is the user offline
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    // self.remoteVideo.hidden = true;
    
    NSDictionary *params = @{
        @"uuid": @(uid),
        @"action": @"leave",
    };
    self.retBlock?self.retBlock(params,YES): nil;
}

/// A callback to handle muting of the audio
/// @param engine  - RTC engine instance
/// @param muted  - YES if muted; NO otherwise
/// @param uid  - user id
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    NSLog(@"didVideoMuted%d,uid:%lu",muted,(unsigned long)uid);
}

- (void)rtcEngine:(AgoraRtcEngineKit* _Nonnull)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid{
    NSLog(@"didAudioMuted%d,uid:%lu",muted,(unsigned long)uid);
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didLeaveChannelWithStats:(AgoraChannelStats *)stats{
    NSLog(@"didLeaveChannel");
    self.localStatusBlock ? self.localStatusBlock(@-1, YES): nil;
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed{
    NSLog(@"didJoinChannel");
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode{
    NSLog(@"didOccurError %ld", (long)errorCode);
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine connectionChangedToState:(AgoraConnectionState)state reason:(AgoraConnectionChangedReason)reason{
    self.localStatusBlock?self.localStatusBlock(@(state), YES): nil;
    if (state == AgoraConnectionStateFailed) {
        __weak typeof(self) weakself = self;
        [engine leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
            weakself.localStatusBlock ? weakself.localStatusBlock(@-1, YES): nil;
        }];
    }
    
    NSLog(@"connectionChangedToState %ld reason%ld", (long)state, (long)reason);
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine didUserInfoUpdatedWithUserId:(NSUInteger)uid userInfo:(AgoraUserInfo *)userInfo{
    
    NSLog(@"didUserInfoUpdatedWithUserId %ld userInfo%@", (long)uid, userInfo.userAccount);
}
#pragma mark - getter
-(NSMutableArray<NSNumber *> *)waitArray{
    if (!_waitArray) {
        _waitArray = [NSMutableArray new];
    }
    return _waitArray;
}

- (void)dealloc {
    NSLog(@"Agora ---- dealloc ----");
}

@end
