package eeui.android.eeuiNotifications.module;


import android.app.PendingIntent;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;

import androidx.core.app.NotificationManagerCompat;

import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;

import java.util.Random;

import app.eeui.framework.extend.base.WXModuleBase;
import app.eeui.framework.extend.module.eeuiJson;
import app.eeui.framework.extend.module.eeuiParse;
import eeui.android.eeuiNotifications.R;
import eeui.android.eeuiNotifications.receiver.NotificationClickReceiver;
import eeui.android.eeuiNotifications.utils.NotificationUtils;

public class eeuiNotificationsAppModule extends WXModuleBase {

    public static JSONObject parameter = new JSONObject();

    private int generateRandId() {
        int length = 6;
        String base = "123456789";
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            int number = random.nextInt(base.length());
            sb.append(base.charAt(number));
        }
        return eeuiParse.parseInt(sb.toString());
    }

    /**
     * 获取当前权限
     *
     */
    @JSMethod
    public void getPermissionStatus(final JSCallback jsCallback){
        boolean isPer = NotificationManagerCompat.from(getContext()).areNotificationsEnabled();
        jsCallback.invoke(isPer);
    }

    /**
     * 跳转测试页
     *
     */
    @JSMethod
    public void gotoSet() {

        Intent intent = new Intent();

        if (Build.VERSION.SDK_INT >= 26) {

            // android 8.0引导

            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");

            intent.putExtra("android.provider.extra.APP_PACKAGE", getContext().getPackageName());

        } else if (Build.VERSION.SDK_INT >= 21) {

            // android 5.0-7.0

            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");

            intent.putExtra("app_package", getContext().getPackageName());

            intent.putExtra("app_uid", getContext().getApplicationInfo().uid);

        } else {

            // 其他

            intent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");

            intent.setData(Uri.fromParts("package", getContext().getPackageName(), null));

        }

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        getContext().startActivity(intent);

    }

    /**
     * 设置角标(只限iOS)
     *
     */
    @JSMethod
    public void setBadge(int badge) {
        
    }

    /**
     * 通知
     * @param params
     */
    @JSMethod
    public void notify(Object params) {
        int randId = generateRandId();

        //创建intent
        Intent intent = new Intent(getActivity(), NotificationClickReceiver.class);
        intent.putExtra("whatId", randId);
        PendingIntent resultPendingIntent =PendingIntent.getBroadcast(getActivity(), randId, intent, 0);
        //发送pendingIntent

        JSONObject json = eeuiJson.parseObject(params);
        int notifyId = eeuiJson.getInt(json, "id", randId);
        String title = eeuiJson.getString(json, "title");
        String body = eeuiJson.getString(json, "body");
        parameter.put("whatId" + randId, json);

        NotificationUtils notificationUtils = new NotificationUtils(getContext());
        notificationUtils
                .setContentIntent(resultPendingIntent)
                .sendNotification(notifyId, title, body, R.drawable.notify_icon);
    }

    /**
     * 根据ID清除指定通知
     * @param id
     */
    @JSMethod
    public void clearId(int id) {
        NotificationUtils notificationUtils = new NotificationUtils(getContext());
        notificationUtils.clearNotificationId(id);
    }

    /**
     * 根据标题清除指定通知
     * @param title
     */
    @JSMethod
    public void clearTitle(String title) {
        NotificationUtils notificationUtils = new NotificationUtils(getContext());
        notificationUtils.clearNotificationTitle(title);
    }

    /**
     * 清除所有通知
     */
    @JSMethod
    public void clearAll() {
        NotificationUtils notificationUtils = new NotificationUtils(getContext());
        notificationUtils.clearNotification();
    }
}
