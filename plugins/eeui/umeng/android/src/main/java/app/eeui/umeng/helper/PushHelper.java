package app.eeui.umeng.helper;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.alibaba.fastjson.JSONObject;
import com.umeng.analytics.MobclickAgent;
import com.umeng.commonsdk.UMConfigure;
import com.umeng.message.MsgConstant;
import com.umeng.message.PushAgent;
import com.umeng.message.UmengNotificationClickHandler;
import com.umeng.message.api.UPushRegisterCallback;
import com.umeng.message.entity.UMessage;

import org.android.agoo.huawei.HuaWeiRegister;
import org.android.agoo.mezu.MeizuRegister;
import org.android.agoo.oppo.OppoRegister;
import org.android.agoo.vivo.VivoRegister;
import org.android.agoo.xiaomi.MiPushRegistar;
import org.json.JSONException;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.Map;
import java.util.NoSuchElementException;

import app.eeui.framework.BuildConfig;
import app.eeui.framework.activity.PageActivity;
import app.eeui.framework.extend.bean.PageStatus;
import app.eeui.framework.extend.module.eeuiBase;
import app.eeui.framework.extend.module.eeuiJson;
import app.eeui.framework.extend.module.eeuiMap;
import app.eeui.framework.extend.module.eeuiParse;
import app.eeui.framework.ui.eeui;
import app.eeui.umeng.ui.entry.eeuiUmengEntry;

/**
 * PushSDK集成帮助类
 */
public class PushHelper {

    private static final String TAG = "eeuiUmengPushHelper";

    public static JSONObject umengConfig;
    public static String deviceToken = "";

    /**
     * 初始化参数
     */
    public static void initConfig() {
        umengConfig = eeuiJson.parseObject(eeuiBase.config.getObject("umeng").get("android"));
    }

    /**
     * 预初始化
     */
    public static void preInit(Context context) {
        UMConfigure.preInit(context, eeuiJson.getString(umengConfig, "appKey"), eeuiJson.getString(umengConfig, "channel"));
    }

    /**
     * 在子线程中执行初始化
     */
    public static void initThread(final Context context) {
        new Thread(() -> PushHelper.init(context)).start();
    }

    /**
     * 初始化
     */
    public static void init(final Context context) {
        UMConfigure.init(context, eeuiJson.getString(umengConfig, "appKey"), eeuiJson.getString(umengConfig, "channel"), UMConfigure.DEVICE_TYPE_PHONE, eeuiJson.getString(umengConfig, "messageSecret"));
        UMConfigure.setLogEnabled(BuildConfig.DEBUG); //开启日志

        //获取消息推送代理示例
        PushAgent mPushAgent = PushAgent.getInstance(context);
        mPushAgent.setNotificationOnForeground(false);  //App处于前台时不显示通知
        mPushAgent.setNotificationPlaySound(MsgConstant.NOTIFICATION_PLAY_SERVER);  //服务端控制声音

        //注册推送服务，每次调用register方法都会回调该接口
        mPushAgent.register(new UPushRegisterCallback() {
            @Override
            public void onSuccess(String deviceToken) {
                //注册成功会返回deviceToken deviceToken是推送消息的唯一标志
                Log.i(TAG, "注册成功：deviceToken：-------->  " + deviceToken);
                PushHelper.deviceToken = deviceToken;
                JSONObject object = new JSONObject();
                object.put("messageType", "umengToken");
                object.put("token", deviceToken);
                postMessage(object);
            }

            @Override
            public void onFailure(String s, String s1) {
                Log.e(TAG, "注册失败：-------->  " + "s:" + s + ",s1:" + s1);
                PushHelper.deviceToken = "";
            }
        });
        //打开通知动作
        mPushAgent.setNotificationClickHandler(new UmengNotificationClickHandler() {
            @Override
            public void handleMessage(Context context, UMessage uMessage) {
                try {
                    clickHandleMessage(uMessage);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

        /**
         * 初始化厂商通道
         */
        String xiaomiAppId = eeuiJson.getString(umengConfig, "xiaomiAppId");
        String xiaomiAppKey = eeuiJson.getString(umengConfig, "xiaomiAppKey");
        String huaweiAppId = eeuiJson.getString(umengConfig, "huaweiAppId");
        String meizuAppId = eeuiJson.getString(umengConfig, "meizuAppId");
        String meizuAppKey = eeuiJson.getString(umengConfig, "meizuAppKey");
        String oppoAppKey = eeuiJson.getString(umengConfig, "oppoAppKey");
        String oppoAppSecret = eeuiJson.getString(umengConfig, "oppoAppSecret");
        String vivoAppId = eeuiJson.getString(umengConfig, "vivoAppId");
        String vivoAppKey = eeuiJson.getString(umengConfig, "vivoAppKey");
        //小米通道
        if (!TextUtils.isEmpty(xiaomiAppId)) {
            MiPushRegistar.register(context, xiaomiAppId, xiaomiAppKey);
        }
        //华为通道，注意华为通道的初始化参数在minifest中配置
        if (!TextUtils.isEmpty(huaweiAppId)) {
            HuaWeiRegister.register((Application) context);
        }
        //魅族通道
        if (!TextUtils.isEmpty(meizuAppId)) {
            MeizuRegister.register(context, meizuAppId, meizuAppKey);
        }
        //OPPO通道
        if (!TextUtils.isEmpty(oppoAppKey)) {
            OppoRegister.register(context, oppoAppKey, oppoAppSecret);
        }
        //VIVO 通道，注意VIVO通道的初始化参数在minifest中配置
        if (!TextUtils.isEmpty(vivoAppId)) {
            VivoRegister.register(context);
        }

        //注册统计
        ((Application) context).registerActivityLifecycleCallbacks(mCallbacks);
    }

    private static void clickHandleMessage(UMessage uMessage) throws JSONException {
        Map<String, Object> temp = eeuiMap.jsonToMap(uMessage.getRaw());
        Map<String, Object> body = eeuiMap.objectToMap(temp.get("body"));
        Map<String, Object> extra = eeuiMap.objectToMap(temp.get("extra"));
        if (body == null) {
            return;
        }
        JSONObject object = new JSONObject();
        object.put("messageType", "notificationClick");
        object.put("status", "click");
        object.put("msgid", eeuiParse.parseStr(body.get("msg_id")));
        object.put("title", eeuiParse.parseStr(body.get("title")));
        object.put("subtitle", "");
        object.put("text", eeuiParse.parseStr(body.get("text")));
        object.put("extra", extra != null ? extra : new HashMap<>());
        object.put("rawData", temp);
        postMessage(object);
    }

    public static void postMessage(Object message) {
        LinkedList<Activity> activityList = eeui.getActivityList();
        for (Activity mContext : activityList) {
            if (mContext instanceof PageActivity) {
                ((PageActivity) mContext).onAppStatusListener(new PageStatus("page", "message", null, message));
            }
        }
    }

    private static final Application.ActivityLifecycleCallbacks mCallbacks = new Application.ActivityLifecycleCallbacks() {
        @Override
        public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

        }

        @Override
        public void onActivityStarted(Activity activity) {

        }

        @Override
        public void onActivityResumed(Activity activity) {
            MobclickAgent.onResume(activity);
        }

        @Override
        public void onActivityPaused(Activity activity) {
            MobclickAgent.onPause(activity);
        }

        @Override
        public void onActivityStopped(Activity activity) {

        }

        @Override
        public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

        }

        @Override
        public void onActivityDestroyed(Activity activity) {

        }
    };

}
