package eeui.android.eeuiWebserver.module;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.widget.Toast;

import app.eeui.framework.extend.view.ExtendWebView;
import app.eeui.framework.extend.view.webviewBridge.JsCallback;

/**
 * web-view模块组件
 */
public class eeuiWebserverWebModule {

    /**
     * 简单演示
     * @param webView
     * @param msg
     */
    public static void simple(ExtendWebView webView, String msg) {
        Toast.makeText(webView.getContext(), msg, Toast.LENGTH_SHORT).show();
    }

    /**
     * 回调演示
     * @param webView
     * @param msg
     * @param callback
     */
    public static void call(ExtendWebView webView, final String msg, final JsCallback callback) {
        AlertDialog.Builder localBuilder = new AlertDialog.Builder(webView.getContext());
        localBuilder.setTitle("demo");
        localBuilder.setMessage(msg);
        localBuilder.setPositiveButton("确定", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if (callback != null) {
                    try {
                        callback.apply("返回：" + msg);
                    } catch (JsCallback.JsCallbackException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
        AlertDialog dialog = localBuilder.setCancelable(false).create();
        dialog.show();
    }

    /**
     * 同步返回演示
     * @param webView
     * @param msg
     * @return
     */
    public static String retMsg(ExtendWebView webView, String msg) {
        return "返回：" + msg;
    }
}
