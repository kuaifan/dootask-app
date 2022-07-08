package eeui.android.communication.module.communication;

import android.content.Context;

import java.io.File;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Util {
    public static HashMap<String, HashMap<String, Object>> getError(String msg, int code){
        HashMap<String, HashMap<String, Object>> result = new HashMap<>();
        HashMap<String, Object> param = new HashMap<>();
        param.put("code", code);
        param.put("message", msg);
        result.put("error", param);
        return result;
    }


    public static int getScreenWidth(Context context){
        return context.getResources().getDisplayMetrics().widthPixels;
    }

    public static int getScreenHeight(Context context){
        return context.getResources().getDisplayMetrics().heightPixels;
    }

    public static float getScreenDpiX(Context context){
        return context.getResources().getDisplayMetrics().xdpi;
    }

    public static float getScreenDpiY(Context context){
        return context.getResources().getDisplayMetrics().ydpi;
    }

    public static float getDensity(Context context){
        return context.getResources().getDisplayMetrics().density;
    }

    public static float dp2px(Context context, float dp){
        return context.getResources().getDisplayMetrics().density * dp;
    }

    public static File getRootFile(){
        File file = new File(Constant.ROOT_PATH);
        if (!file.exists()) {
            file.mkdir();
        }
        return file;
    }

    public static File getFile(String fileName) throws IOException {
        File file = new File(getRootFile(), fileName);
        if (file.exists()) {
            file.delete();
            file.createNewFile();
        } else {
            file.createNewFile();
        }
        return file;
    }

    public static String getRootFilePath(){
        File file = new File(Constant.ROOT_PATH);
        if (!file.exists()) {
            file.mkdir();
        }
        return file.getAbsolutePath();
    }

    public static String getFilePath(String fileName) throws IOException {
        File file = new File(getRootFile(), fileName);
        if (file.exists()) {
            file.delete();
            file.createNewFile();
        } else {
            file.createNewFile();
        }
        return file.getAbsolutePath();
    }

    public static boolean isPhone(String str) {
        Pattern p = null;
        Matcher m = null;
        boolean b = false;
        p = Pattern.compile("^\\+?[\\d\\-\\#\\*\\.\\(\\)]+$");
        m = p.matcher(str);
        b = m.matches();
        return b;
    }

    public static boolean isEmail(String str) {
        Pattern p = null;
        Matcher m = null;
        boolean b = false;
        p = Pattern.compile("^(\\w)+([\\.\\-\\_]\\w+)*@(\\w)+(([\\.\\-\\_]\\w+)+)$");
        m = p.matcher(str);
        b = m.matches();
        return b;
    }

    private static int MY_PERMISSIONS_EXTERNAL = 111;

    public static String getMD5(String val) throws NoSuchAlgorithmException {
        MessageDigest md5 = MessageDigest.getInstance("MD5");
        md5.update(val.getBytes());
        byte[] m = md5.digest();//加密
        return getString(m);
    }

    private static String getString(byte[] b){
        StringBuffer sb = new StringBuffer();
        for(int i = 0; i < b.length; i ++){
            sb.append(b[i]);
        }
        return sb.toString();
    }

}
