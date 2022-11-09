package eeui.android.eeuiPicture.module;

import app.eeui.framework.extend.view.ExtendWebView;
import app.eeui.framework.extend.view.webviewBridge.JsCallback;
import app.eeui.framework.ui.eeui;
import eeui.android.eeuiPicture.entry.eeuiPictureEntry;

/**
 * web-view模块组件
 */
public class eeuiPictureWebModule {

    private static eeuiPictureEntry __obj;

    private static eeuiPictureEntry myApp() {
        if (__obj == null) {
            __obj = new eeuiPictureEntry();
        }
        return __obj;
    }

    /***************************************************************************************************/
    /***************************************************************************************************/
    /***************************************************************************************************/

    /**
     * 打开相册
     * @param object
     * @param callback
     */
    public static void create(ExtendWebView webView, String object, JsCallback callback) {
        myApp().create(webView.getContext(), object, eeui.MCallback(callback));
    }

    /**
     * 压缩图片
     * @param object
     * @param callback
     */
    public static void compressImage(ExtendWebView webView, String object, JsCallback callback) {
        myApp().compressImage(webView.getContext(), object, eeui.MCallback(callback));
    }

    /**
     * 预览图片
     * @param position
     * @param array
     */
    public static void picturePreview(ExtendWebView webView, int position, String array, JsCallback callback) {
        myApp().picturePreview(webView.getContext(), position, array, eeui.MCallback(callback));
    }

    /**
     * 预览视频
     * @param path
     */
    public static void videoPreview(ExtendWebView webView, String path) {
        myApp().videoPreview(webView.getContext(), path);
    }

    /**
     * 缓存清除，包括裁剪和压缩后的缓存，要在上传成功后调用，注意：需要系统sd卡权限
     */
    public static void deleteCache(ExtendWebView webView) {
        myApp().deleteCache(webView.getContext());
    }
}
