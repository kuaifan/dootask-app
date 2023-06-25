package eeui.android.eeuiAgoro.component;

import static io.agora.rtc.video.VideoCanvas.RENDER_MODE_HIDDEN;

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
import eeui.android.eeuiAgoro.client.Event;
import io.agora.rtc.Constants;
import io.agora.rtc.IRtcEngineEventHandler;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;

public class eeuiAgoroComponent extends WXComponent<FrameLayout> {
    private static final String TAG = "Agora";
    private int uuid = -1;
    private FrameLayout mFrameLayout;

    public eeuiAgoroComponent(WXSDKInstance instance, WXVContainer parent, BasicComponentData basicComponentData) {
        super(instance, parent, basicComponentData);
        EventBus.getDefault().register(this);
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
    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onEvent(Event event) {
        if (mFrameLayout == null){
            mFrameLayout = new FrameLayout(getContext());
        }
        Log.d(TAG,"event=>"+event.getMassage());
        if (event.getMassage() == "local"){
            setupLocalVideo(event);
        }else {
            setupRemoteVideo(event);
        }

    }

    public void setupLocalVideo(Event event){
        if (mFrameLayout.getChildCount()>0){
            mFrameLayout.removeAllViews();
        }
        int uid = event.getUid();
        Log.d(TAG,"setupLocalVideo()->"+uid);
        RtcEngine mRtcEngine = event.getRtcEngine();

        /** Sets the channel profile of the Agora RtcEngine.
         CHANNEL_PROFILE_COMMUNICATION(0): (Default) The Communication profile.
         Use this profile in one-on-one calls or group calls, where all users can talk freely.
         CHANNEL_PROFILE_LIVE_BROADCASTING(1): The Live-Broadcast profile. Users in a live-broadcast
         channel have a role as either broadcaster or audience. A broadcaster can both send and receive streams;
         an audience can only receive streams.*/
        mRtcEngine.setChannelProfile(Constants.CHANNEL_PROFILE_LIVE_BROADCASTING);
        /**In the demo, the default is to enter as the anchor.*/
        mRtcEngine.setClientRole(IRtcEngineEventHandler.ClientRole.CLIENT_ROLE_BROADCASTER);
        // Enable video module
        mRtcEngine.enableVideo();

        SurfaceView surfaceView = RtcEngine.CreateRendererView(getContext());
        // Add to the local container
        mFrameLayout.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        //Setup local video to render your local camera preview
        mRtcEngine.setupLocalVideo(new VideoCanvas(surfaceView, RENDER_MODE_HIDDEN, uid));
        // Set audio route to microPhone
        mRtcEngine.setDefaultAudioRoutetoSpeakerphone(true);
        //开启视频预览
        mRtcEngine.startPreview();
    }

    public void setupRemoteVideo(Event event){
        int uid = event.getUid();
        Log.d(TAG,"setupRemoteVideo()->"+uid);
        if (this.uuid != uid){
            return;
        }
        RtcEngine mRtcEngine = event.getRtcEngine();
        SurfaceView surfaceView = RtcEngine.CreateRendererView(getContext());
        //远端绑定
        surfaceView.setZOrderMediaOverlay(true);
        mFrameLayout.addView(surfaceView,new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        mRtcEngine.setupRemoteVideo(new VideoCanvas(surfaceView, VideoCanvas.RENDER_MODE_HIDDEN, uid));
    }
    @Override
    public void onActivityDestroy() {
        super.onActivityDestroy();
        Log.d(TAG,"onActivityDestroy");
        EventBus.getDefault().unregister(this);
    }

}
