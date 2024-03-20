package app.eeui.umeng.ui.entry;

import android.content.Context;

import com.taobao.weex.WXSDKEngine;
import com.taobao.weex.common.WXException;
import app.eeui.framework.extend.annotation.ModuleEntry;
import app.eeui.framework.extend.module.eeuiJson;
import app.eeui.umeng.helper.PushHelper;
import app.eeui.umeng.ui.module.eeuiUmengAnalyticsModule;
import app.eeui.umeng.ui.module.eeuiUmengPushModule;

@ModuleEntry
public class eeuiUmengEntry {

    /**
     * APP启动会运行此函数方法
     * @param content Application
     */
    public void init(Context content) {
        PushHelper.initConfig();

        if (eeuiJson.getBoolean(PushHelper.umengConfig, "enabled")) {
            PushHelper.preInit(content);

            if (eeuiJson.getBoolean(PushHelper.umengConfig, "automatic")) {
                PushHelper.initThread(content);
            }
        }

        // 注册weex模块
        try {
            WXSDKEngine.registerModule("eeuiUmengPush", eeuiUmengPushModule.class);
            WXSDKEngine.registerModule("eeuiUmengAnalytics", eeuiUmengAnalyticsModule.class);
        } catch (WXException e) {
            e.printStackTrace();
        }
    }
}
