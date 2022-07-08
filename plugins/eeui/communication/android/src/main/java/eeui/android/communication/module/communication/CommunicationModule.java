package eeui.android.communication.module.communication;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.text.TextUtils;

import java.util.HashMap;

public class CommunicationModule {

    private Context mContext;
    private static volatile CommunicationModule instance = null;

    private CommunicationModule(Context context){
        mContext = context;
    }

    public static CommunicationModule getInstance(Context context) {
        if (instance == null) {
            synchronized (CommunicationModule.class) {
                if (instance == null) {
                    instance = new CommunicationModule(context);
                }
            }
        }

        return instance;
    }

    public void call(String number, final ModuleResultListener listener)  {
        if (listener == null) return;

        boolean tel = Util.isPhone(number);
        if (!tel || TextUtils.isEmpty(number)) {
            listener.onResult(Util.getError(Constant.CALL_INVALID_ARGUMENT, Constant.CALL_INVALID_ARGUMENT_CODE));
            return;
        }

        try {
            Intent intent = new Intent(Intent.ACTION_CALL, Uri.parse("tel:" + number));
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mContext.startActivity(intent);
            listener.onResult(null);
        } catch (Exception e) {
            e.printStackTrace();
            listener.onResult(Util.getError(Constant.CALL_PHONE_PERMISSION_DENIED, Constant.CALL_PHONE_PERMISSION_DENIED_CODE));
        }
    }

    public void mail(String[] tos, HashMap<String, String> params, ModuleResultListener listener){
        if (listener == null) return;

        if (tos==null||tos.length<1){
            listener.onResult(Util.getError(Constant.MAIL_INVALID_ARGUMENT, Constant.MAIL_INVALID_ARGUMENT_CODE));
            return;
        }
        for (String to: tos) {
            if (!Util.isEmail(to)) {
                listener.onResult(Util.getError(Constant.MAIL_INVALID_ARGUMENT, Constant.MAIL_INVALID_ARGUMENT_CODE));
                return;
            }
        }

        String url = "";
        for (int i = 0; i < tos.length; i++) {
            url += tos[i] + (i == tos.length - 1 ? "" : ";");
        }
        String subject = params.containsKey("subject") ? params.get("subject") : "";
        String body = params.containsKey("body") ? params.get("body") : "";

        Uri uri = Uri.parse("mailto:" + url);
        Intent intent = new Intent(Intent.ACTION_SENDTO, uri);
        intent.putExtra(Intent.EXTRA_SUBJECT, subject); // 主题
        intent.putExtra(Intent.EXTRA_TEXT, body); // 正文
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mContext.startActivity(intent);
        listener.onResult(null);
    }

    public void sms(String[] tos, final String text, ModuleResultListener listener) {
        if (listener == null) return;

        if (tos == null || tos.length < 1) {
            listener.onResult(Util.getError(Constant.SMS_INVALID_ARGUMENT, Constant.SMS_INVALID_ARGUMENT_CODE));
            return;
        }
        for (String to : tos) {
            if (!Util.isPhone(to)) {
                listener.onResult(Util.getError(Constant.SMS_INVALID_ARGUMENT, Constant.SMS_INVALID_ARGUMENT_CODE));
                return;
            }
        }

        String url = "";
        for (int i = 0; i < tos.length; i++) {
            url += tos[i] + (i == tos.length - 1 ? "" : ";");
        }
        Uri uri = Uri.parse("smsto:" + url);
        Intent intent = new Intent(Intent.ACTION_VIEW, uri);
        intent.putExtra("sms_body", text==null?"":text);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        mContext.startActivity(intent);
        listener.onResult(null);
    }
}
