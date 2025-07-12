package app.eeui.framework.extend.module.utilcode.util;


import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;

import app.eeui.framework.activity.PageActivity;
import app.eeui.framework.extend.module.utilcode.constant.PermissionConstants;


import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * <pre>
 *     author: Blankj
 *     blog  : http://blankj.com
 *     time  : 2017/12/29
 *     desc  : utils about permission
 * </pre>
 */
public final class PermissionUtils {

    private static final List<String> PERMISSIONS = getPermissions();

    private static PermissionUtils sInstance;

    private OnRationaleListener mOnRationaleListener;
    private SimpleCallback mSimpleCallback;
    private FullCallback mFullCallback;
    private ThemeCallback mThemeCallback;
    private Set<String> mPermissions;
    private List<String> mPermissionsRequest;
    private List<String> mPermissionsGranted;
    private List<String> mPermissionsDenied;
    private List<String> mPermissionsDeniedForever;

    public static boolean isShowApply = false;
    public static boolean isShowRationale = false;
    public static boolean isShowOpenAppSetting = false;

    /**
     * Return the permissions used in application.
     *
     * @return the permissions used in application
     */
    public static List<String> getPermissions() {
        return getPermissions(Utils.getApp().getPackageName());
    }

    /**
     * Return the permissions used in application.
     *
     * @param packageName The name of the package.
     * @return the permissions used in application
     */
    public static List<String> getPermissions(final String packageName) {
        PackageManager pm = Utils.getApp().getPackageManager();
        try {
            return Arrays.asList(
                    pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
                            .requestedPermissions
            );
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    /**
     * Return whether <em>you</em> have granted the permissions.
     *
     * @param permissions The permissions.
     * @return {@code true}: yes<br>{@code false}: no
     */
    public static boolean isGranted(final String... permissions) {
        for (String permission : permissions) {
            if (!isGranted(permission)) {
                return false;
            }
        }
        return true;
    }

    private static boolean isGranted(final String permission) {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M
                || PackageManager.PERMISSION_GRANTED
                == ContextCompat.checkSelfPermission(Utils.getApp(), permission);
    }

    /**
     * Launch the application's details settings.
     */
    public static void launchAppDetailsSettings() {
        Intent intent = new Intent("android.settings.APPLICATION_DETAILS_SETTINGS");
        intent.setData(Uri.parse("package:" + Utils.getApp().getPackageName()));
        Utils.getApp().startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
    }

    /**
     * Set the permissions.
     *
     * @param permissions The permissions.
     * @return the single {@link PermissionUtils} instance
     */
    public static PermissionUtils permission(@PermissionConstants.Permission final String... permissions) {
        return new PermissionUtils(permissions);
    }

    private PermissionUtils(final String... permissions) {
        mPermissions = new LinkedHashSet<>();
        for (String permission : permissions) {
            for (String aPermission : PermissionConstants.getPermissions(permission)) {
                if (PERMISSIONS.contains(aPermission)) {
                    mPermissions.add(aPermission);
                }
            }
        }
        sInstance = this;
    }

    /**
     * Set rationale listener.
     *
     * @param listener The rationale listener.
     * @return the single {@link PermissionUtils} instance
     */
    public PermissionUtils rationale(final OnRationaleListener listener) {
        mOnRationaleListener = listener;
        return this;
    }

    /**
     * Set the simple call back.
     *
     * @param callback the simple call back
     * @return the single {@link PermissionUtils} instance
     */
    public PermissionUtils callback(final SimpleCallback callback) {
        mSimpleCallback = callback;
        return this;
    }

    /**
     * Set the full call back.
     *
     * @param callback the full call back
     * @return the single {@link PermissionUtils} instance
     */
    public PermissionUtils callback(final FullCallback callback) {
        mFullCallback = callback;
        return this;
    }

    /**
     * Set the theme callback.
     *
     * @param callback The theme callback.
     * @return the single {@link PermissionUtils} instance
     */
    public PermissionUtils theme(final ThemeCallback callback) {
        mThemeCallback = callback;
        return this;
    }

    /**
     * Start request.
     */
    public void request() {
        android.util.Log.d("PermissionUtils", "gggggggggg: 开始权限请求");
        isShowApply = true;
        mPermissionsGranted = new ArrayList<>();
        mPermissionsRequest = new ArrayList<>();
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            android.util.Log.d("PermissionUtils", "gggggggggg: Android版本 < M，直接授予所有权限");
            mPermissionsGranted.addAll(mPermissions);
            requestCallback();
        } else {
            android.util.Log.d("PermissionUtils", "gggggggggg: 检查权限状态，总权限数: " + mPermissions.size());
            for (String permission : mPermissions) {
                if (isGranted(permission)) {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 权限已授予: " + permission);
                    mPermissionsGranted.add(permission);
                } else {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 权限未授予: " + permission);
                    mPermissionsRequest.add(permission);
                }
            }
            android.util.Log.d("PermissionUtils", "gggggggggg: 已授予权限数: " + mPermissionsGranted.size() + ", 需要请求权限数: " + mPermissionsRequest.size());
            if (mPermissionsRequest.isEmpty()) {
                android.util.Log.d("PermissionUtils", "gggggggggg: 所有权限已授予，直接回调");
                requestCallback();
            } else {
                android.util.Log.d("PermissionUtils", "gggggggggg: 启动权限请求Activity");
                startPermissionActivity();
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private void startPermissionActivity() {
        android.util.Log.d("PermissionUtils", "gggggggggg: 准备启动权限请求Activity");
        mPermissionsDenied = new ArrayList<>();
        mPermissionsDeniedForever = new ArrayList<>();
        PageActivity.startPermission(Utils.getApp());
        android.util.Log.d("PermissionUtils", "gggggggggg: 权限请求Activity已启动");
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    public boolean rationale(final Activity activity) {
        boolean isRationale = false;
        if (mOnRationaleListener != null) {
            for (String permission : mPermissionsRequest) {
                if (activity.shouldShowRequestPermissionRationale(permission)) {
                    getPermissionsStatus(activity);
                    mOnRationaleListener.rationale(again -> {
                        if (again) {
                            startPermissionActivity();
                        } else {
                            requestCallback();
                        }
                    });
                    isRationale = true;
                    break;
                }
            }
            mOnRationaleListener = null;
        }
        return isRationale;
    }

    private void getPermissionsStatus(final Activity activity) {
        android.util.Log.d("PermissionUtils", "gggggggggg: 开始获取权限状态，需要检查的权限数: " + mPermissionsRequest.size());
        for (String permission : mPermissionsRequest) {
            if (isGranted(permission)) {
                android.util.Log.d("PermissionUtils", "gggggggggg: 权限已授予: " + permission);
                mPermissionsGranted.add(permission);
            } else {
                android.util.Log.d("PermissionUtils", "gggggggggg: 权限被拒绝: " + permission);
                mPermissionsDenied.add(permission);
                if (!activity.shouldShowRequestPermissionRationale(permission)) {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 权限被永久拒绝: " + permission);
                    mPermissionsDeniedForever.add(permission);
                }
            }
        }
        android.util.Log.d("PermissionUtils", "gggggggggg: 权限状态获取完成 - 已授予: " + mPermissionsGranted.size() + ", 拒绝: " + mPermissionsDenied.size() + ", 永久拒绝: " + mPermissionsDeniedForever.size());
    }

    private void requestCallback() {
        // 确保在主线程中执行回调
        if (Looper.myLooper() != Looper.getMainLooper()) {
            android.util.Log.d("PermissionUtils", "gggggggggg: 不在主线程，切换到主线程执行回调");
            new Handler(Looper.getMainLooper()).post(this::requestCallback);
            return;
        }
        
        android.util.Log.d("PermissionUtils", "gggggggggg: 开始执行权限回调");
        android.util.Log.d("PermissionUtils", "gggggggggg: 权限状态统计 - 总权限数: " + mPermissions.size() + ", 已授予: " + mPermissionsGranted.size() + ", 拒绝: " + mPermissionsDenied.size() + ", 永久拒绝: " + mPermissionsDeniedForever.size());
        
        isShowApply = false;
        if (mSimpleCallback != null) {
            android.util.Log.d("PermissionUtils", "gggggggggg: 执行SimpleCallback回调");
            if (mPermissionsRequest.size() == 0
                    || mPermissions.size() == mPermissionsGranted.size()) {
                android.util.Log.d("PermissionUtils", "gggggggggg: 所有权限已授予，调用onGranted");
                mSimpleCallback.onGranted();
            } else {
                if (!mPermissionsDenied.isEmpty()) {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 有权限被拒绝，调用onDenied");
                    mSimpleCallback.onDenied();
                }
            }
            mSimpleCallback = null;
        }
        if (mFullCallback != null) {
            android.util.Log.d("PermissionUtils", "gggggggggg: 执行FullCallback回调");
            if (mPermissionsRequest.size() == 0
                    || mPermissions.size() == mPermissionsGranted.size()) {
                android.util.Log.d("PermissionUtils", "gggggggggg: 所有权限已授予，调用onGranted，授予的权限: " + mPermissionsGranted.toString());
                mFullCallback.onGranted(mPermissionsGranted);
            } else {
                if (!mPermissionsDenied.isEmpty()) {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 有权限被拒绝，调用onDenied，永久拒绝: " + mPermissionsDeniedForever.toString() + ", 拒绝: " + mPermissionsDenied.toString());
                    mFullCallback.onDenied(mPermissionsDeniedForever, mPermissionsDenied);
                }
            }
            mFullCallback = null;
        }
        mOnRationaleListener = null;
        mThemeCallback = null;
        android.util.Log.d("PermissionUtils", "gggggggggg: 权限回调执行完成");
    }

    public void onRequestPermissionsResult(final Activity activity) {
        android.util.Log.d("PermissionUtils", "gggggggggg: 权限请求结果回调");
        // Android 13+ 需要延迟处理，因为权限系统可能还在处理中
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            android.util.Log.d("PermissionUtils", "gggggggggg: Android 13+，延迟100ms处理");
            new Handler(Looper.getMainLooper()).postDelayed(() -> {
                if (activity != null && !activity.isFinishing() && !activity.isDestroyed()) {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 延迟处理 - Activity有效，开始获取权限状态");
                    getPermissionsStatus(activity);
                    requestCallback();
                } else {
                    android.util.Log.d("PermissionUtils", "gggggggggg: 延迟处理 - Activity无效，跳过处理");
                }
            }, 100);
        } else {
            android.util.Log.d("PermissionUtils", "gggggggggg: Android < 13，直接处理");
            getPermissionsStatus(activity);
            requestCallback();
        }
    }

    public interface OnRationaleListener {

        void rationale(ShouldRequest shouldRequest);

        interface ShouldRequest {
            void again(boolean again);
        }
    }

    public interface SimpleCallback {
        void onGranted();

        void onDenied();
    }

    public interface FullCallback {
        void onGranted(List<String> permissionsGranted);

        void onDenied(List<String> permissionsDeniedForever, List<String> permissionsDenied);
    }

    public interface ThemeCallback {
        void onActivityCreate(Activity activity);
    }

    /**
     * 获取实例名
     * @return
     */
    public static PermissionUtils getInstance() {
        return sInstance;
    }

    public ThemeCallback getThemeCallback() {
        return mThemeCallback;
    }

    public List<String> getPermissionsRequest() {
        return mPermissionsRequest;
    }

    /**
     * 解释权限的dialog
     */
    public static void showRationaleDialog(Context context, final PermissionUtils.OnRationaleListener.ShouldRequest shouldRequest, String desc) {
        if (isShowRationale) {
            return;
        }
        
        // 检查Activity是否有效
        if (context instanceof Activity) {
            Activity activity = (Activity) context;
            if (activity.isFinishing() || activity.isDestroyed()) {
                return;
            }
        }
        
        // 确保在主线程中运行
        if (Looper.myLooper() != Looper.getMainLooper()) {
            new Handler(Looper.getMainLooper()).post(() -> 
                showRationaleDialog(context, shouldRequest, desc)
            );
            return;
        }
        
        isShowRationale = true;
        String descMsg = !"".equals(desc) ? "[" + desc + "]" : "相关";
        
        try {
            new androidx.appcompat.app.AlertDialog.Builder(context)
                    .setTitle("申请权限")
                    .setMessage("请允许" + descMsg + "权限后才能继续")
                    .setPositiveButton("确定", (dialog, which) -> {
                        shouldRequest.again(true);
                        isShowRationale = false;
                    })
                    .setNegativeButton("取消", (dialog, which) -> {
                        shouldRequest.again(false);
                        isShowRationale = false;
                    })
                    .setCancelable(false)
                    .create()
                    .show();
        } catch (Exception e) {
            // 如果显示对话框失败，直接回调取消
            isShowRationale = false;
            shouldRequest.again(false);
        }
    }

    /**
     * 显示前往应用设置Dialog
     */
    public static void showOpenAppSettingDialog(Context context, String desc) {
        if (isShowOpenAppSetting) {
            return;
        }
        
        // 检查Activity是否有效
        if (context instanceof Activity) {
            Activity activity = (Activity) context;
            if (activity.isFinishing() || activity.isDestroyed()) {
                return;
            }
        }
        
        // 确保在主线程中运行
        if (Looper.myLooper() != Looper.getMainLooper()) {
            new Handler(Looper.getMainLooper()).post(() -> 
                showOpenAppSettingDialog(context, desc)
            );
            return;
        }
        
        isShowOpenAppSetting = true;
        String descMsg = !"".equals(desc) ? "[" + desc + "]" : "相关";
        
        try {
            new androidx.appcompat.app.AlertDialog.Builder(context)
                    .setTitle("需要权限")
                    .setMessage("我们需要" + descMsg + "权限，才能实现功能，点击前往，将转到应用的设置界面，请开启应用的" + descMsg + "权限。")
                    .setPositiveButton("前往", (dialog, which) -> {
                        PermissionUtils.launchAppDetailsSettings();
                        isShowOpenAppSetting = false;
                    })
                    .setNegativeButton("取消", (dialog, which) -> isShowOpenAppSetting = false)
                    .setCancelable(false)
                    .create()
                    .show();
        } catch (Exception e) {
            // 如果显示对话框失败，直接标记为未显示
            isShowOpenAppSetting = false;
        }
    }
}
