package eeui.android.eeuiWebserver.module;

import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.content.Context;
import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Collections;
import java.util.List;
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

        // 去掉 "file://" 前缀
        if (directoryPath.startsWith("file://")) {
            directoryPath = directoryPath.substring(7);
        }

        // 检查是否已有运行的服务器
        if (sharedWebServer != null) {
            try {
                if (sharedWebServer.isAlive()) {
                    // 服务器已存在，返回已存在状态和服务信息
                    String serverURL = "http://" + getLocalIPAddress() + ":" + sharedWebServer.getListeningPort() + "/";
                    
                    JSONObject result = new JSONObject();
                    result.put("status", "exists");
                    result.put("message", "服务器已存在");
                    result.put("url", serverURL);
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
        File directory = new File(directoryPath);
        if (!directory.exists() || !directory.isDirectory()) {
            JSONObject result = new JSONObject();
            result.put("status", "error");
            result.put("message", "指定的目录不存在或不是有效目录");
            callback.invoke(result);
            return;
        }

        try {
            // 创建并启动服务器
            sharedWebServer = new WebServer(port, directoryPath, indexFile, keepalivePath);
            sharedWebServer.start();

            String serverURL = "http://" + getLocalIPAddress() + ":" + sharedWebServer.getListeningPort() + "/";
            
            JSONObject result = new JSONObject();
            result.put("status", "success");
            result.put("message", "服务器启动成功");
            result.put("url", serverURL);
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
        String serverURL = "";
        int port = 0;

        if (sharedWebServer != null) {
            try {
                isRunning = sharedWebServer.isAlive();
                if (isRunning) {
                    port = sharedWebServer.getListeningPort();
                    serverURL = "http://" + getLocalIPAddress() + ":" + port + "/";
                }
            } catch (Exception e) {
                isRunning = false;
            }
        }

        JSONObject result = new JSONObject();
        if (isRunning && !serverURL.isEmpty()) {
            result.put("status", "success");
            result.put("message", "服务器正在运行");
            result.put("url", serverURL);
            result.put("port", port);
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
        if (ipAddress == null || ipAddress.isEmpty() || ipAddress.equals("error")) {
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
                    return String.format("%d.%d.%d.%d",
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

        public WebServer(int port, String rootDirectory, String indexFile, String keepalivePath) {
            super(port);
            this.rootDirectory = rootDirectory;
            this.indexFile = indexFile;
            this.keepalivePath = keepalivePath;
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
            if (fileName.endsWith(".html") || fileName.endsWith(".htm")) {
                return "text/html";
            } else if (fileName.endsWith(".js")) {
                return "application/javascript";
            } else if (fileName.endsWith(".css")) {
                return "text/css";
            } else if (fileName.endsWith(".json")) {
                return "application/json";
            } else if (fileName.endsWith(".png")) {
                return "image/png";
            } else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
                return "image/jpeg";
            } else if (fileName.endsWith(".gif")) {
                return "image/gif";
            } else {
                return "application/octet-stream";
            }
        }
    }
}
