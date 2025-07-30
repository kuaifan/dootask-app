package app.eeui.framework.ui.component.webView;

import android.app.Activity;
import android.app.UiModeManager;
import android.content.Context;
import androidx.annotation.NonNull;

import android.os.Build;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebSettings;

import com.alibaba.fastjson.JSONObject;
import com.taobao.weex.WXSDKInstance;
import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.taobao.weex.ui.action.BasicComponentData;
import com.taobao.weex.ui.component.WXVContainer;

import java.util.HashMap;
import java.util.Map;

import app.eeui.framework.R;
import app.eeui.framework.extend.module.eeuiConstants;
import app.eeui.framework.extend.module.eeuiJson;
import app.eeui.framework.extend.module.eeuiParse;
import app.eeui.framework.extend.module.eeuiScreenUtils;
import app.eeui.framework.extend.view.ExtendWebView;

/**
 * Created by WDM on 2018/4/13.
 */
public class WebView extends WXVContainer<ViewGroup> {

    private static final String TAG = "WebView";

    private View mView;

    private ExtendWebView v_webview;

    public WebView(WXSDKInstance instance, WXVContainer parent, BasicComponentData basicComponentData) {
        super(instance, parent, basicComponentData);
    }

    @Override
    protected ViewGroup initComponentHostView(@NonNull Context context) {
        mView = ((Activity) context).getLayoutInflater().inflate(R.layout.layout_eeui_webview, null);
        initPagerView();
        //
        if (getEvents().contains(eeuiConstants.Event.READY)) {
            fireEvent(eeuiConstants.Event.READY, null);
        }
        //
        return (ViewGroup) mView;
    }

    @Override
    public void addSubView(View view, int index) {

    }

