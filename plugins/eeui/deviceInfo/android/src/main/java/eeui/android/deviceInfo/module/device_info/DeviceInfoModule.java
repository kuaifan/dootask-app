package eeui.android.deviceInfo.module.device_info;

import android.content.Context;
import android.provider.Settings;

import java.util.HashMap;

public class DeviceInfoModule {
    private String mUuid;
    private Context mContext;
    private static volatile DeviceInfoModule instance = null;

    private DeviceInfoModule(Context context){
        mContext = context;
    }

    public static DeviceInfoModule getInstance(Context context) {
        if (instance == null) {
            synchronized (DeviceInfoModule.class) {
                if (instance == null) {
                    instance = new DeviceInfoModule(context);
                }
            }
        }

        return instance;
    }

    public void info(ModuleResultListener listener){
        HashMap<String, String> result = new HashMap<>();
        result.put("model", getModel());
        result.put("vendor", getManufacturer());
        result.put("uuid", getUuid());
        result.put("platform", "Android");
        result.put("version", getOSVersion());
        listener.onResult(result);
    }

    public String getUuid() {
        if (mUuid == null) {
            mUuid = Settings.Secure.getString(mContext.getContentResolver(), Settings.Secure.ANDROID_ID);
        }
        return mUuid;
    }

    public String getModel() {
        String model = android.os.Build.MODEL;
        return model;
    }

    public String getManufacturer() {
        String manufacturer = android.os.Build.MANUFACTURER;
        return manufacturer;
    }

    public String getOSVersion() {
        String osversion = android.os.Build.VERSION.RELEASE;
        return osversion;
    }
}
