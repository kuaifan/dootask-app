package app.eeui.umeng.activity;

import android.os.Bundle;
import android.os.Looper;

import com.umeng.message.UmengNotifyClickActivity;

import app.eeui.framework.ui.eeui;

public class MfrMessageActivity extends UmengNotifyClickActivity {

    @Override
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        eeui myEeui = new eeui();
        String appId = eeui.getApplication().getPackageName();
        myEeui.openOtherAppTo(this, appId, appId + ".WelcomeActivity", null);
        new android.os.Handler(Looper.getMainLooper()).postDelayed(this::finish, 1000);
    }
}