    /**
     * 主题匹配
     */
    public void setDefaultTheme() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            UiModeManager uiModeManager = (UiModeManager) getContext().getSystemService(Context.UI_MODE_SERVICE);
            if (uiModeManager.getNightMode() == UiModeManager.MODE_NIGHT_YES) {
                v_webview.getSettings().setForceDark(WebSettings.FORCE_DARK_ON);
            } else {
                v_webview.getSettings().setForceDark(WebSettings.FORCE_DARK_OFF);
            }
        }
    }

    @Override
    public void onActivityResume() {
        super.onActivityResume();
    }

    private void initPagerView() {
        v_webview = mView.findViewById(R.id.v_webview);
        v_webview.setSupportMultipleWindows(true);
        //
        if (getEvents().contains(eeuiConstants.Event.STATE_CHANGED)) {
            v_webview.setOnStatusClient(new ExtendWebView.StatusCall() {
                @Override
                public void onCreateTarget(android.webkit.WebView view, String url) {
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("status", "createTarget");
                    retData.put("url", url);
                    fireEvent(eeuiConstants.Event.STATE_CHANGED, retData);
                }

                @Override
                public void onStatusChanged(android.webkit.WebView view, String status) {
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("status", status);
                    fireEvent(eeuiConstants.Event.STATE_CHANGED, retData);
                }

                @Override
                public void onErrorChanged(android.webkit.WebView view, int errorCode, String description, String failingUrl) {
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("status", "error");
                    retData.put("errCode", errorCode);
                    retData.put("errMsg", description);
                    retData.put("errUrl", failingUrl);
                    fireEvent(eeuiConstants.Event.STATE_CHANGED, retData);
                }

                @Override
                public void onTitleChanged(android.webkit.WebView view, String title) {
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("status", "title");
                    retData.put("title", title);
                    fireEvent(eeuiConstants.Event.STATE_CHANGED, retData);
                }

                @Override
                public void onUrlChanged(android.webkit.WebView view, String url) {
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("status", "url");
                    retData.put("url", url);
                    fireEvent(eeuiConstants.Event.STATE_CHANGED, retData);
                }
            });
        }
        if (getEvents().contains(eeuiConstants.Event.HEIGHT_CHANGED)) {
            v_webview.setHeightChanged(value -> {
                v_webview.post(()->{
                    Map<String, Object> retData = new HashMap<>();
                    retData.put("height", eeuiScreenUtils.weexDp2px(getInstance(), eeuiParse.parseFloat(value) * v_webview.getScale()));
                    fireEvent(eeuiConstants.Event.HEIGHT_CHANGED, retData);
                });
            });
        }
        if (getEvents().contains(eeuiConstants.Event.RECEIVE_MESSAGE)) {
            v_webview.setSendMessage(value -> {
                Map<String, Object> retData = new HashMap<>();
                retData.put("message", value);
                fireEvent(eeuiConstants.Event.RECEIVE_MESSAGE, retData);
            });
        }
    }

    @Override
    protected boolean setProperty(String key, Object param) {
        return initProperty(key, param) || super.setProperty(key, param);
    }

    @Override
    public void destroy() {
        super.destroy();
    }

    private boolean initProperty(String key, Object val) {
        switch (key) {
            case "eeui":
                JSONObject json = eeuiJson.parseObject(eeuiParse.parseStr(val, ""));
                if (json.size() > 0) {
                    for (Map.Entry<String, Object> entry : json.entrySet()) {
                        initProperty(entry.getKey(), entry.getValue());
                    }
                }
                return true;

            case "url":
                setUrl(eeuiParse.parseStr(val, ""));
                return true;

            case "content":
                setContent(eeuiParse.parseStr(val, ""));
                return true;

            case "progressbarVisibility":
                setProgressbarVisibility(eeuiParse.parseBool(val, true));
                return true;

            case "allowsInlineMediaPlayback":
                if (v_webview != null) {
                    v_webview.setAllowsInlineMediaPlayback(eeuiParse.parseBool(val, true));
                }
                return true;

            case "allowFileAccessFromFileURLs":
                if (v_webview != null) {
                    v_webview.setAllowFileAccessFromFileURLs(eeuiParse.parseBool(val, true));
                }
                return true;

            case "scrollEnabled":
                setScrollEnabled(eeuiParse.parseBool(val, true));
                return true;

            case "enableApi":
                if (v_webview != null) {
                    v_webview.setEnableApi(eeuiParse.parseBool(val, true));
                }
                return true;

            case "userAgent":
                if (v_webview != null) {
                    v_webview.setUserAgent(eeuiParse.parseStr(val, ""));
                }
                return true;

            case "transparency":
                if (v_webview != null) {
                    v_webview.setTransparency(eeuiParse.parseBool(val, false));
                }
                return true;

            case "hiddenDone":
                if (v_webview != null) {
                    v_webview.setHiddenDone(eeuiParse.parseBool(val, false));
                }
                return true;

            case "hapticBackEnabled":
                if (v_webview != null) {
                    v_webview.setHapticBackEnabled(eeuiParse.parseBool(val, false));
                }
                return true;

            case "disabledUserLongClickSelect":
                if (v_webview != null) {
                    v_webview.setDisabledUserLongClickSelect(eeuiParse.parseBool(val, false));
                }
                return true;

            case "fullscreen":
                setFullscreen(eeuiParse.parseBool(val, false));
                return true;

            default:
                return false;
        }
    }

    private boolean __canGoBack() {
        return v_webview != null && v_webview.canGoBack();
    }

    private boolean __canGoForward() {
        return v_webview != null && v_webview.canGoForward();
    }

    /***************************************************************************************************/
    /***************************************************************************************************/
    /***************************************************************************************************/

    /**
     * 设置Url
     * @param url
     */
    @JSMethod
    public void setUrl(String url){
        if (v_webview != null) {
            v_webview.loadUrl(url);
        }
    }

    /**
     * 设置javaScript
     * @param script
     */
    @JSMethod
    public void setJavaScript(String script){
        if (v_webview != null) {
            v_webview.loadUrl("javascript:(function(){" + script + "})();");
        }
    }

    /**
     * 设置内容
     * @param content
     */
    @JSMethod
    public void setContent(String content){
        if (v_webview != null) {
            if (!content.contains("</html>") && !content.contains("</HTML>")) {
                content = "<html>" +
                        "<header>" +
                        "<meta charset='utf-8'>" +
                        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no'>" +
                        "<style type='text/css'>" + ExtendWebView.commonStyle() + "</style>" +
                        "</header>" +
                        "<body>" + content + "</body>" +
                        "</html>";
            }
            v_webview.loadDataWithBaseURL("about:blank", content, "text/html", "utf-8", null);
        }
    }

    /**
     * 是否显示进度条
     * @param var
     */
    @JSMethod
    public void setProgressbarVisibility(boolean var) {
        if (v_webview != null) {
            v_webview.setProgressbarVisibility(var);
        }
    }

    /**
     * 长按网页内容震动（仅支持android，ios无效）
     * @param var
     */
    @JSMethod
    public void setHapticBackEnabled(boolean var) {
        if (v_webview != null) {
            v_webview.setHapticBackEnabled(var);
        }
    }

    /**
     * 允许用户长按选择内容
     * @param var
     */
    @JSMethod
    public void setDisabledUserLongClickSelect(boolean var) {
        if (v_webview != null) {
            v_webview.setDisabledUserLongClickSelect(var);
        }
    }

    /**
     * 设置是否允许滚动
     * @param var
     */
    @JSMethod
    public void setScrollEnabled(boolean var) {
        if (v_webview != null) {
            v_webview.setScrollContainer(var);
            v_webview.setVerticalScrollBarEnabled(var);
            v_webview.setHorizontalScrollBarEnabled(var);
        }
    }

    /**
     * 设置是否全屏显示（覆盖顶部状态栏和底部安全区域，仅支持ios，android无效）
     * @param fullscreen 是否全屏
     */
    @JSMethod
    public void setFullscreen(boolean fullscreen) {
        //
    }

    /**
     * 是否可以后退
     */
    @JSMethod
    public void canGoBack(JSCallback callback) {
        if (callback != null) {
            callback.invoke(__canGoBack());
        }
    }

    /**
     * 后退
     */
    @JSMethod
    public void goBack(JSCallback callback){
        boolean canBack = false;
        if (__canGoBack()) {
            v_webview.goBack();
            canBack = true;
        }
        if (callback != null) {
            callback.invoke(canBack);
        }
    }

    /**
     * 是否可以前进
     */
    @JSMethod
    public void canGoForward(JSCallback callback) {
        if (callback != null) {
            callback.invoke(__canGoForward());
        }
    }

    /**
     * 前进
     */
    @JSMethod
    public void goForward(JSCallback callback){
        boolean canForward = false;
        if (__canGoForward()) {
            v_webview.goForward();
            canForward = true;
        }
        if (callback != null) {
            callback.invoke(canForward);
        }
    }

    /**
     * 创建快照（仅支持ios，android无效）
     */
    @JSMethod
    public void createSnapshot(JSCallback callback) {
        //
    }

    /**
     * 显示快照（仅支持ios，android无效）
     */
    @JSMethod
    public void showSnapshot() {
        //
    }

    /**
     * 隐藏快照（仅支持ios，android无效）
     */
    @JSMethod
    public void hideSnapshot() {
        //
    }
}
