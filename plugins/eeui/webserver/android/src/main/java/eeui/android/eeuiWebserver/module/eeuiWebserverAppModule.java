package eeui.android.eeuiWebserver.module;

import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.content.Context;
import android.content.res.AssetManager;
import android.webkit.MimeTypeMap;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import com.taobao.weex.annotation.JSMethod;
import com.taobao.weex.bridge.JSCallback;
import com.alibaba.fastjson.JSONObject;

import app.eeui.framework.extend.base.WXModuleBase;
import fi.iki.elonen.NanoHTTPD;

public class eeuiWebserverAppModule extends WXModuleBase {

    private static WebServer sharedWebServer = null;

    /**
     * 启动HTTP服务器
     */
    @JSMethod
    public void startWebServer(Object params, JSCallback callback) {
        if (callback == null) {
            return;
        }

        String directoryPath = "";
        int port = 0;
        String indexFile = "index.html";
        String keepalivePath = "/__keepalive__";

        // 解析参数
        if (params instanceof Map) {
            Map<String, Object> paramMap = (Map<String, Object>) params;
            directoryPath = getString(paramMap, "path", "");
            port = getInt(paramMap, "port", 0);
            indexFile = getString(paramMap, "index", "index.html");
            keepalivePath = getString(paramMap, "keepalive", "/__keepalive__");
        } else if (params instanceof String) {
            directoryPath = (String) params;
        }

        // 处理路径前缀
        boolean isAssetsPath = false;
        String assetPath = "";

        if (directoryPath.startsWith("file:///android_asset/")) {
            isAssetsPath = true;
            assetPath = directoryPath.substring(22);
        } else if (directoryPath.startsWith("file://assets/")) {
            isAssetsPath = true;
            assetPath = directoryPath.substring(14);
        } else if (directoryPath.startsWith("file:///assets/")) {
            isAssetsPath = true;
            assetPath = directoryPath.substring(15);
        } else if (directoryPath.startsWith("file://")) {
            directoryPath = directoryPath.substring(7);
        }

        // 检查是否已有运行的服务器
        if (sharedWebServer != null) {
            try {
                if (sharedWebServer.isAlive()) {
                    JSONObject result = new JSONObject();
                    result.put("status", "exists");
                    result.put("message", "服务器已存在");
                    result.put("port", sharedWebServer.getListeningPort());
                    callback.invoke(result);
                    return;
                }
            } catch (Exception e) {
                // 如果出错，清空并重新创建
                sharedWebServer = null;
            }
        }

        // 检查目录是否存在
        if (!isAssetsPath) {
            File directory = new File(directoryPath);
            if (!directory.exists() || !directory.isDirectory()) {
                JSONObject result = new JSONObject();
                result.put("status", "error");
                result.put("message", "指定的目录不存在或不是有效目录");
                callback.invoke(result);
                return;
            }
        } else {
            // 对于assets路径，检查是否能访问
            try {
                AssetManager assetManager = getContext().getAssets();
                String[] files = assetManager.list(assetPath);
                if (files == null) {
                    JSONObject result = new JSONObject();
                    result.put("status", "error");
                    result.put("message", "指定的assets目录不存在或不是有效目录");
                    callback.invoke(result);
                    return;
                }
            } catch (IOException e) {
                JSONObject result = new JSONObject();
                result.put("status", "error");
                result.put("message", "无法访问assets目录: " + e.getMessage());
                callback.invoke(result);
                return;
            }
        }

        try {
            // 创建并启动服务器
            if (isAssetsPath) {
                sharedWebServer = new WebServer(port, getContext().getAssets(), assetPath, indexFile, keepalivePath);
            } else {
                sharedWebServer = new WebServer(port, directoryPath, indexFile, keepalivePath);
            }
            sharedWebServer.start();

            JSONObject result = new JSONObject();
            result.put("status", "success");
            result.put("message", "服务器启动成功");
            result.put("port", sharedWebServer.getListeningPort());
            callback.invoke(result);

        } catch (IOException e) {
            JSONObject result = new JSONObject();
            result.put("status", "error");
            result.put("message", "启动服务器失败：" + e.getMessage());
            callback.invoke(result);
        }
    }

    /**
     * 停止HTTP服务器
     */
    @JSMethod
    public void stopWebServer(JSCallback callback) {
        if (callback == null) {
            return;
        }

        boolean wasRunning = false;

        if (sharedWebServer != null) {
            try {
                wasRunning = sharedWebServer.isAlive();
                if (wasRunning) {
                    sharedWebServer.stop();
                }
            } catch (Exception e) {
                // 忽略异常
            }
            sharedWebServer = null;
        }

        JSONObject result = new JSONObject();
        if (wasRunning) {
            result.put("status", "success");
            result.put("message", "服务器已停止");
        } else {
            result.put("status", "error");
            result.put("message", "服务器未运行");
        }
        callback.invoke(result);
    }

    /**
     * 获取服务器状态
     */
    @JSMethod
    public void getServerStatus(JSCallback callback) {
        if (callback == null) {
            return;
        }

        boolean isRunning = false;

        if (sharedWebServer != null) {
            try {
                isRunning = sharedWebServer.isAlive();
            } catch (Exception e) {
                isRunning = false;
            }
        }

        JSONObject result = new JSONObject();
        if (isRunning) {
            result.put("status", "success");
            result.put("message", "服务器正在运行");
            result.put("port", sharedWebServer.getListeningPort());
        } else {
            result.put("status", "error");
            result.put("message", "服务器未运行");
        }
        callback.invoke(result);
    }

