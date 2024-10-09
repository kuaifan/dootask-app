package eeui.android.eeuiAgoro.entry;

import android.app.Activity;
import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import eeui.android.eeuiAgoro.client.AgoraRtcPresenter;
import eeui.android.eeuiAgoro.service.KeepLiveService;

/**
 * Describe: 监听app锁屏或切后台
 */
class ActivityLifecycleListener implements Application.ActivityLifecycleCallbacks {

    private int activityCount = 0;
    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

    }
    @Override
    public void onActivityStarted(Activity activity) {
        activityCount++;
        getAppStatus(activity);
        Log.d("LifecycleListener", "onActivityStarted: ");
    }
    @Override
    public void onActivityResumed(Activity activity) {

    }
    @Override
    public void onActivityPaused(Activity activity) {

    }
    @Override
    public void onActivityStopped(Activity activity) {
        activityCount--;
        getAppStatus(activity);
        Log.d("LifecycleListener", "onActivityStopped: ");
    }
    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

    }
    @Override
    public void onActivityDestroyed(Activity activity) {

    }
    /**
     * 根据activityCount,判断app状态
     */
    public void getAppStatus(Activity activity) {
        if (activityCount == 0) {
            //App进入后台或者APP锁屏了
            //开启服务
            if (AgoraRtcPresenter.getInstance().getmRtcEngine() != null) {
                // 正在通话中才启动服务
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    //android8.0以上通过startForegroundService启动service
                    activity.startForegroundService(new Intent(activity, KeepLiveService.class));
                } else {
                    activity.startService(new Intent(activity, KeepLiveService.class));
                }
            }
        } else {
            //App进入前台
            //结束服务
            activity.stopService(new Intent(activity, KeepLiveService.class));
        }
    }
}

