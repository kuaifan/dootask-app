package eeui.android.eeuiAgoro.module;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.util.Log;
import android.widget.Toast;

import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;

import org.greenrobot.eventbus.EventBus;

import app.eeui.framework.extend.base.WXModuleBase;
import eeui.android.eeuiAgoro.client.AgoraRtcPresenter;

public class eeuiAgoroAppModule extends WXModuleBase {

    /**
     * 简单演示
     * @param msg
     */
    @JSMethod
    public void simple(String msg) {
        Toast.makeText(getContext(), msg, Toast.LENGTH_SHORT).show();
    }

    /**
     * 回调演示
     * @param msg
     * @param callback
     */
    @JSMethod
    public void call(final String msg, final JSCallback callback) {
        AlertDialog.Builder localBuilder = new AlertDialog.Builder(getContext());
        localBuilder.setTitle("demo");
        localBuilder.setMessage(msg);
        localBuilder.setPositiveButton("确定", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if (callback != null) {
                    callback.invoke("返回：" + msg); //多次回调请使用invokeAndKeepAlive
                }
            }
        });
        AlertDialog dialog = localBuilder.setCancelable(false).create();
        dialog.show();
    }

    /**
     * 同步返回演示
     * @param msg
     * @return
     */
    @JSMethod(uiThread = false)
    public String retMsg(String msg) {
        return "返回：" + msg;
    }

    /**
     * @param object
     * @param callback
     */
    @JSMethod
    public void initialWithParam(final String object, final JSCallback callback){
        AgoraRtcPresenter.getInstance().init(mWXSDKInstance.getContext(), object, callback);
    }

    @JSMethod
    public void blindLocal(final int uid){
        AgoraRtcPresenter.getInstance().blindLocal(mWXSDKInstance.getContext(),uid);
    }

    @JSMethod
    public void blindRemote(final int uid){
        AgoraRtcPresenter.getInstance().setupRemoteVideo(uid);
    }

    @JSMethod
    public void jointChanel(final String object,final JSCallback callback){
        AgoraRtcPresenter.getInstance().jointChanel(object,callback);
    }

    /**
     * 切换前置/后置摄像头
     */
    @JSMethod
    public void switchCamera(){
        AgoraRtcPresenter.getInstance().switchCamera();
    }

    @JSMethod
    public int enableAudio(boolean enable){

        if (enable) {
            return AgoraRtcPresenter.getInstance().enableAudio();
        } else {
            return AgoraRtcPresenter.getInstance().disableAudio();
        }
    }

    @JSMethod
    public int enableVideo(boolean enable){
        if (enable) {
            return AgoraRtcPresenter.getInstance().enableVideo();
        }else {
            return AgoraRtcPresenter.getInstance().disableVideo();
        }

    }
    @JSMethod
    public int adjustRecording(int volume){
        return AgoraRtcPresenter.getInstance().adjustRecording(volume);
    }
    @JSMethod
    public int localVideo(boolean mute){
        return AgoraRtcPresenter.getInstance().localVideo(mute);
    }
    @JSMethod
    public int muteAllRemoteVideo(boolean mute){
        return AgoraRtcPresenter.getInstance().muteAllRemoteVideo(mute);
    }
    @JSMethod
    public int muteAllRemoteAudioStreams(boolean mute){
        return AgoraRtcPresenter.getInstance().muteAllRemoteAudioStreams(mute);
    }

    /**
     * 静音远程音频流
     */
    @JSMethod
    public int muteRemoteAudioStream(int uid, boolean mute){
        return AgoraRtcPresenter.getInstance().muteRemoteAudioStream(uid, mute);
    }
    @JSMethod
    public int muteRemoteVideoStream(int uid, boolean mute){
        return AgoraRtcPresenter.getInstance().muteRemoteVideoStream(uid,mute);
    }
    /**
     * 扬声器
     */
    @JSMethod
    public int loudspeaker(Boolean speaker) {
        return AgoraRtcPresenter.getInstance().setEnableSpeakerphone(speaker);
    }

    @JSMethod
    public void breadcast(){
        AgoraRtcPresenter.getInstance().breadcast();
    }

    /**
     * 离开频道
     */
    @JSMethod
    public void leaveChannel(){
        AgoraRtcPresenter.getInstance().leaveChannel();
    }

    @JSMethod
    public void destroy(){
//        EventBus.getDefault().unregister(this);
        AgoraRtcPresenter.getInstance().destroy();
    }

    @JSMethod
    public void statusCallback(final JSCallback callback){
        AgoraRtcPresenter.getInstance().statusCallback(callback);
    }

    @JSMethod
    public void localStatusCallback(final JSCallback callback){
        AgoraRtcPresenter.getInstance().localStatusCallback(callback);
    }

}
