package app.eeui.framework.extend.module.location;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.fragment.app.FragmentActivity;

import java.util.HashSet;
import java.util.Set;

public class LocationHelper {
    private static final String TAG = "LocationHelper";
    private static LocationHelper instance;
    private final Context context;
    private final LocationManager locationManager;
    private LocationListener locationListener;
    private final Set<OnLocationResultListener> listeners = new HashSet<>();
    private static final int PERMISSION_REQUEST_CODE = 1001;

    private Handler timeoutHandler;
    private Location lastReturnedLocation;
    private LocationState currentState = LocationState.IDLE;
    private LocationConfig config;

    // 位置监听接口
    public interface OnLocationResultListener {
        void onSuccess(double latitude, double longitude);

        void onError(String error);
    }

    // 位置错误枚举
    public enum LocationError {
        PERMISSION_DENIED("PERMISSION_DENIED"),
        LOCATION_DISABLED("LOCATION_DISABLED"),
        TIMEOUT("TIMEOUT"),
        LOW_ACCURACY("LOW_ACCURACY"),
        SECURITY_EXCEPTION("SECURITY_EXCEPTION"),
        UNEXPECTED_ERROR("UNEXPECTED_ERROR");

        private final String code;

        LocationError(String code) {
            this.code = code;
        }

        public String getCode() {
            return code;
        }
    }

    // 位置状态枚举
    public enum LocationState {
        IDLE,           // 空闲状态
        REQUESTING,     // 正在请求权限
        UPDATING        // 正在更新位置
    }

    // 位置配置类
    public static class LocationConfig {
        public final long timeout;              // 超时时间（毫秒）
        public final long maxLocationAge;       // 位置最大有效期（毫秒）
        public final long minUpdateInterval;    // 最小更新间隔（毫秒）
        public final float minUpdateDistance;   // 最小更新距离（米）
        public final float minAccuracy;         // 最小精度要求（米）
        public final boolean useLastKnown;      // 是否使用最后已知位置
        public final boolean useBothProviders;  // 是否同时使用GPS和网络定位
        public final CoordinateSystem coordinateSystem; // 坐标系

        private LocationConfig(Builder builder) {
            this.timeout = builder.timeout;
            this.maxLocationAge = builder.maxLocationAge;
            this.minUpdateInterval = builder.minUpdateInterval;
            this.minUpdateDistance = builder.minUpdateDistance;
            this.minAccuracy = builder.minAccuracy;
            this.useLastKnown = builder.useLastKnown;
            this.useBothProviders = builder.useBothProviders;
            this.coordinateSystem = builder.coordinateSystem;
        }

        public static class Builder {
            private long timeout = 15000;
            private long maxLocationAge = 30000;
            private long minUpdateInterval = 500;
            private float minUpdateDistance = 0;
            private float minAccuracy = 100;
            private boolean useLastKnown = true;
            private boolean useBothProviders = true;
            private CoordinateSystem coordinateSystem = CoordinateSystem.WGS84;

            public Builder setTimeout(long timeout) {
                this.timeout = timeout;
                return this;
            }

            public Builder setMaxLocationAge(long maxLocationAge) {
                this.maxLocationAge = maxLocationAge;
                return this;
            }

            public Builder setMinUpdateInterval(long minUpdateInterval) {
                this.minUpdateInterval = minUpdateInterval;
                return this;
            }

            public Builder setMinUpdateDistance(float minUpdateDistance) {
                this.minUpdateDistance = minUpdateDistance;
                return this;
            }

            public Builder setMinAccuracy(float minAccuracy) {
                this.minAccuracy = minAccuracy;
                return this;
            }

            public Builder setUseLastKnown(boolean useLastKnown) {
                this.useLastKnown = useLastKnown;
                return this;
            }

            public Builder setUseBothProviders(boolean useBothProviders) {
                this.useBothProviders = useBothProviders;
                return this;
            }

            public LocationConfig build() {
                return new LocationConfig(this);
            }

            public Builder setCoordinateSystem(CoordinateSystem coordinateSystem) {
                this.coordinateSystem = coordinateSystem;
                return this;
            }
        }
    }

    // 私有构造方法
    private LocationHelper(Context context) {
        this.context = context.getApplicationContext();
        this.locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
        this.timeoutHandler = new Handler(Looper.getMainLooper());
        this.config = new LocationConfig.Builder().build(); // 使用默认配置
    }

