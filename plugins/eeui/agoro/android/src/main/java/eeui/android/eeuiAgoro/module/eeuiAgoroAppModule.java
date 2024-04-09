package eeui.android.eeuiAgoro.module;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.media.AudioManager;
import android.widget.Toast;

import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;

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
    public void initialWithParam(final String object, final JSCallback callback) {
        AgoraRtcPresenter.getInstance().init(mWXSDKInstance.getContext(), object, callback);
    }

    @JSMethod
    public void blindLocal(final int uid) {
        AgoraRtcPresenter.getInstance().blindLocal(mWXSDKInstance.getContext(), uid);
    }

    @JSMethod
    public void blindRemote(final int uid) {
        AgoraRtcPresenter.getInstance().setupRemoteVideo(uid);
    }

    @JSMethod
    public void jointChanel(final String object, final JSCallback callback) {
        AgoraRtcPresenter.getInstance().jointChanel(object, callback);
    }

    /**
     * 切换前置/后置摄像头
     */
    @JSMethod(uiThread = false)
    public int switchCamera() {
        return AgoraRtcPresenter.getInstance().switchCamera();
    }

    @JSMethod(uiThread = false)
    public int enableAudio(boolean enable) {
        AudioManager audioManager = (AudioManager) getActivity().getSystemService(Context.AUDIO_SERVICE);
        int beforeVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        int result;
        if (enable) {
            result = AgoraRtcPresenter.getInstance().enableAudio();
        } else {
            result = AgoraRtcPresenter.getInstance().disableAudio();
        }
        int afterVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        if (beforeVolume != afterVolume) {
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, beforeVolume, 0);
        }
        return result;
    }

    @JSMethod(uiThread = false)
    public int enableVideo(boolean enable) {
        if (enable) {
            return AgoraRtcPresenter.getInstance().enableVideo();
        } else {
            return AgoraRtcPresenter.getInstance().disableVideo();
        }
    }

    @JSMethod(uiThread = false)
    public int adjustRecording(int volume) {
        return AgoraRtcPresenter.getInstance().adjustRecording(volume);
    }

    @JSMethod(uiThread = false)
    public int localVideo(boolean mute) {
        return AgoraRtcPresenter.getInstance().localVideo(mute);
    }

    @JSMethod(uiThread = false)
    public int muteAllRemoteVideo(boolean mute) {
        return AgoraRtcPresenter.getInstance().muteAllRemoteVideo(mute);
    }

    @JSMethod(uiThread = false)
    public int muteAllRemoteAudioStreams(boolean mute) {
        return AgoraRtcPresenter.getInstance().muteAllRemoteAudioStreams(mute);
    }

    /**
     * 静音远程音频流
     */
    @JSMethod(uiThread = false)
    public int muteRemoteAudioStream(int uid, boolean mute) {
        return AgoraRtcPresenter.getInstance().muteRemoteAudioStream(uid, mute);
    }

    @JSMethod(uiThread = false)
    public int muteRemoteVideoStream(int uid, boolean mute) {
        return AgoraRtcPresenter.getInstance().muteRemoteVideoStream(uid, mute);
    }

    /**
     * 扬声器
     */
    @JSMethod(uiThread = false)
    public int loudspeaker(Boolean speaker) {
        return AgoraRtcPresenter.getInstance().setEnableSpeakerphone(speaker);
    }

    @JSMethod
    public void breadcast() {
        AgoraRtcPresenter.getInstance().breadcast();
    }

    /**
     * 离开频道
     */
    @JSMethod
    public void leaveChannel() {
        AgoraRtcPresenter.getInstance().leaveChannel();
    }

    @JSMethod
    public void destroy() {
        AgoraRtcPresenter.getInstance().destroy();
    }

    @JSMethod
    public void statusCallback(final JSCallback callback) {
        AgoraRtcPresenter.getInstance().statusCallback(callback);
    }

    @JSMethod
    public void localStatusCallback(final JSCallback callback) {
        AgoraRtcPresenter.getInstance().localStatusCallback(callback);
    }
}
