package app.eeui.framework.extend.module;

import com.taobao.weex.WXSDKInstance;
import com.taobao.weex.WXSDKManager;
import com.taobao.weex.utils.WXUtils;

import app.eeui.framework.extend.module.utilcode.util.ScreenUtils;

import android.content.Context;
import android.content.res.Resources;
import android.os.Build;
import android.util.DisplayMetrics;
import android.view.WindowManager;

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
     * @param weexInstance Weex实例，用于单位转换
     * @return 返回包含顶部和底部安全区域高度的Map
     */
    public static Map<String, Object> getSafeAreaInsets(Context context, WXSDKInstance weexInstance) {
        Map<String, Object> result = new HashMap<>();
        int statusBarHeight = 0;
        int navigationBarHeight = 0;

        // 获取状态栏高度
        int resourceId = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            statusBarHeight = context.getResources().getDimensionPixelSize(resourceId);
        }

        // 获取导航栏高度（如果显示）
        resourceId = context.getResources().getIdentifier("navigation_bar_height", "dimen", "android");
        if (resourceId > 0 && isNavBarVisible(context)) {
            navigationBarHeight = context.getResources().getDimensionPixelSize(resourceId);
        }

        // 添加到结果Map中
        result.put("top", statusBarHeight);
        result.put("bottom", navigationBarHeight);

        // 添加Weex像素单位的值
        if (weexInstance != null) {
            result.put("topPx", weexDp2pxFloat(weexInstance, statusBarHeight));
            result.put("bottomPx", weexDp2pxFloat(weexInstance, navigationBarHeight));
        }

        return result;
    }

    /**
     * 判断导航栏是否可见
     * @param context 上下文
     * @return 导航栏是否可见
     */
    private static boolean isNavBarVisible(Context context) {
        boolean hasNavigationBar = false;
        Resources resources = context.getResources();
        int id = resources.getIdentifier("config_showNavigationBar", "bool", "android");
        if (id > 0) {
            hasNavigationBar = resources.getBoolean(id);
        }
        
        // 检查导航栏可见性
        if (hasNavigationBar) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                // 某些设备上可能隐藏了导航栏
                int displayCutoutMode = 0;
                try {
                    WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
                    DisplayMetrics dm = new DisplayMetrics();
                    windowManager.getDefaultDisplay().getRealMetrics(dm);
                    int realHeight = dm.heightPixels;
                    windowManager.getDefaultDisplay().getMetrics(dm);
                    int displayHeight = dm.heightPixels;
                    return (realHeight - displayHeight) > 0;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
        return hasNavigationBar;
    }
}
