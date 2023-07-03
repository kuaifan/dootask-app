package eeui.android.eeuiAgoro.client;

import android.content.Context;
import android.util.Log;


import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.bridge.JSCallback;
import com.yanzhenjie.permission.AndPermission;
import com.yanzhenjie.permission.runtime.Permission;

import org.greenrobot.eventbus.EventBus;

import io.agora.rtc.IRtcEngineEventHandler;
import io.agora.rtc.RtcEngine;

public class AgoraRtcPresenter {
    private static final String TAG = AgoraRtcPresenter.class.getCanonicalName();
    private static AgoraRtcPresenter sAgoraRtcPresenter;

    private RtcEngine mRtcEngine;
    private JSCallback mJSCallback;
    private JSCallback mLocalJSCallback;
    private JSCallback mStatusCallback;

    private JSCallback mJointCallback;
    private Context mContext;
    private boolean isLeaveChannel = false;

    private AgoraRtcPresenter(){}

    public static synchronized AgoraRtcPresenter getInstance(){
        if (sAgoraRtcPresenter == null){
            sAgoraRtcPresenter = new AgoraRtcPresenter();
        }
        return sAgoraRtcPresenter;
    }
    /**
     * 初始化
     */
    public void init(Context context, final String object, final JSCallback callback){
        mContext = context;
        mJSCallback = callback;
        JSONObject jsonObject = JSONObject.parseObject(object);
        String appId = jsonObject.getString("id");
        if (mRtcEngine != null) {
            return;
        }
        try {
            mRtcEngine = RtcEngine.create(context, appId, iRtcEngineEventHandler);
            if (mRtcEngine != null){
                mRtcEngine.enableVideo();
                Log.d(TAG,"RtcEngine 初始化成功");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void blindLocal(Context context, final int uid){
        if (!isLeaveChannel){
            //Permission.Group.STORAGE,
            boolean hasPermissions = AndPermission.hasPermissions(context, Permission.Group.STORAGE, Permission.Group.MICROPHONE, Permission.Group.CAMERA);
            Log.d(TAG,"hasPermissions="+hasPermissions);
            if (hasPermissions){
                setupLocalVideo(uid);
            }else {
                AndPermission.with(context)
                        .runtime()
                        .permission(Permission.Group.STORAGE, Permission.Group.MICROPHONE, Permission.Group.CAMERA )
                        .onGranted( permissions -> {
                            // Permissions Granted
                            setupLocalVideo(uid);
                        }).onDenied(permissions ->{
                            // 判断用户是不是不再显示权限弹窗了，若不再显示的话进入权限设置页
                            Log.d(TAG,"权限已被拒绝,需到设置页面进行手动设置权限！");
                        }).start();
            }
        }else {
            isLeaveChannel = false;
        }

    }
    public void setupLocalVideo(final int uid){
        //发送事件
        EventBus.getDefault().post(new Event(uid, mRtcEngine, "local"));
    }
    /**
     * 设置远端视频
     */
    public void setupRemoteVideo(int uid){
        //发送事件
        EventBus.getDefault().post(new Event(uid, mRtcEngine, "remote"));
    }

    /**
     * 加入频道
     * @param object
     */
    public void jointChanel(String object,final JSCallback callback){

        this.mJointCallback = callback;
        String accessToken = "";
        String channelName = "";
        int uid = 0;
        JSONObject jsonObject = JSONObject.parseObject(object);
        accessToken = jsonObject.getString("token");
        channelName = jsonObject.getString("channel");
        uid = jsonObject.getIntValue("uid");
        Log.d(TAG,"jointChanel->uid->"+uid);
        // 使用 Token 加入频道。
        mRtcEngine.joinChannel(accessToken, channelName, "Extra Optional Data", uid);
    }

    /**
     * 离开频道
     */
    public void leaveChannel(){
        this.isLeaveChannel = true;

        int leave = mRtcEngine.leaveChannel();

        Log.d(TAG,"leave="+leave);
        if (leave == 0) {
            mLocalJSCallback.invokeAndKeepAlive(-1);
        }
    }

    public void localStatusCallback(final JSCallback callback){
        mLocalJSCallback = callback;
    }

    public void statusCallback(final JSCallback callback){
        mStatusCallback = callback;
    }

    /**
     * 释放资源
     */
    public void destroy(){
        if (mRtcEngine != null){
            mRtcEngine.stopPreview();
            mRtcEngine.destroy();
            mRtcEngine = null;
            mJSCallback = null;
            mLocalJSCallback = null;
        }
        if (sAgoraRtcPresenter != null){
            sAgoraRtcPresenter = null;
        }
    }

    /**
     * 切换前置/后置摄像头
     */
    public int switchCamera(){
        int code = mRtcEngine.switchCamera();
        return code;
    }

    /**
     * 启用视频模块
     */
    public int enableVideo(){
        mRtcEngine.startPreview();

        return mRtcEngine.enableLocalVideo(true);
    }
    /**
     * 启用视频模块
     */
    public int disableVideo(){
        mRtcEngine.stopPreview();
        return mRtcEngine.enableLocalVideo(false);
    }

    /**
     * 启用音频模块
     */
    public int enableAudio(){
        return mRtcEngine.enableLocalAudio(true);
    }

    public int disableAudio(){
//        mRtcEngine.stopPreview();
        return mRtcEngine.enableLocalAudio(false);
    }

    public int adjustRecording(int volume){
        return mRtcEngine.adjustRecordingSignalVolume(volume);
    }
    public int localVideo(boolean mute){
        return mRtcEngine.muteLocalVideoStream(mute);
    }
    public int muteAllRemoteVideo(boolean mute){
        return mRtcEngine.muteAllRemoteVideoStreams(mute);
    }
    public int muteAllRemoteAudioStreams(boolean mute){
        return mRtcEngine.muteAllRemoteVideoStreams(mute);
    }
    public int muteRemoteAudioStream(int uid, boolean mute){
        return mRtcEngine.muteRemoteAudioStream(uid,mute);
    }
    public int muteRemoteVideoStream(int uid, boolean mute){
        return mRtcEngine.muteRemoteVideoStream(uid,mute);
    }

    /**
     * 开启/关闭扬声器播放。
     * @param enable
     * true：开启。音频路由为扬声器。
     * false：关闭。音频路由为听筒。
     * @return
     */
    public int setEnableSpeakerphone(boolean enable){
        return mRtcEngine.setEnableSpeakerphone(enable);
    }
    public void breadcast(){
    }

    private final IRtcEngineEventHandler iRtcEngineEventHandler = new IRtcEngineEventHandler() {

        /**Reports a warning during SDK runtime.
         * Warning code: https://docs.agora.io/en/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_i_rtc_engine_event_handler_1_1_warn_code.html*/
        @Override
        public void onWarning(int warn){
            Log.w(TAG, String.format("onWarning code %d message %s", warn, RtcEngine.getErrorDescription(warn)));
        }

        /**Reports an error during SDK runtime.
         * Error code: https://docs.agora.io/en/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_i_rtc_engine_event_handler_1_1_error_code.html*/
        @Override
        public void onError(int err){
            Log.e(TAG, String.format("onError code %d message %s", err, RtcEngine.getErrorDescription(err)));
        }

        /**Occurs when a user leaves the channel.
         * @param stats With this callback, the application retrieves the channel information,
         *              such as the call duration and statistics.*/
        @Override
        public void onLeaveChannel(RtcStats stats) {
            super.onLeaveChannel(stats);
            Log.d(TAG, String.format("local user %d leaveChannel!"));
        }

        @Override
        public void onRejoinChannelSuccess(String channel, int uid, int elapsed) {
            super.onRejoinChannelSuccess(channel, uid, elapsed);
            Log.d(TAG, String.format("重新加入频道"));
        }

        /**Occurs when the local user joins a specified channel.
         * The channel name assignment is based on channelName specified in the joinChannel method.
         * If the uid is not specified when joinChannel is called, the server automatically assigns a uid.
         * @param channel Channel name
         * @param uid User ID
         * @param elapsed Time elapsed (ms) from the user calling joinChannel until this callback is triggered*/
        @Override
        public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
            Log.i(TAG, String.format("onJoinChannelSuccess channel %s uid %d", channel, uid));
            JSONObject json = new JSONObject();
            json.put("channel",channel);
            json.put("uuid",uid);
            json.put("elapsed",elapsed);
            mJointCallback.invoke(json);
        }

        @Override
        public void onRemoteVideoStateChanged(int uid, int state, int reason, int elapsed) {
            super.onRemoteVideoStateChanged(uid, state, reason, elapsed);
            Log.i(TAG, "onRemoteVideoStateChanged->" + uid + ", state->" + state + ", reason->" + reason);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("type","video");
            jsonObject.put("uuid",uid);
            jsonObject.put("status",state);
            mStatusCallback.invokeAndKeepAlive(jsonObject);
        }

        @Override
        public void onRemoteAudioStateChanged(int uid, int state, int reason, int elapsed) {
            super.onRemoteAudioStateChanged(uid, state, reason, elapsed);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("type","audio");
            jsonObject.put("uuid",uid);
            jsonObject.put("status",state);
            mStatusCallback.invokeAndKeepAlive(jsonObject);
        }

        @Override
        public void onLocalAudioStateChanged(int state, int error) {
            super.onLocalAudioStateChanged(state, error);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("type","audio");
            jsonObject.put("uuid","me");
            jsonObject.put("status",state);
            mStatusCallback.invokeAndKeepAlive(jsonObject);
        }

        @Override
        public void onLocalVideoStateChanged(int localVideoState, int error) {
            super.onLocalVideoStateChanged(localVideoState, error);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("type","video");
            jsonObject.put("uuid","me");
            jsonObject.put("status",localVideoState);
            mStatusCallback.invokeAndKeepAlive(jsonObject);
        }

        /**
         * 远端用户加入当前频道回调
         * @param uid
         * @param elapsed
         */
        @Override
        public void onUserJoined(int uid, int elapsed) {
            Log.d(TAG,"onUserJoined ->"+uid);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("action","joint");
            jsonObject.put("uuid",uid);
            if (mJSCallback != null){
                mJSCallback.invokeAndKeepAlive(jsonObject);
            }

        }

        /**
         * 远端用户离开当前频道回调
         * @param uid
         * @param reason
         */
        @Override
        public void onUserOffline(int uid, int reason) {
            super.onUserOffline(uid, reason);
            isLeaveChannel = true;
            Log.d(TAG,"onUserOffline-> "+uid);
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("action","leave");
            jsonObject.put("uuid",uid);
            if (mJSCallback != null){
                mJSCallback.invokeAndKeepAlive(jsonObject);
            }
        }
    };
}
