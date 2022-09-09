package eeui.android.eeuiNotifications.entry;

import android.content.Context;

import com.taobao.weex.WXSDKEngine;
import com.taobao.weex.common.WXException;

import app.eeui.framework.extend.annotation.ModuleEntry;
import eeui.android.eeuiNotifications.module.eeuiNotificationsAppModule;

@ModuleEntry
public class eeuiNotificationsEntry {

    /**
     * APP启动会运行此函数方法
     * @param content Application
     */
    public void init(Context content) {

        //注册weex模块
        try {
            WXSDKEngine.registerModule("eeuiNotifications", eeuiNotificationsAppModule.class);
        } catch (WXException e) {
            e.printStackTrace();
        }
    }
}
