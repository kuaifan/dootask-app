package app.eeui.umeng.ui.module;

import android.os.Handler;
import android.os.Looper;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.umeng.message.IUmengCallback;
import com.umeng.message.PushAgent;
import com.umeng.message.UTrack;
import com.umeng.message.common.inter.ITagManager;
import com.umeng.message.tag.TagManager;

import java.util.List;

import app.eeui.framework.extend.base.WXModuleBase;
import app.eeui.framework.ui.eeui;
import app.eeui.umeng.ui.entry.eeuiUmengEntry;

public class eeuiUmengPushModule extends WXModuleBase {

    private static Handler mSDKHandler = new Handler(Looper.getMainLooper());
    private PushAgent mPAgent;
    private PushAgent PAgent() {
        if (mPAgent == null) {
            mPAgent = PushAgent.getInstance(eeui.getApplication());
        }
        return mPAgent;
    }

    @JSMethod(uiThread = false)
    public String deviceToken(){
        return eeuiUmengEntry.deviceToken;
    }

    @JSMethod
    public void setDisplayNotificationNumber(int num) {
        PAgent().setDisplayNotificationNumber(num);
    }

    @JSMethod
    public void setNotificaitonOnForeground(boolean show) {
        PAgent().setNotificationOnForeground(show);
    }

    @JSMethod
    public void disable(final JSCallback successCallback) {
        PAgent().disable(new IUmengCallback() {
            @Override
            public void onSuccess() {
                JSONObject data = new JSONObject();
                data.put("status", "success");
                successCallback.invoke(data);
            }

            @Override
            public void onFailure(String s, String s1) {
                JSONObject data = new JSONObject();
                data.put("status", "error");
                data.put("error", s);
                successCallback.invoke(data);
            }
        });
    }

    @JSMethod
    public void enable(final JSCallback successCallback) {
        PAgent().disable(new IUmengCallback() {
            @Override
            public void onSuccess() {
                JSONObject data = new JSONObject();
                data.put("status", "success");
                successCallback.invoke(data);
            }

            @Override
            public void onFailure(String s, String s1) {
                JSONObject data = new JSONObject();
                data.put("status", "error");
                data.put("error", s);
                successCallback.invoke(data);
            }
        });
    }

    @JSMethod
    public void addTag(String tag, final JSCallback successCallback) {
        PAgent().getTagManager().addTags(new TagManager.TCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final ITagManager.Result result) {
                JSONObject data = new JSONObject();
                data.put("status", isSuccess ? "success": "error");
                data.put("remain", isSuccess ? result.remain : 0);
                successCallback.invoke(data);
            }
        }, tag);
    }

    @JSMethod
    public void deleteTag(String tag, final JSCallback successCallback) {
        PAgent().getTagManager().deleteTags(new TagManager.TCallBack() {
            @Override
            public void onMessage(boolean isSuccess, final ITagManager.Result result) {
                JSONObject data = new JSONObject();
                data.put("status", isSuccess ? "success": "error");
                data.put("remain", isSuccess ? result.remain : 0);
                successCallback.invoke(data);
            }
        }, tag);
    }

    @JSMethod
    public void listTag(final JSCallback successCallback) {
        PAgent().getTagManager().getTags(new TagManager.TagListCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final List<String> result) {
                mSDKHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        JSONObject data = new JSONObject();
                        data.put("status", isSuccess ? "success": "error");
                        data.put("lists", resultToList(result));
                        successCallback.invoke(data);
                    }
                });
            }
        });
    }

    @JSMethod
    public void addAlias(String alias, String aliasType, final JSCallback successCallback) {
        PAgent().addAlias(alias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final String message) {
                JSONObject data = new JSONObject();
                data.put("status", isSuccess ? "success": "error");
                successCallback.invoke(data);
            }
        });
    }

    @JSMethod
    public void addExclusiveAlias(String exclusiveAlias, String aliasType, final JSCallback successCallback) {
        PAgent().setAlias(exclusiveAlias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final String message) {
                JSONObject data = new JSONObject();
                data.put("status", isSuccess ? "success": "error");
                successCallback.invoke(data);
            }
        });
    }

    @JSMethod
    public void deleteAlias(String alias, String aliasType, final JSCallback successCallback) {
        PAgent().deleteAlias(alias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(boolean isSuccess, String s) {
                JSONObject data = new JSONObject();
                data.put("status", isSuccess ? "success": "error");
                successCallback.invoke(data);
            }
        });
    }

    private JSONArray resultToList(List<String> result){
        JSONArray list = new JSONArray();
        if (result != null) {
            list.addAll(result);
        }
        return list;
    }
}
