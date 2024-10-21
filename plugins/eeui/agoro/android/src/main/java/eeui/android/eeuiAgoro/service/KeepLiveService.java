package eeui.android.eeuiAgoro.service;


import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;

public class KeepLiveService extends Service {
    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private NotificationManager notificationManager;
    private String notificationId   = "keep_app_live";
    private String notificationName = "APP后台运行中";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d("service", "onCreate: ");
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        //创建NotificationChannel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(notificationId, notificationName, NotificationManager.IMPORTANCE_HIGH);
            //不震动
            channel.enableVibration(false);
            //静音
            channel.setSound(null, null);
            notificationManager.createNotificationChannel(channel);
        }
        //创建服务后,五秒内调用该方法
        startForeground(1, getNotification());

    }

    /**
     * 获取通知(Android8.0后需要)
     *
     * @return
     */
    private Notification getNotification() {
        Notification.Builder builder = new Notification.Builder(this)
//            .setSmallIcon(R.mipmap.ic_logo)
            .setContentTitle("dootask")
            .setContentIntent(getIntent())
            .setContentText("后台运行中");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setChannelId(notificationId);
        }
        return builder.build();
    }

    /**
     * 点击后,直接打开app(之前的页面),不跳转特定activity
     * @return
     */
    private PendingIntent getIntent() {
        Intent msgIntent = getApplicationContext().getPackageManager().getLaunchIntentForPackage(getPackageName());//获取启动Activity
        PendingIntent pendingIntent = PendingIntent.getActivity(
            getApplicationContext(),
            1,
            msgIntent,
            PendingIntent.FLAG_UPDATE_CURRENT);

        return pendingIntent;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();

        Log.d("service", "onDestroy: ");
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        //创建NotificationChannel
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            notificationManager.deleteNotificationChannel(notificationId);
        }
    }
}
