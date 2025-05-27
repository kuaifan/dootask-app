# eeuiWebserver iOS 插件

该插件基于 GCDWebServer 实现了本地HTTP服务器功能，可以为指定目录创建HTTP服务，供应用层调用和WebView访问。

## 架构说明

- **AppModule** (`eeuiWebserverAppModule`) - 主要功能模块，提供HTTP服务器功能，供应用层调用
- **WebModule** (`eeuiWebserverWebModule`) - 简单示例模块，仅供WebView内部调用演示

## 功能特性

- 🚀 快速启动本地HTTP服务器
- 📁 支持任意本地目录作为Web根目录
- 🌐 自动获取本地IP地址和端口信息
- 📱 支持WiFi和蜂窝网络
- ⚡ 支持文件范围请求（Range Requests）
- 🔄 实时状态查询

## 安装依赖

插件已自动添加 GCDWebServer 依赖，使用前请确保运行：

```bash
pod install
```

## API 方法

### 1. 启动HTTP服务器

**注意：** HTTP服务器功能位于AppModule中，供应用层调用。

```javascript
// 获取eeuiWebserver模块（AppModule）
const webserver = weex.requireModule('eeuiWebserver')

webserver.startWebServer('/path/to/your/directory', (result) => {
    if (result.success) {
        console.log('服务器启动成功！')
        console.log('访问地址：', result.url)
        console.log('本地IP：', result.ip)
        console.log('端口：', result.port)
    } else {
        console.log('启动失败：', result.message)
    }
})
```

**回调参数说明：**
- `success`: Boolean - 是否启动成功
- `message`: String - 操作结果消息
- `url`: String - 完整的服务器访问地址（成功时）
- `ip`: String - 本地IP地址（成功时）
- `port`: Number - 服务端口（成功时）

### 2. 停止HTTP服务器

```javascript
webserver.stopWebServer((result) => {
    if (result.success) {
        console.log('服务器已停止')
    } else {
        console.log('停止失败：', result.message)
    }
})
```

### 3. 获取服务器状态

```javascript
webserver.getServerStatus((result) => {
    if (result.isRunning) {
        console.log('服务器运行中')
        console.log('访问地址：', result.url)
        console.log('本地IP：', result.ip)
        console.log('端口：', result.port)
    } else {
        console.log('服务器未运行')
    }
})
```

## 使用示例

### 完整示例

```javascript
const webserver = weex.requireModule('eeuiWebserver')

// 启动服务器
function startServer() {
    // 假设要服务的目录路径
    const directoryPath = '/Users/youruser/Documents/webapp'
    
    webserver.startWebServer(directoryPath, (result) => {
        if (result.success) {
            console.log('🎉 HTTP服务器启动成功！')
            console.log('📡 访问地址：', result.url)
            console.log('🌐 本地IP：', result.ip)
            console.log('🔌 端口：', result.port)
            
            // 在WebView中加载
            loadWebView(result.url)
        } else {
            console.error('❌ 启动失败：', result.message)
        }
    })
}

// 停止服务器
function stopServer() {
    webserver.stopWebServer((result) => {
        if (result.success) {
            console.log('⏹️ 服务器已停止')
        }
    })
}

// 检查状态
function checkStatus() {
    webserver.getServerStatus((result) => {
        if (result.isRunning) {
            console.log('✅ 服务器运行中，地址：', result.url)
        } else {
            console.log('❌ 服务器未运行')
        }
    })
}

// 在WebView中加载本地服务器内容
function loadWebView(url) {
    // 这里添加您的WebView加载逻辑
    // 例如：webview.loadUrl(url)
}
```

### AppModule vs WebModule

**AppModule 使用（主要功能）：**

```javascript
// 应用层调用 - HTTP服务器功能
const webserver = weex.requireModule('eeuiWebserver')

// HTTP服务器相关方法
webserver.startWebServer('/path/to/directory', callback)
webserver.stopWebServer(callback)
webserver.getServerStatus(callback)

// 原有演示方法也可用
webserver.simple('测试消息')
webserver.call('测试消息', callback)
const result = webserver.retMsg('测试消息')
```

**WebModule 使用（仅演示）：**

```javascript
// WebView内部调用 - 仅简单演示方法
// 注意：WebModule不包含HTTP服务器功能

// 简单日志输出
simple('测试消息')

// 回调演示  
call('测试消息', callback)

// 同步返回
const result = retMsg('测试消息')
```

## 注意事项

1. **目录权限**：确保指定的目录存在且应用有读取权限
2. **端口自动分配**：服务器会自动选择可用端口，通过回调获取实际端口号
3. **网络访问**：生成的IP地址可以在同一网络下的其他设备上访问
4. **生命周期管理**：建议在适当的时机停止服务器以释放资源
5. **文件格式**：服务器会自动根据文件扩展名设置合适的MIME类型

## 技术实现

- 基于 `GCDWebServer` 3.5.4 版本
- 支持静态文件服务
- 自动网络接口检测
- 自动端口分配（使用系统可用端口）
- 支持 iOS 8.0+

## 更新说明

✅ **已修复编译错误**：使用正确的GCDWebServer API方法
✅ **已测试兼容性**：确保与GCDWebServer 3.5.4版本兼容 