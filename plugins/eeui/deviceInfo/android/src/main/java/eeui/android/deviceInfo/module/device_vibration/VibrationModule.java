package eeui.android.deviceInfo.module.device_vibration;

import android.content.Context;
import android.media.AudioManager;
import android.os.Vibrator;

public class VibrationModule {
    private Context mContext;
    private static volatile VibrationModule instance = null;

    private VibrationModule(Context context){
        mContext = context;
    }

    public static VibrationModule getInstance(Context context) {
        if (instance == null) {
            synchronized (VibrationModule.class) {
                if (instance == null) {
                    instance = new VibrationModule(context);
                }
            }
        }

        return instance;
    }
    
    public void vibrate(int time, ModuleResultListener listener){
        if (time == 0) time = 500;
        cancelVibration();
        vibrate(time);
        listener.onResult(null);
    }

    public void vibrate(long time) {
        if (time == 0) {
            time = 500;
        }
        AudioManager manager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
        if (manager.getRingerMode() != AudioManager.RINGER_MODE_SILENT) {
            Vibrator vibrator = (Vibrator) mContext.getSystemService(Context.VIBRATOR_SERVICE);
            vibrator.vibrate(time);
        }
    }

    public void cancelVibration() {
        Vibrator vibrator = (Vibrator) mContext.getSystemService(Context.VIBRATOR_SERVICE);
        vibrator.cancel();
    }

}
