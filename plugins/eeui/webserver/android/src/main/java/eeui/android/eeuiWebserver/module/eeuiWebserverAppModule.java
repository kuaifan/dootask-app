package eeui.android.eeuiWebserver.module;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.widget.Toast;

import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;

import app.eeui.framework.extend.base.WXModuleBase;

public class eeuiWebserverAppModule extends WXModuleBase {

    /**
     * 简单演示
     * @param msg
     */
    @JSMethod
    public void simple(String msg) {
        Toast.makeText(getContext(), msg, Toast.LENGTH_SHORT).show();
    }

    /**
     * 回调演示
     * @param msg
     * @param callback
     */
    @JSMethod
    public void call(final String msg, final JSCallback callback) {
        AlertDialog.Builder localBuilder = new AlertDialog.Builder(getContext());
        localBuilder.setTitle("demo");
        localBuilder.setMessage(msg);
        localBuilder.setPositiveButton("确定", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                if (callback != null) {
                    callback.invoke("返回：" + msg); //多次回调请使用invokeAndKeepAlive
                }
            }
        });
        AlertDialog dialog = localBuilder.setCancelable(false).create();
        dialog.show();
    }

    /**
     * 同步返回演示
     * @param msg
     * @return
     */
    @JSMethod(uiThread = false)
    public String retMsg(String msg) {
        return "返回：" + msg;
    }
}
