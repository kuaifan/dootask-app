package app.eeui.framework.extend.module.utilcode.constant;

import android.Manifest;
import android.Manifest.permission;
import android.annotation.SuppressLint;
import android.os.Build;
import androidx.annotation.StringDef;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;


/**
 * <pre>
 *     author: Blankj
 *     blog  : http://blankj.com
 *     time  : 2017/12/29
 *     desc  : The constants of permission.
 * </pre>
 */
@SuppressLint("InlinedApi")
public final class PermissionConstants {

    public static final String CALENDAR   = "android.permission-group.CALENDAR";
    public static final String CAMERA     = "android.permission-group.CAMERA";
    public static final String CONTACTS   = "android.permission-group.CONTACTS";
    public static final String LOCATION   = "android.permission-group.LOCATION";
    public static final String MICROPHONE = "android.permission-group.MICROPHONE";
    public static final String PHONE      = "android.permission-group.PHONE";
    public static final String SENSORS    = "android.permission-group.SENSORS";
    public static final String SMS        = "android.permission-group.SMS";
    public static final String STORAGE    = "android.permission-group.STORAGE";

    private static final String[] GROUP_CALENDAR   = {
            permission.READ_CALENDAR, permission.WRITE_CALENDAR
    };
    private static final String[] GROUP_CAMERA     = {
            permission.CAMERA
    };
    private static final String[] GROUP_CONTACTS   = {
            permission.READ_CONTACTS, permission.WRITE_CONTACTS, permission.GET_ACCOUNTS
    };
    private static final String[] GROUP_LOCATION   = {
            permission.ACCESS_FINE_LOCATION, permission.ACCESS_COARSE_LOCATION
    };
    private static final String[] GROUP_MICROPHONE = {
            permission.RECORD_AUDIO
    };
    private static final String[] GROUP_PHONE      = {
            permission.READ_PHONE_STATE, permission.READ_PHONE_NUMBERS, permission.CALL_PHONE,
            permission.ANSWER_PHONE_CALLS, permission.READ_CALL_LOG, permission.WRITE_CALL_LOG,
            permission.ADD_VOICEMAIL, permission.USE_SIP, permission.PROCESS_OUTGOING_CALLS
    };
    private static final String[] GROUP_SENSORS    = {
            permission.BODY_SENSORS
    };
    private static final String[] GROUP_SMS        = {
            permission.SEND_SMS, permission.RECEIVE_SMS, permission.READ_SMS,
            permission.RECEIVE_WAP_PUSH, permission.RECEIVE_MMS,
    };
    
    // Android 13+ 媒体权限
    private static final String[] GROUP_STORAGE_ANDROID_13_PLUS = {
            permission.READ_MEDIA_IMAGES,
            permission.READ_MEDIA_VIDEO,
            permission.READ_MEDIA_AUDIO
    };
    
    // Android 12 及以下存储权限
    private static final String[] GROUP_STORAGE_LEGACY = {
            permission.READ_EXTERNAL_STORAGE, permission.WRITE_EXTERNAL_STORAGE
    };

    @StringDef({CALENDAR, CAMERA, CONTACTS, LOCATION, MICROPHONE, PHONE, SENSORS, SMS, STORAGE,})
    @Retention(RetentionPolicy.SOURCE)
    public @interface Permission {
    }

    public static String[] getPermissions(@Permission final String permission) {
        switch (permission) {
            case CALENDAR:
                return GROUP_CALENDAR;
            case CAMERA:
                return GROUP_CAMERA;
            case CONTACTS:
                return GROUP_CONTACTS;
            case LOCATION:
                return GROUP_LOCATION;
            case MICROPHONE:
                return GROUP_MICROPHONE;
            case PHONE:
                return GROUP_PHONE;
            case SENSORS:
                return GROUP_SENSORS;
            case SMS:
                return GROUP_SMS;
            case STORAGE:
                // 根据 Android 版本返回不同的存储权限
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    return GROUP_STORAGE_ANDROID_13_PLUS;
                } else {
                    return GROUP_STORAGE_LEGACY;
                }
        }
        return new String[]{permission};
    }
}
