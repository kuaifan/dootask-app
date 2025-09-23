package app.eeui.framework.ui.module;


import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;

import app.eeui.framework.extend.view.ExtendWebView;
import app.eeui.framework.extend.view.webviewBridge.JsCallback;
import app.eeui.framework.ui.eeui;


public class WebviewModule {

    public static void goBack(ExtendWebView webView){
        goBack(webView, null);
    }

    public static void goForward(ExtendWebView webView){
        goForward(webView, null);
    }

    /****************************************************************************************/
    /****************************************************************************************/

    /**
     * 设置Url
     * @param url
     */
    public static void setUrl(ExtendWebView webView, String url){
        if (webView != null) {
            webView.loadUrl(url);
        }
    }

    /**
     * 设置内容
     * @param content
     */
    public static void setContent(ExtendWebView webView, String content){
        if (webView != null) {
            webView.loadDataWithBaseURL("about:blank", "<html>" +
                    "<header>" +
                    "<meta charset='utf-8'>" +
                    "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=no'>" +
                    "<style type='text/css'>" + ExtendWebView.commonStyle() + "</style>" +
                    "</header>" +
                    "<body>" + content + "</body>" +
                    "</html>", "text/html", "utf-8", null);
        }
    }

    /**
     * 是否显示进度条
     * @param var
     */
    public static void setProgressbarVisibility(ExtendWebView webView, boolean var) {
        if (webView != null) {
            ((ExtendWebView) webView).setProgressbarVisibility(var);
        }
    }

    /**
     * 长按网页内容震动（仅支持android，ios无效）
     * @param var
     */
    public static void setHapticBackEnabled(ExtendWebView webView, boolean var) {
        if (webView != null) {
            ((ExtendWebView) webView).setHapticBackEnabled(var);
        }
    }

    /**
     * 允许用户长按选择内容
     * @param var
     */
    public static void setDisabledUserLongClickSelect(ExtendWebView webView, boolean var) {
        if (webView != null) {
            ((ExtendWebView) webView).setDisabledUserLongClickSelect(var);
        }
    }

    /**
     * 设置是否允许滚动
     * @param var
     */
    public static void setScrollEnabled(ExtendWebView webView, boolean var) {
        if (webView != null) {
            webView.setScrollContainer(var);
            webView.setVerticalScrollBarEnabled(var);
            webView.setHorizontalScrollBarEnabled(var);
        }
    }

    /**
     * 是否可以后退
     */
    public static void canGoBack(ExtendWebView webView, JsCallback callback) {
        if (callback != null) {
            eeui.HCallback(callback, webView.canGoBack());
        }
    }

    /**
     * 后退
     */
    public static void goBack(ExtendWebView webView, JsCallback callback){
        boolean canBack = false;
        if (webView.canGoBack()) {
            webView.goBack();
            canBack = true;
        }
        if (callback != null) {
            eeui.HCallback(callback, canBack);
        }
    }

    /**
     * 是否可以前进
     */
    public static void canGoForward(ExtendWebView webView, JsCallback callback) {
        if (callback != null) {
            eeui.HCallback(callback, webView.canGoForward());
        }
    }

    /**
     * 前进
     */
    public static void goForward(ExtendWebView webView, JsCallback callback){
        boolean canForward = false;
        if (webView.canGoForward()) {
            webView.goForward();
            canForward = true;
        }
        if (callback != null) {
            eeui.HCallback(callback, canForward);
        }
    }

    /**
     * 创建快照（仅支持ios，android无效）
     */
    public static void createSnapshot(ExtendWebView webView, JsCallback callback) {
        //
    }

    /**
     * 显示快照（仅支持ios，android无效）
     */
    public static void showSnapshot(ExtendWebView webView) {
        //
    }

    /**
     * 隐藏快照（仅支持ios，android无效）
     */
    public static void hideSnapshot(ExtendWebView webView) {
        //
    }

    /**
     * 网页向组件发送参数
     */
    public static void sendMessage(ExtendWebView webView, Object params){
        webView.sendMessage(params);
    }
}
