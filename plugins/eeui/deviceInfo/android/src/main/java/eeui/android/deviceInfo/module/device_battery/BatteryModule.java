package eeui.android.deviceInfo.module.device_battery;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import java.util.HashMap;

public class BatteryModule {

    private Context mContext;
    private static volatile BatteryModule instance = null;

    private BatteryModule(Context context){
        mContext = context;
    }

    public static BatteryModule getInstance(Context context) {
        if (instance == null) {
            synchronized (BatteryModule.class) {
                if (instance == null) {
                    instance = new BatteryModule(context);
                }
            }
        }

        return instance;
    }

    public void status(ModuleResultListener listener){
        Intent batteryIntent = mContext
                .registerReceiver( null ,
                        new IntentFilter( Intent.ACTION_BATTERY_CHANGED ) ) ;
        HashMap<String, Object> result = new HashMap<>();
        result.put("level", batteryIntent.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, 0));
        result.put("isPlugged", batteryIntent.getIntExtra(android.os.BatteryManager.EXTRA_PLUGGED, -1) > 0 ? true : false);
        listener.onResult(result);
    }
}