    /**
     * 获取本地IP地址
     */
    @JSMethod
    public void getLocalIPAddress(JSCallback callback) {
        if (callback == null) {
            return;
        }

        String ipAddress = getLocalIPAddress();

        JSONObject result = new JSONObject();
        if (ipAddress.isEmpty() || ipAddress.equals("error")) {
            result.put("status", "error");
            result.put("message", "获取本地IP地址失败");
        } else {
            result.put("status", "success");
            result.put("message", "获取本地IP地址成功");
            result.put("ip", ipAddress);
        }
        callback.invoke(result);
    }

    // 辅助方法
    private String getString(Map<String, Object> map, String key, String defaultValue) {
        Object value = map.get(key);
        return value != null ? value.toString() : defaultValue;
    }

    private int getInt(Map<String, Object> map, String key, int defaultValue) {
        Object value = map.get(key);
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        try {
            return Integer.parseInt(value.toString());
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private String getLocalIPAddress() {
        try {
            // 首先尝试获取WiFi IP
            WifiManager wifiManager = (WifiManager) getContext().getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifiManager != null) {
                WifiInfo wifiInfo = wifiManager.getConnectionInfo();
                int ipAddress = wifiInfo.getIpAddress();
                if (ipAddress != 0) {
                    return String.format(Locale.US, "%d.%d.%d.%d",
                        (ipAddress & 0xff),
                        (ipAddress >> 8 & 0xff),
                        (ipAddress >> 16 & 0xff),
                        (ipAddress >> 24 & 0xff));
                }
            }

            // 如果WiFi不可用，尝试其他网络接口
            List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
            for (NetworkInterface intf : interfaces) {
                List<InetAddress> addrs = Collections.list(intf.getInetAddresses());
                for (InetAddress addr : addrs) {
                    if (!addr.isLoopbackAddress() && !addr.isLinkLocalAddress()) {
                        String sAddr = addr.getHostAddress();
                        if (sAddr != null && sAddr.indexOf(':') < 0) { // IPv4
                            return sAddr;
                        }
                    }
                }
            }
        } catch (Exception e) {
            // 忽略异常
        }
        return "";
    }

    // 内部HTTP服务器类
    private static class WebServer extends NanoHTTPD {
        private final String rootDirectory;
        private final String indexFile;
        private final String keepalivePath;
        private final AssetManager assetManager;
        private final boolean isAssetsMode;

        // 文件系统模式构造函数
        public WebServer(int port, String rootDirectory, String indexFile, String keepalivePath) {
            super(port);
            this.rootDirectory = rootDirectory;
            this.indexFile = indexFile;
            this.keepalivePath = keepalivePath;
            this.assetManager = null;
            this.isAssetsMode = false;
        }

        // Assets模式构造函数
        public WebServer(int port, AssetManager assetManager, String assetPath, String indexFile, String keepalivePath) {
            super(port);
            this.rootDirectory = assetPath;
            this.indexFile = indexFile;
            this.keepalivePath = keepalivePath;
            this.assetManager = assetManager;
            this.isAssetsMode = true;
        }

        @Override
        public Response serve(IHTTPSession session) {
            String uri = session.getUri();

            // 处理keep-alive心跳请求
            if (keepalivePath.equals(uri)) {
                JSONObject response = new JSONObject();
                response.put("status", "success");
                response.put("timestamp", System.currentTimeMillis() / 1000);
                return newFixedLengthResponse(Response.Status.OK, "application/json", response.toString());
            }

            if (isAssetsMode) {
                return serveFromAssets(uri);
            } else {
                return serveFromFileSystem(uri);
            }
        }

        private Response serveFromAssets(String uri) {
            try {
                String assetPath = rootDirectory + uri;
                if (assetPath.endsWith("/")) {
                    assetPath += indexFile;
                }

                // 移除开头的斜杠
                if (assetPath.startsWith("/")) {
                    assetPath = assetPath.substring(1);
                }

                InputStream inputStream = assetManager.open(assetPath);
                return newChunkedResponse(Response.Status.OK, getMimeType(assetPath), inputStream);

            } catch (IOException e) {
                // 如果直接路径失败，尝试添加index文件
                try {
                    String indexPath = rootDirectory + uri;
                    if (!indexPath.endsWith("/")) {
                        indexPath += "/";
                    }
                    indexPath += indexFile;
                    if (indexPath.startsWith("/")) {
                        indexPath = indexPath.substring(1);
                    }

                    InputStream inputStream = assetManager.open(indexPath);
                    return newChunkedResponse(Response.Status.OK, getMimeType(indexPath), inputStream);

                } catch (IOException e2) {
                    return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "404 Not Found");
                }
            }
        }

        private Response serveFromFileSystem(String uri) {
            // 处理静态文件请求
            String filePath = rootDirectory + uri;
            File file = new File(filePath);

            // 如果是目录，尝试找index文件
            if (file.isDirectory()) {
                file = new File(file, indexFile);
                if (!file.exists()) {
                    return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "404 Not Found");
                }
            }

            if (!file.exists() || !file.isFile()) {
                return newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "404 Not Found");
            }

            try {
                return newChunkedResponse(Response.Status.OK, getMimeType(file.getName()),
                    new java.io.FileInputStream(file));
            } catch (IOException e) {
                return newFixedLengthResponse(Response.Status.INTERNAL_ERROR, "text/plain",
                    "500 Internal Server Error");
            }
        }

        private String getMimeType(String fileName) {
            // 获取文件扩展名
            int lastDot = fileName.lastIndexOf('.');
            if (lastDot == -1) {
                return "application/octet-stream"; // 没有扩展名
            }

            String extension = fileName.substring(lastDot + 1).toLowerCase(Locale.US);

            // 使用系统内置的MIME类型映射
            String mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);

            // 如果系统找不到对应的MIME类型，返回默认值
            return mimeType != null ? mimeType : "application/octet-stream";
        }
    }
}
