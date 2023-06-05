package eeui.android.deviceInfo.module;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.taobao.weex.common.WXModule;

import eeui.android.deviceInfo.module.device_battery.BatteryModule;
import eeui.android.deviceInfo.module.device_info.DeviceInfoModule;
import eeui.android.deviceInfo.module.device_network.NetworkModule;
import eeui.android.deviceInfo.module.device_screen.Constant;
import eeui.android.deviceInfo.module.device_screen.ScreenModule;
import eeui.android.deviceInfo.module.device_screen.Util;
import eeui.android.deviceInfo.module.device_vibration.VibrationModule;
import eeui.android.deviceInfo.module.device_volume.VolumeModule;

public class AppdeviceInfoModule extends WXModule {

    /**
     * 获取设配信息
     * @param jsCallback
     */
    @JSMethod
    public void info(final JSCallback jsCallback){
        DeviceInfoModule.getInstance(mWXSDKInstance.getContext()).info(jsCallback::invoke);
    }

    /************************************************************************/
    /************************************************************************/
    /************************************************************************/

    /**
     * 获取网络状态
     * @param jsCallback
     */
    @JSMethod
    public void netStatus(final JSCallback jsCallback){
        NetworkModule.getInstance(mWXSDKInstance.getContext()).status(jsCallback::invoke);
    }

    /************************************************************************/
    /************************************************************************/
    /************************************************************************/

    /**
     * 震动
     * @param time
     * @param jsCallback
     */
    @JSMethod
    public void setVibrate(int time, final JSCallback jsCallback){
        VibrationModule.getInstance(mWXSDKInstance.getContext()).vibrate(time, jsCallback::invoke);
    }

    /************************************************************************/
    /************************************************************************/
    /************************************************************************/

    JSCallback mSetBritnessCallback;
    float mBritness;

    /**
     * 获取屏幕信息
     * @param jsCallback
     */
    @JSMethod
    public void screenInfo(final JSCallback jsCallback){
        ScreenModule.getInstance(mWXSDKInstance.getContext()).info(jsCallback::invoke);
    }

    /**
     * 获取屏幕亮度
     * @param jsCallback
     */
    @JSMethod
    public void getBrightness(final JSCallback jsCallback){
        ScreenModule.getInstance(mWXSDKInstance.getContext()).getBrightness(jsCallback::invoke);
    }

    /**
     * 设置屏幕亮度
     * @param brightness
     * @param jsCallback
     */
    @JSMethod
    public void setBrightness(float brightness, JSCallback jsCallback){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            mSetBritnessCallback = jsCallback;
            mBritness = brightness;
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
            intent.setData(Uri.parse("package:" + mWXSDKInstance.getContext().getPackageName()));
            ((Activity)mWXSDKInstance.getContext()).startActivityForResult(intent, Constant.WRITE_SETTINGS_REQUEST_CODE);
        } else {
            _setBrightness(brightness);
            getBrightness(jsCallback);
        }
    }

    /**
     * 获取屏幕方向状态
     * @param jsCallback
     */
    @JSMethod
    public void getOrientation(final JSCallback jsCallback){
        ScreenModule.getInstance(mWXSDKInstance.getContext()).getOrientation(jsCallback::invoke);
    }

    @JSMethod
    public void lockOrientation(String orientation, final JSCallback jsCallback){
        ScreenModule.getInstance(mWXSDKInstance.getContext()).lockOrientation((Activity) mWXSDKInstance.getContext(), orientation, jsCallback::invoke);
    }

    @JSMethod
    public void unlockOrientation(final JSCallback jsCallback){
        ScreenModule.getInstance(mWXSDKInstance.getContext()).unlockOrientation((Activity) mWXSDKInstance.getContext(), jsCallback::invoke);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == Constant.WRITE_SETTINGS_REQUEST_CODE) {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.System.canWrite(mWXSDKInstance.getContext())) {
                    _setBrightness(mBritness);
                    getBrightness(mSetBritnessCallback);
                } else {
                    mSetBritnessCallback.invoke(Util.getError(Constant.CAMERA_PERMISSION_DENIED, Constant.CAMERA_PERMISSION_DENIED_CODE));
                }
            }
        }
    }

    private void _setScreenMode(int value) {
        Settings.System.putInt(mWXSDKInstance.getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE, value);
    }

    private void _setBrightness(float value) {
        int screenMode = 0;
        try {
            screenMode = Settings.System.getInt(mWXSDKInstance.getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE);
        } catch (Settings.SettingNotFoundException e) {
            e.printStackTrace();
        }

        if(screenMode == Settings.System.SCREEN_BRIGHTNESS_MODE_AUTOMATIC){
            _setScreenMode(Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL);
        }

        Settings.System.putInt(mWXSDKInstance.getContext().getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, (int) (value * 255));
    }

    /************************************************************************/
    /************************************************************************/
    /************************************************************************/

    /**
     * 获取音量
     * @param jsCallback
     */
    @JSMethod
    public void getVolume(final JSCallback jsCallback){
        VolumeModule.getInstance(mWXSDKInstance.getContext()).get(jsCallback::invoke);
    }

    /**
     * 设置音量
     * @param volume
     * @param jsCallback
     */
    @JSMethod
    public void setVolume(float volume, final JSCallback jsCallback){
        VolumeModule.getInstance(mWXSDKInstance.getContext()).set(volume, jsCallback::invoke);
    }

    /************************************************************************/
    /************************************************************************/
    /************************************************************************/

    /**
     * 获取电池状态
     * @param jsCallback
     */
    @JSMethod
    public void batteryStatus(final JSCallback jsCallback){
        BatteryModule.getInstance(mWXSDKInstance.getContext()).status(jsCallback::invoke);
    }
}