    // 获取单例实例
    public static LocationHelper getInstance(Context context) {
        if (instance == null) {
            synchronized (LocationHelper.class) {
                if (instance == null) {
                    instance = new LocationHelper(context);
                }
            }
        }
        return instance;
    }

    // 设置配置
    public void setConfig(LocationConfig config) {
        this.config = config;
    }

    // 添加监听器
    public void addListener(OnLocationResultListener listener) {
        if (listener != null) {
            listeners.add(listener);
        }
    }

    // 移除监听器
    public void removeListener(OnLocationResultListener listener) {
        listeners.remove(listener);
    }

    // 清除所有监听器
    public void clearListeners() {
        listeners.clear();
    }

    // 获取当前状态
    public LocationState getCurrentState() {
        return currentState;
    }

    // 请求位置
    public void requestLocation(FragmentActivity activity, OnLocationResultListener listener) {
        if (currentState != LocationState.IDLE) {
            Log.d(TAG, "Location request already in progress");
            if (listener != null) {
                listeners.add(listener);
            }
            return;
        }

        if (listener != null) {
            listeners.add(listener);
        }

        lastReturnedLocation = null;
        currentState = LocationState.REQUESTING;

        if (!hasLocationPermission(activity)) {
            Log.d(TAG, "Requesting location permissions");
            requestLocationPermission(activity);
            return;
        }

        startLocation();
    }

    // 刷新位置
    public void refresh() {
        Log.d(TAG, "Refreshing location");
        if (currentState != LocationState.IDLE) {
            lastReturnedLocation = null;
            startLocation();
        }
    }

    // 停止位置更新
    public void stop() {
        Log.d(TAG, "Stopping location updates");
        currentState = LocationState.IDLE;
        lastReturnedLocation = null;
        if (locationListener != null) {
            try {
                locationManager.removeUpdates(locationListener);
            } catch (SecurityException e) {
                Log.e(TAG, "Error removing location updates", e);
            }
            locationListener = null;
        }
        timeoutHandler.removeCallbacksAndMessages(null);
    }

