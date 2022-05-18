package app.eeui.umeng.ui.entry;

import android.app.Activity;
import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.WXSDKEngine;
import com.taobao.weex.common.WXException;
import com.umeng.analytics.MobclickAgent;
import com.umeng.commonsdk.UMConfigure;
import com.umeng.message.IUmengRegisterCallback;
import com.umeng.message.MsgConstant;
import com.umeng.message.PushAgent;
import com.umeng.message.UHandler;
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
import app.eeui.framework.extend.annotation.ModuleEntry;
import app.eeui.framework.extend.bean.PageStatus;
import app.eeui.framework.extend.module.eeuiBase;
import app.eeui.framework.extend.module.eeuiJson;
import app.eeui.framework.extend.module.eeuiMap;
import app.eeui.framework.extend.module.eeuiParse;
import app.eeui.framework.ui.eeui;
import app.eeui.umeng.ui.module.eeuiUmengAnalyticsModule;
import app.eeui.umeng.ui.module.eeuiUmengPushModule;

@ModuleEntry
public class eeuiUmengEntry {

    private static final String TAG = "eeuiUmengPushEntry";
    private JSONObject umengConfig;

    public static String deviceToken = "";

    /**
     * APP启动会运行此函数方法
     * @param content Application
     */
    public void init(Context content) {
        umengConfig = eeuiJson.parseObject(eeuiBase.config.getObject("umeng").get("android"));
        if (eeuiJson.getBoolean(umengConfig, "enabled")) {
            initUmeng(content);
        }

        //注册weex模块
        try {
            WXSDKEngine.registerModule("eeuiUmengPush", eeuiUmengPushModule.class);
            WXSDKEngine.registerModule("eeuiUmengAnalytics", eeuiUmengAnalyticsModule.class);
        } catch (WXException e) {
            e.printStackTrace();
        }
    }

    private void initUmeng(Context content) {
        // 在此处调用基础组件包提供的初始化函数 相应信息可在应用管理 -> 应用信息 中找到 http://message.umeng.com/list/apps
        // 参数一：当前上下文context；
        // 参数二：应用申请的Appkey（需替换）；
        // 参数三：渠道名称；
        // 参数四：设备类型，必须参数，传参数为UMConfigure.DEVICE_TYPE_PHONE则表示手机；传参数为UMConfigure.DEVICE_TYPE_BOX则表示盒子；默认为手机；
        // 参数五：Push推送业务的secret 填充Umeng Message Secret对应信息（需替换）
        UMConfigure.init(content, eeuiJson.getString(umengConfig, "appKey"), eeuiJson.getString(umengConfig, "channel"), UMConfigure.DEVICE_TYPE_PHONE, eeuiJson.getString(umengConfig, "messageSecret"));
        UMConfigure.setLogEnabled(BuildConfig.DEBUG); //开启日志

        //获取消息推送代理示例
        PushAgent mPushAgent = PushAgent.getInstance(content);
        mPushAgent.setNotificationPlaySound(MsgConstant.NOTIFICATION_PLAY_SERVER); //服务端控制声音

        //注册推送服务，每次调用register方法都会回调该接口
        mPushAgent.register(new IUmengRegisterCallback() {
            @Override
            public void onSuccess(String deviceToken) {
                //注册成功会返回deviceToken deviceToken是推送消息的唯一标志
                Log.i(TAG, "注册成功：deviceToken：-------->  " + deviceToken);
                eeuiUmengEntry.deviceToken = deviceToken;
                JSONObject object = new JSONObject();
                object.put("messageType", "umengToken");
                object.put("token", deviceToken);
                postMessage(object);
            }

            @Override
            public void onFailure(String s, String s1) {
                Log.e(TAG, "注册失败：-------->  " + "s:" + s + ",s1:" + s1);
                eeuiUmengEntry.deviceToken = "";
            }
        });
        //打开通知动作
        mPushAgent.setNotificationClickHandler(new UHandler() {
            @Override
            public void handleMessage(Context context, UMessage uMessage) {
                try {
                    clickHandleMessage(uMessage);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                Activity mActivity = null;
                Intent intent;
                try {
                    LinkedList<Activity> mLinkedList = eeui.getActivityList();
                    mActivity = mLinkedList.getLast();
                } catch (NoSuchElementException ignored) { }
                if (mActivity != null) {
                    intent = new Intent(context, mActivity.getClass());
                } else {
                    intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
                }
                if (intent != null) {
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    context.startActivity(intent);
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
            MiPushRegistar.register(content, xiaomiAppId, xiaomiAppKey);
        }
        //华为通道，注意华为通道的初始化参数在minifest中配置
        if (!TextUtils.isEmpty(huaweiAppId)) {
            HuaWeiRegister.register((Application) content);
        }
        //魅族通道
        if (!TextUtils.isEmpty(meizuAppId)) {
            MeizuRegister.register(content, meizuAppId, meizuAppKey);
        }
        //OPPO通道
        if (!TextUtils.isEmpty(oppoAppKey)) {
            OppoRegister.register(content, oppoAppKey, oppoAppSecret);
        }
        //VIVO 通道，注意VIVO通道的初始化参数在minifest中配置
        if (!TextUtils.isEmpty(vivoAppId)) {
            VivoRegister.register(content);
        }

        //注册统计
        ((Application) content).registerActivityLifecycleCallbacks(mCallbacks);
    }

    private void clickHandleMessage(UMessage uMessage) throws JSONException {
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

    public void postMessage(Object message) {
        LinkedList<Activity> activityList = eeui.getActivityList();
        for (Activity mContext : activityList) {
            if (mContext instanceof PageActivity) {
                ((PageActivity) mContext).onAppStatusListener(new PageStatus("page", "message", null, message));
            }
        }
    }

    private static ActivityLifecycleCallbacks mCallbacks = new ActivityLifecycleCallbacks() {
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
