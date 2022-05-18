package app.eeui.umeng.ui.module;


import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.umeng.analytics.MobclickAgent;

import org.json.JSONException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import app.eeui.framework.extend.base.WXModuleBase;

public class eeuiUmengAnalyticsModule extends WXModuleBase {
    @JSMethod
    public void onPageStart(String pageName) {
        MobclickAgent.onPageStart(pageName);
    }

    @JSMethod
    public void onPageEnd(String pageName) {
        MobclickAgent.onPageEnd(pageName);
    }

    @JSMethod
    public void onEvent(String eventId) {
        MobclickAgent.onEvent(getContext(), eventId);
    }

    @JSMethod
    public void onEventWithLable(String eventId, String eventLabel) {
        MobclickAgent.onEvent(getContext(), eventId, eventLabel);
    }

    @JSMethod
    public void onEventWithMap(String eventId, JSONObject map) {
        Map<String, String> rMap = new HashMap<>();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            rMap.put(entry.getKey(), String.valueOf(entry.getValue()));
        }
        MobclickAgent.onEvent(getContext(), eventId, rMap);
    }

    @JSMethod
    public void onEventObject(String eventID, JSONObject property) {
        Map<String, Object> map = new HashMap<>();
        for (Map.Entry<String, Object> entry : property.entrySet()) {
            map.put(entry.getKey(), String.valueOf(entry.getValue()));
        }
        MobclickAgent.onEventObject(getContext(), eventID, map);

    }
    @JSMethod
    public void onEventWithMapAndCount(String eventId,JSONObject map,int value) {
        Map<String, String> rMap = new HashMap<>();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            rMap.put(entry.getKey(), String.valueOf(entry.getValue()));
        }
        MobclickAgent.onEventValue(getContext(), eventId, rMap, value);
    }
    @JSMethod
    public void registerPreProperties(JSONObject map) {
        org.json.JSONObject json = new org.json.JSONObject();
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            try {
                json.put(entry.getKey(), String.valueOf(entry.getValue()));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        MobclickAgent.registerPreProperties(getContext(),json);
    }
    @JSMethod
    public void unregisterPreProperty(String propertyName) {
        MobclickAgent.unregisterPreProperty(getContext(), propertyName);

    }

    @JSMethod
    public void getPreProperties(JSCallback callback) {
        String result = MobclickAgent.getPreProperties(getContext()).toString();
        callback.invoke(result);
    }
    @JSMethod
    public void clearPreProperties() {
        MobclickAgent.clearPreProperties(getContext());

    }
    @JSMethod
    public void setFirstLaunchEvent(JSONArray array) {
        List<String> list = new ArrayList();
        for (int i = 0; i < array.size(); i++) {
            list.add(String.valueOf(array.get(i)));
        }
        MobclickAgent.setFirstLaunchEvent(getContext(), list);
    }
    /********************************U-Dplus*********************************/
    @JSMethod
    public void profileSignInWithPUID(String puid) {
        MobclickAgent.onProfileSignIn(puid);
    }

    @JSMethod
    @SuppressWarnings("unused")
    public void profileSignInWithPUIDWithProvider(String provider, String puid) {
        MobclickAgent.onProfileSignIn(provider, puid);
    }

    @JSMethod
    @SuppressWarnings("unused")
    public void profileSignOff() {
        MobclickAgent.onProfileSignOff();
    }
}
