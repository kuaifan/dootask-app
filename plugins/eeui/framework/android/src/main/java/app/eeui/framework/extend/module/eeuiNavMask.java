/*
 * Copyright 2025 eeui.app
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package app.eeui.framework.extend.module;

import android.app.Activity;
import android.content.Context;
import android.content.res.Resources;
import android.graphics.Color;
import android.os.Build;
import android.view.DisplayCutout;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.widget.FrameLayout;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 导航栏遮罩管理类
 * 用于在顶部状态栏和底部安全区域添加浮层
 */
public class eeuiNavMask {

    // 遮罩计数器，用于生成唯一标识
    private static final AtomicInteger MASK_COUNTER = new AtomicInteger(0);

    // 遮罩信息缓存，Key: 唯一标识名称, Value: 遮罩对象
    private static final Map<String, NavMaskInfo> MASK_MAP = new HashMap<>();

    /**
     * 添加导航栏遮罩
     * @param context 上下文
     * @param color 遮罩颜色值 (支持 #RGB、#RRGGBB、#RRGGBBAA 格式)
     * @return 返回遮罩唯一标识
     */
    public static String addNavMask(Context context, String color) {
        if (context == null) {
            return "";
        }

        // 检查是否为 Activity
        if (!(context instanceof Activity)) {
            return "";
        }

        Activity activity = (Activity) context;

        // 生成唯一标识
        int id = MASK_COUNTER.incrementAndGet();
        String name = "navMask_" + id;

        // 解析颜色值
        int colorInt;
        try {
            colorInt = parseColor(color);
        } catch (Exception e) {
            colorInt = Color.TRANSPARENT;
        }

        // 创建遮罩信息对象
        NavMaskInfo maskInfo = new NavMaskInfo();
        maskInfo.name = name;
        maskInfo.color = colorInt;

        // 创建并添加状态栏和底部安全区域的遮罩视图
        addTopMask(activity, maskInfo);
        addBottomMask(activity, maskInfo);

        // 保存遮罩信息
        MASK_MAP.put(name, maskInfo);

        return name;
    }

    /**
     * 移除指定导航栏遮罩
     * @param context 上下文
     * @param name 遮罩唯一标识
     */
    public static void removeNavMask(Context context, String name) {
        if (context == null || name == null || name.isEmpty()) {
            return;
        }

        NavMaskInfo maskInfo = MASK_MAP.get(name);
        if (maskInfo != null) {
            removeMaskViews(maskInfo);
            MASK_MAP.remove(name);
        }
    }

    /**
     * 移除所有导航栏遮罩
     * @param context 上下文
     */
    public static void removeAllNavMasks(Context context) {
        if (context == null) {
            return;
        }

        for (NavMaskInfo maskInfo : MASK_MAP.values()) {
            removeMaskViews(maskInfo);
        }

        MASK_MAP.clear();
    }

    /**
     * 添加顶部状态栏遮罩
     * @param activity 当前活动
     * @param maskInfo 遮罩信息
     */
    private static void addTopMask(Activity activity, NavMaskInfo maskInfo) {
        // 获取状态栏高度
        int statusBarHeight = getStatusBarHeight(activity);
        if (statusBarHeight <= 0) {
            return;
        }

        // 获取当前窗口的内容视图
        ViewGroup decorView = (ViewGroup) activity.getWindow().getDecorView();

        // 创建顶部遮罩视图
        View topMaskView = new View(activity);
        topMaskView.setBackgroundColor(maskInfo.color);

        // 设置视图位于顶层
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            topMaskView.setElevation(1000f); // 确保在最上层
        }

