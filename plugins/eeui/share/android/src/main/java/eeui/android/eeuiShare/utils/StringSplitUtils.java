package eeui.android.eeuiShare.utils;

import java.util.List;

public class StringSplitUtils {
    public static String getStrings(List<String> list){
        String s = "";
        StringBuffer sb = new StringBuffer();
        for (String str: list) {
            sb.append(str).append(",");
        }
        s = sb.deleteCharAt(sb.length() - 1).toString();//去掉最后一个逗号
        return s;
    }
}
