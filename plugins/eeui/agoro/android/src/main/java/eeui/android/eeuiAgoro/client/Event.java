package eeui.android.eeuiAgoro.client;

import io.agora.rtc2.RtcEngine;

public class Event {
    private int uid;
    private RtcEngine mRtcEngine;
    private String massage;
    private String accessToken;
    private String channelName;

    public Event(int uid, RtcEngine mRtcEngine, String massage) {
        this.uid = uid;
        this.mRtcEngine = mRtcEngine;
        this.massage = massage;
    }
    public Event(int uid, RtcEngine mRtcEngine, String massage, String accessToken, String channelName) {
        this.uid = uid;
        this.mRtcEngine = mRtcEngine;
        this.massage = massage;
        this.accessToken = accessToken;
        this.channelName = channelName;
    }
    public int getUid() {
        return uid;
    }

    public void setUid(int uuid) {
        this.uid = uuid;
    }

    public RtcEngine getRtcEngine() {

        return mRtcEngine;
    }

    public void setRtcEngine(RtcEngine rtcEngine) {
        mRtcEngine = rtcEngine;
    }

    public String getMassage() {
        return massage;
    }

    public void setMassage(String massage) {
        this.massage = massage;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String getChannelName() {
        return channelName;
    }

    public void setChannelName(String channelName) {
        this.channelName = channelName;
    }
}