        // 为顶部遮罩设置布局参数
        FrameLayout.LayoutParams topParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                statusBarHeight
        );
        topParams.topMargin = 0;

        // 设置初始透明度为0，准备淡入动画
        topMaskView.setAlpha(0f);

        // 直接添加到DecorView
        decorView.addView(topMaskView, topParams);
        maskInfo.topView = topMaskView;

        // 添加淡入动画
        topMaskView.animate()
                .alpha(1f)
                .setDuration(150) // 0.15秒
                .start();
    }

    /**
     * 添加底部安全区域遮罩
     * @param activity 当前活动
     * @param maskInfo 遮罩信息
     */
    private static void addBottomMask(Activity activity, NavMaskInfo maskInfo) {
        // 获取底部安全区域高度
        int navigationBarHeight = getNavigationBarHeight(activity);
        if (navigationBarHeight <= 0) {
            return;
        }

        // 获取当前窗口的DecorView
        ViewGroup decorView = (ViewGroup) activity.getWindow().getDecorView();

        // 创建底部遮罩视图
        View bottomMaskView = new View(activity);
        bottomMaskView.setBackgroundColor(maskInfo.color);

        // 设置视图位于顶层
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            bottomMaskView.setElevation(1000f); // 确保在最上层
        }

        // 为底部遮罩设置布局参数
        FrameLayout.LayoutParams bottomParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                navigationBarHeight
        );
        bottomParams.gravity = Gravity.BOTTOM;

        // 设置初始透明度为0，准备淡入动画
        bottomMaskView.setAlpha(0f);

        // 直接添加到DecorView
        decorView.addView(bottomMaskView, bottomParams);
        maskInfo.bottomView = bottomMaskView;

        // 添加淡入动画
        bottomMaskView.animate()
                .alpha(1f)
                .setDuration(150) // 0.15秒
                .start();
    }

    /**
     * 移除遮罩视图
     * @param maskInfo 遮罩信息
     */
    private static void removeMaskViews(NavMaskInfo maskInfo) {
        // 移除顶部视图（带淡出动画）
        if (maskInfo.topView != null) {
            final View topView = maskInfo.topView;
            final ViewGroup topParent = (ViewGroup) topView.getParent();

            topView.animate()
                    .alpha(0f)
                    .setDuration(150) // 0.15秒
                    .withEndAction(new Runnable() {
                        @Override
                        public void run() {
                            if (topParent != null) {
                                topParent.removeView(topView);
                            }
                        }
                    })
                    .start();

            maskInfo.topView = null;
        }

        // 移除底部视图（带淡出动画）
        if (maskInfo.bottomView != null) {
            final View bottomView = maskInfo.bottomView;
            final ViewGroup bottomParent = (ViewGroup) bottomView.getParent();

            bottomView.animate()
                    .alpha(0f)
                    .setDuration(150) // 0.15秒
                    .withEndAction(new Runnable() {
                        @Override
                        public void run() {
                            if (bottomParent != null) {
                                bottomParent.removeView(bottomView);
                            }
                        }
                    })
                    .start();

            maskInfo.bottomView = null;
        }
    }

    /**
     * 获取状态栏高度
     * @param context 上下文
     * @return 状态栏高度（像素）
     */
    public static int getStatusBarHeight(Context context) {
        int result = 0;
        int resourceId = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            result = context.getResources().getDimensionPixelSize(resourceId);
        }
        return result;
    }

    /**
     * 获取底部导航栏高度
     * @param context 上下文
     * @return 导航栏高度（像素）
     */
    public static int getNavigationBarHeight(Context context) {
        if (context == null) {
            return 0;
        }

        // 系统窗口的显示标志
        boolean hasNavigationBar = false;

        // 先从系统资源检查是否有导航栏
        int resourceId = context.getResources().getIdentifier("config_showNavigationBar", "bool", "android");
        if (resourceId > 0) {
            hasNavigationBar = context.getResources().getBoolean(resourceId);
        }

        // 如果是Activity，进一步检查可见状态
        if (context instanceof Activity) {
            Activity activity = (Activity) context;
            Window window = activity.getWindow();

            if (!isNavBarVisible(window)) {
                hasNavigationBar = false;
            }
        }

        // 如果设备有导航栏，获取其高度
        if (hasNavigationBar) {
            Resources resources = context.getResources();
            int navBarResourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android");
            if (navBarResourceId > 0) {
                return resources.getDimensionPixelSize(navBarResourceId);
            }
        }

        // 兜底方案：检查底部安全区域
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && context instanceof Activity) {
            Activity activity = (Activity) context;
            Window window = activity.getWindow();
            WindowInsets insets = window.getDecorView().getRootWindowInsets();
            if (insets != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    // Android 11+
                    return insets.getInsets(WindowInsets.Type.navigationBars()).bottom;
                } else {
                    // Android 10
                    return insets.getSystemWindowInsetBottom();
                }
            }
        }

        // 如果以上方法都无法检测，返回一个固定值作为底部安全区域
        if (hasNotch(context)) {
            // 有刘海屏的设备，返回一个常见的安全区域高度
            return dp2px(context, 34);
        }

        return 0;
    }

    /**
     * 判断 Navigation Bar 是否可见
     * @param window {@link Window}
     * @return {@code true} yes, {@code false} no
     */
    public static boolean isNavBarVisible(final Window window) {
        if (window != null) {
            boolean   isVisible = false;
            ViewGroup decorView = (ViewGroup) window.getDecorView();
            for (int i = 0, len = decorView.getChildCount(); i < len; i++) {
                final View child = decorView.getChildAt(i);
                final int  id    = child.getId();
                if (id != View.NO_ID) {
                    String resourceEntryName = Resources.getSystem().getResourceEntryName(id);
                    if ("navigationBarBackground".equals(resourceEntryName)
                        && child.getVisibility() == View.VISIBLE) {
                        isVisible = true;
                        break;
                    }
                }
            }
            if (isVisible) {
                int visibility = decorView.getSystemUiVisibility();
                isVisible = (visibility & View.SYSTEM_UI_FLAG_HIDE_NAVIGATION) == 0;
            }
            return isVisible;
        }
        return false;
    }

    /**
     * 检测设备是否有刘海屏
     * @param context 上下文
     * @return 是否有刘海屏
     */
    private static boolean hasNotch(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // Android P 及以上系统，使用官方API检测
            if (context instanceof Activity) {
                Activity activity = (Activity) context;
                View decorView = activity.getWindow().getDecorView();
                WindowInsets insets = decorView.getRootWindowInsets();
                if (insets != null) {
                    DisplayCutout cutout = insets.getDisplayCutout();
                    return cutout != null;
                }
            }
        }

        // 检查厂商，某些特定厂商的设备更可能有刘海屏
        String manufacturer = Build.MANUFACTURER.toLowerCase();
        return manufacturer.contains("huawei") ||
               manufacturer.contains("xiaomi") ||
               manufacturer.contains("oppo") ||
               manufacturer.contains("vivo") ||
               manufacturer.contains("honor");
    }

    /**
     * dp转px
     * @param context 上下文
     * @param dp dp值
     * @return px值
     */
    private static int dp2px(Context context, float dp) {
        float scale = context.getResources().getDisplayMetrics().density;
        return (int) (dp * scale + 0.5f);
    }

    /**
     * 解析颜色值
     * 支持以下格式：
     * #RGB       - 短十六进制颜色
     * #RRGGBB    - 标准十六进制颜色
     * #RRGGBBAA  - 网页格式带透明度的十六进制颜色 (网页/iOS标准)
     * @param colorString 颜色字符串
     * @return 颜色整数值
     */
    public static int parseColor(String colorString) {
        if (colorString == null || colorString.isEmpty()) {
            return Color.TRANSPARENT;
        }

        // 去除空格并转换为大写
        String color = colorString.trim().toUpperCase();

        // 去除 # 前缀
        if (color.startsWith("#")) {
            color = color.substring(1);
        }

        int a, r, g, b;

        // 处理 #RGB 格式
        if (color.length() == 3) {
            r = Integer.parseInt(color.substring(0, 1) + color.substring(0, 1), 16);
            g = Integer.parseInt(color.substring(1, 2) + color.substring(1, 2), 16);
            b = Integer.parseInt(color.substring(2, 3) + color.substring(2, 3), 16);
            a = 255;
        }
        // 处理 #RRGGBB 格式
        else if (color.length() == 6) {
            r = Integer.parseInt(color.substring(0, 2), 16);
            g = Integer.parseInt(color.substring(2, 4), 16);
            b = Integer.parseInt(color.substring(4, 6), 16);
            a = 255;
        }
        // 处理 #RRGGBBAA 格式 (网页/iOS格式)
        else if (color.length() == 8) {
            // 统一使用网页/iOS格式 (#RRGGBBAA)
            r = Integer.parseInt(color.substring(0, 2), 16);
            g = Integer.parseInt(color.substring(2, 4), 16);
            b = Integer.parseInt(color.substring(4, 6), 16);
            a = Integer.parseInt(color.substring(6, 8), 16);
        }
        // 不支持的格式，返回透明色
        else {
            return Color.TRANSPARENT;
        }

        return Color.argb(a, r, g, b);
    }

    /**
     * 遮罩信息内部类
     */
    private static class NavMaskInfo {
        String name;            // 遮罩唯一标识
        int color;              // 遮罩颜色
        View topView;           // 顶部遮罩视图
        View bottomView;        // 底部遮罩视图
    }
}
