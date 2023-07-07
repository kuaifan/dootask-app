package eeui.android.eeuiAgoro.component;

import static io.agora.rtc2.video.VideoCanvas.RENDER_MODE_HIDDEN;

import android.content.Context;
import android.util.Log;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.taobao.weex.WXSDKInstance;
import com.taobao.weex.ui.action.BasicComponentData;
import com.taobao.weex.ui.component.WXComponent;
import com.taobao.weex.ui.component.WXComponentProp;
import com.taobao.weex.ui.component.WXVContainer;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.HashMap;

import eeui.android.eeuiAgoro.client.AgoraRtcPresenter;
import eeui.android.eeuiAgoro.client.Event;
import io.agora.rtc2.Constants;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.video.VideoCanvas;

public class eeuiAgoroComponent extends WXComponent<FrameLayout> {
    private static final String TAG = "Agora";
    private int uuid = -1;
    private FrameLayout mFrameLayout;

    private SurfaceView mSurfaceView;
    public eeuiAgoroComponent(WXSDKInstance instance, WXVContainer parent, BasicComponentData basicComponentData) {
        super(instance, parent, basicComponentData);
        Log.d(TAG, "eeuiAgoroComponent: ");
        if (!EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().register(this);
        }
    }

    @Override
    protected FrameLayout initComponentHostView(@NonNull Context context) {
        if (mFrameLayout == null){
            mFrameLayout = new FrameLayout(context);
        }
        return mFrameLayout;
    }


    @WXComponentProp(name = "uuid")
    public void uuid(int uuid) {
        this.uuid = uuid;

        HashMap map = new HashMap();
        map.put("uuid",this.uuid);
        fireEvent("load",map);//和vue文件里面对应的函数通信
    }
    /**
     * 事件响应方法
     * 接收消息
     * @param event
     */
    @Subscribe(threadMode = ThreadMode.MAIN, sticky = true)
    public void onEvent(Event event) {
        if (mFrameLayout == null){
            mFrameLayout = new FrameLayout(getContext());
        }
        Log.d(TAG,"event=>"+event.getMassage());
        if (event.getMassage().equals("local")){
            setupLocalVideo(event);
        }else {
            setupRemoteVideo(event);
        }

    }

    public void setupLocalVideo(Event event){
        int uid = event.getUid();
        Log.d(TAG,"setupLocalVideo()->"+uid);
        if (this.uuid != uid){
            return;
        }
        RtcEngine mRtcEngine = event.getRtcEngine();

        /** Sets the channel profile of the Agora RtcEngine.
         CHANNEL_PROFILE_COMMUNICATION(0): (Default) The Communication profile.
         Use this profile in one-on-one calls or group calls, where all users can talk freely.
         CHANNEL_PROFILE_LIVE_BROADCASTING(1): The Live-Broadcast profile. Users in a live-broadcast
         channel have a role as either broadcaster or audience. A broadcaster can both send and receive streams;
         an audience can only receive streams.*/

        if (mSurfaceView == null) {
            mSurfaceView = new SurfaceView(getContext());
            if (mSurfaceView == null) {
                Log.d(TAG, "mSurfaceView: fail ");
                return;
            }
            // Add to the local container
            mFrameLayout.addView(mSurfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            //Setup local video to render your local camera preview
            mRtcEngine.setupLocalVideo(new VideoCanvas(mSurfaceView, RENDER_MODE_HIDDEN, uid));
            mRtcEngine.enableVideo();

            if (AgoraRtcPresenter.getInstance().currentVideo) {

                mRtcEngine.startPreview();
            }else {
                mRtcEngine.enableLocalVideo(false);
            }

            // Set audio route to microPhone
            mRtcEngine.setDefaultAudioRoutetoSpeakerphone(true);
        }

    }

    public void setupRemoteVideo(Event event){
        int uid = event.getUid();
        Log.d(TAG,"setupRemoteVideo()->"+uid);
        if (this.uuid != uid){
            return;
        }
        RtcEngine mRtcEngine = event.getRtcEngine();
        if (mSurfaceView == null) {
            mSurfaceView = new SurfaceView(getContext());
            // Add to the local container
            mFrameLayout.addView(mSurfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            mSurfaceView.setZOrderMediaOverlay(true);
        }
        //远端绑定

        int res = mRtcEngine.setupRemoteVideo(new VideoCanvas(mSurfaceView, VideoCanvas.RENDER_MODE_HIDDEN, uid));
        Log.d(TAG, "setupRemoteVideo: "+res);
        Log.d(TAG, "setupRemoteVideo: "+mFrameLayout.getChildCount());
    }
    @Override
    public void onActivityDestroy() {
        super.onActivityDestroy();
        Log.d(TAG,"onActivityDestroy");
//        if (!EventBus.getDefault().isRegistered(this)) {
//
//        }
//        EventBus.getDefault().unregister(this);
    }

}