    // 处理权限请求结果
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Location permission granted");
                startLocation();
            } else {
                Log.e(TAG, "Location permission denied");
                handleError(LocationError.PERMISSION_DENIED, null);
            }
        }
    }

    // 检查位置权限
    private boolean hasLocationPermission(Context context) {
        return ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
            || ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    // 请求位置权限
    private void requestLocationPermission(FragmentActivity activity) {
        ActivityCompat.requestPermissions(activity,
            new String[]{
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            },
            PERMISSION_REQUEST_CODE);
    }

    // 开始位置更新
    @SuppressWarnings("MissingPermission")
    private void startLocation() {
        currentState = LocationState.UPDATING;

        // 检查位置服务是否可用
        if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
            && !locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            handleError(LocationError.LOCATION_DISABLED, null);
            return;
        }

        // 设置超时
        timeoutHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (currentState == LocationState.UPDATING && lastReturnedLocation == null) {
                    handleError(LocationError.TIMEOUT, null);
                }
            }
        }, config.timeout);

        try {
            // 尝试使用最后已知位置
            if (config.useLastKnown) {
                Location lastLocation = getLastKnownLocation();
                if (lastLocation != null && isLocationValid(lastLocation)) {
                    returnLocation(lastLocation);
                }
            }

            // 创建位置监听器
            locationListener = new LocationListener() {
                @Override
                public void onLocationChanged(@NonNull Location location) {
                    if (location != null && isLocationValid(location)) {
                        returnLocation(location);
                    }
                }

                @Override
                public void onStatusChanged(String provider, int status, Bundle extras) {
                    Log.d(TAG, "Provider status changed: " + provider + ", status: " + status);
                }

                @Override
                public void onProviderEnabled(@NonNull String provider) {
                    Log.d(TAG, "Provider enabled: " + provider);
                }

                @Override
                public void onProviderDisabled(@NonNull String provider) {
                    Log.d(TAG, "Provider disabled: " + provider);
                    if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                        && !locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                        handleError(LocationError.LOCATION_DISABLED, null);
                    }
                }
            };

            // 注册位置更新
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    config.minUpdateInterval,
                    config.minUpdateDistance,
                    locationListener,
                    Looper.getMainLooper()
                );
            }

            if (config.useBothProviders && locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    config.minUpdateInterval,
                    config.minUpdateDistance,
                    locationListener,
                    Looper.getMainLooper()
                );
            }

        } catch (SecurityException e) {
            handleError(LocationError.SECURITY_EXCEPTION, e);
        } catch (Exception e) {
            handleError(LocationError.UNEXPECTED_ERROR, e);
        }
    }

    // 获取最后已知位置
    @SuppressWarnings("MissingPermission")
    private Location getLastKnownLocation() {
        Location bestLocation = null;
        long bestTime = 0;

        try {
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                Location location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
                if (location != null && location.getTime() > bestTime) {
                    bestLocation = location;
                    bestTime = location.getTime();
                }
            }
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                Location location = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
                if (location != null && location.getTime() > bestTime) {
                    bestLocation = location;
                    bestTime = location.getTime();
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting last known location", e);
        }

        return bestLocation;
    }

    // 验证位置是否有效
    private boolean isLocationValid(Location location) {
        if (location == null) return false;

        // 检查位置时间
        long locationAge = System.currentTimeMillis() - location.getTime();
        if (locationAge > config.maxLocationAge) return false;

        // 检查精度
        if (location.hasAccuracy() && location.getAccuracy() > config.minAccuracy) return false;

        // 检查是否是更好的位置
        return isBetterLocation(location);
    }

    // 判断是否是更好的位置
    private boolean isBetterLocation(Location location) {
        if (lastReturnedLocation == null) {
            return true;
        }

        // 检查时间差
        long timeDelta = location.getTime() - lastReturnedLocation.getTime();
        boolean isSignificantlyNewer = timeDelta > config.maxLocationAge;
        boolean isSignificantlyOlder = timeDelta < -config.maxLocationAge;
        boolean isNewer = timeDelta > 0;

        if (isSignificantlyNewer) {
            return true;
        } else if (isSignificantlyOlder) {
            return false;
        }

        // 检查精度
        int accuracyDelta = (int) (location.getAccuracy() - lastReturnedLocation.getAccuracy());
        boolean isLessAccurate = accuracyDelta > 0;
        boolean isMoreAccurate = accuracyDelta < 0;
        boolean isSignificantlyLessAccurate = accuracyDelta > 200;

        // 检查是否是同一个提供者
        boolean isFromSameProvider = isSameProvider(location.getProvider(),
            lastReturnedLocation.getProvider());

        // 综合判断
        if (isMoreAccurate) {
            return true;
        } else if (isNewer && !isLessAccurate) {
            return true;
        } else return isNewer && !isSignificantlyLessAccurate && isFromSameProvider;
    }

    // 检查是否是同一个位置提供者
    private boolean isSameProvider(String provider1, String provider2) {
        if (provider1 == null) {
            return provider2 == null;
        }
        return provider1.equals(provider2);
    }

    // 返回位置结果
    private void returnLocation(Location location) {
        if (currentState == LocationState.UPDATING) {
            lastReturnedLocation = location;

            // 获取原始坐标
            double latitude = location.getLatitude();
            double longitude = location.getLongitude();

            // 根据配置转换坐标系
            if (config.coordinateSystem == CoordinateSystem.WGS84) {
                // Android 在中国返回的是 GCJ02，需要转换为 WGS84
                CoordinateConverter.LatLng wgs84 = CoordinateConverter.gcj02ToWgs84(latitude, longitude);
                latitude = wgs84.latitude;
                longitude = wgs84.longitude;
            }
            // 如果需要其他坐标系，可以在这里添加转换

            // 通知所有监听器
            final double finalLat = latitude;
            final double finalLng = longitude;
            for (OnLocationResultListener listener : listeners) {
                if (listener != null) {
                    listener.onSuccess(finalLat, finalLng);
                }
            }
        }
    }

    // 处理错误
    private void handleError(LocationError error, Exception e) {
        if (e != null) {
            Log.e(TAG, "Location error: " + error.getCode(), e);
        } else {
            Log.e(TAG, "Location error: " + error.getCode());
        }

        for (OnLocationResultListener listener : listeners) {
            if (listener != null) {
                listener.onError(error.getCode());
            }
        }
        stop();
    }
}
