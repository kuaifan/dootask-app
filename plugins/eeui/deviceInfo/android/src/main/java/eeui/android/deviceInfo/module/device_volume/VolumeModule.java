package eeui.android.deviceInfo.module.device_volume;

import android.content.Context;
import android.media.AudioManager;
import java.util.HashMap;

public class VolumeModule {

    private Context mContext;
    private static volatile VolumeModule instance = null;

    private VolumeModule(Context context){
        mContext = context;
    }

    public static VolumeModule getInstance(Context context) {
        if (instance == null) {
            synchronized (VolumeModule.class) {
                if (instance == null) {
                    instance = new VolumeModule(context);
                }
            }
        }

        return instance;
    }
    
    public void set(float volume, ModuleResultListener listener){
        AudioManager manager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
        int streamMaxVolume = manager.getStreamMaxVolume(AudioManager.STREAM_SYSTEM);
        manager.setStreamVolume(AudioManager.STREAM_SYSTEM, Math.round(volume * streamMaxVolume), AudioManager.FLAG_SHOW_UI | AudioManager.FLAG_PLAY_SOUND);
        get(listener);
    }

    public void get(ModuleResultListener listener){
        AudioManager manager = (AudioManager) mContext.getSystemService(Context.AUDIO_SERVICE);
        int streamVolume = manager.getStreamVolume(AudioManager.STREAM_SYSTEM);
        int streamMaxVolume = manager.getStreamMaxVolume(AudioManager.STREAM_SYSTEM);
        HashMap<String, Float> result = new HashMap<>();
        result.put("volume", streamVolume / (streamMaxVolume + 0.0f));
        listener.onResult(result);
    }
}
