package app.eeui.framework.extend.module;

import com.taobao.weex.WXSDKInstance;
import com.taobao.weex.WXSDKManager;
import com.taobao.weex.utils.WXUtils;

import app.eeui.framework.extend.module.utilcode.util.ScreenUtils;

import android.content.Context;
import android.util.DisplayMetrics;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by WDM on 2018/3/13.
 */

public class eeuiScreenUtils {

    public static int weexPx2dp(WXSDKInstance mInstance, Object pxValue, int defaultValue) {
        return (int) (weexPx2dpFloat(mInstance, pxValue, defaultValue));
    }

    public static int weexPx2dp(WXSDKInstance mInstance, Object pxValue) {
        return (int) weexPx2dpFloat(mInstance, pxValue);
    }

    public static int weexDp2px(WXSDKInstance mInstance, Object dpValue) {
        return (int) (weexDp2pxFloat(mInstance, dpValue));
    }

    /******************************************************************************************/
    /******************************************************************************************/
    /******************************************************************************************/

    public static float weexPx2dpFloat(WXSDKInstance mInstance, Object pxValue, float defaultValue) {
        float width;
        if (mInstance == null) {
            width = WXSDKManager.getInstanceViewPortWidth(null);
        }else{
            width = mInstance.getInstanceViewPortWidth();
        }
        return runTwo(ScreenUtils.getScreenWidth() / width * eeuiParse.parseFloat(removePxString(pxValue), defaultValue));
    }

    public static float weexPx2dpFloat(WXSDKInstance mInstance, Object pxValue) {
        return weexPx2dpFloat(mInstance, pxValue, 0);
    }

    public static float weexDp2pxFloat(WXSDKInstance mInstance, Object dpValue) {
        float width;
        if (mInstance == null) {
            width = WXSDKManager.getInstanceViewPortWidth(null);
        }else{
            width = mInstance.getInstanceViewPortWidth();
        }
        return runTwo(width / ScreenUtils.getScreenWidth() * eeuiParse.parseFloat(dpValue, 0));
    }

    /******************************************************************************************/
    /******************************************************************************************/
    /******************************************************************************************/

    private static float runTwo(float number) {
        return (float)(Math.round(number * 100) / 100.0);
    }

    private static String removePxString(Object pxValue) {
        String temp = WXUtils.getString(pxValue, null);
        if (temp != null && !temp.isEmpty()) {
            temp = temp.replace("px", "");
        }
        return temp;
    }

    /**
     * 获取安全区域高度
     * @param context 上下文
     * @return 返回包含顶部和底部安全区域高度的Map
     */
    public static Map<String, Object> getSafeAreaInsets(Context context) {
        Map<String, Object> result = new HashMap<>();

        // 获取状态栏、导航栏高度
        int statusBarHeight = eeuiNavMask.getStatusBarHeight(context);
        int navigationBarHeight = eeuiNavMask.getNavigationBarHeight(context);

        // 获取屏幕尺寸
        DisplayMetrics displayMetrics = context.getResources().getDisplayMetrics();
        int screenWidth = displayMetrics.widthPixels;
        int screenHeight = displayMetrics.heightPixels;

        // 添加到结果Map中
        result.put("top", statusBarHeight);
        result.put("bottom", navigationBarHeight);
        result.put("width", screenWidth);
        result.put("height", screenHeight);

        return result;
    }
}
