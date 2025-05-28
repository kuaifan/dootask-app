# eeuiWebserver

一个用于在iOS应用中启动本地HTTP服务器的eeui插件，可以将本地目录作为静态文件服务器。

## 安装

```shell script
eeui plugin install eeui/webserver
```

## 卸载

```shell script
eeui plugin uninstall eeui/webserver
```

## 引入模块

```js
const webserver = app.requireModule("eeui/webserver");
```

## API 方法

### 1. startWebServer

启动本地HTTP服务器

**参数方式1（字符串）：**
```javascript
webserver.startWebServer("file:///path/to/directory", (result) => {
    console.log(result);
});
```

**参数方式2（对象）：**
```javascript
webserver.startWebServer({
    path: "file:///path/to/directory",  // 要服务的目录路径
    port: 8080,                         // 端口号，默认0（自动分配）
    index: "index.html",                // 默认首页文件
    keepalive: "/__keepalive__"         // 心跳接口路径
}, (result) => {
    console.log(result);
});
```

**路径参数说明：**

`path` 参数支持以下格式：
- 绝对路径：`"file:///private/var/containers/Bundle/..."`
- 相对路径转换：通过 `eeui.rewriteUrl()` 方法转换

```javascript
const eeui = app.requireModule('eeui');
const webserver = app.requireModule("eeui/webserver");

// 将相对路径转换为file://格式
const fullPath = eeui.rewriteUrl('../public');
console.log(fullPath); // 输出：file:///private/var/containers/Bundle/.../public

webserver.startWebServer({
    path: fullPath,
    port: 8080
}, (result) => {
    console.log(result);
});
```

**响应格式：**
```javascript
// 成功启动
{
    status: "success",
    message: "服务器启动成功", 
    url: "http://192.168.1.100:8080/",
    port: 8080
}

// 服务器已存在
{
    status: "exists",
    message: "服务器已存在",
    url: "http://192.168.1.100:8080/", 
    port: 8080
}

// 错误情况
{
    status: "error",
    message: "具体错误信息"
}
```

### 2. stopWebServer

停止HTTP服务器

```javascript
webserver.stopWebServer((result) => {
    console.log(result);
});
```

**响应格式：**
```javascript
// 成功停止
{
    status: "success",
    message: "服务器已停止"
}

// 服务器未运行
{
    status: "error", 
    message: "服务器未运行"
}
```

### 3. getServerStatus

获取服务器运行状态

```javascript
webserver.getServerStatus((result) => {
    console.log(result);
});
```

**响应格式：**
```javascript
// 服务器运行中
{
    status: "success",
    message: "服务器正在运行",
    url: "http://192.168.1.100:8080/",
    port: 8080
}

// 服务器未运行
{
    status: "error",
    message: "服务器未运行"
}
```

### 4. getLocalIPAddress

获取设备本地IP地址

```javascript
webserver.getLocalIPAddress((result) => {
    console.log(result);
});
```

**响应格式：**
```javascript
// 成功获取
{
    status: "success",
    message: "获取本地IP地址成功",
    ip: "192.168.1.100"
}

// 获取失败
{
    status: "error",
    message: "获取本地IP地址失败"
}
```

## 使用示例

```javascript
const eeui = app.requireModule('eeui');
const webserver = app.requireModule("eeui/webserver");

// 使用相对路径启动服务器（推荐方式）
const publicPath = eeui.rewriteUrl('../public');
webserver.startWebServer({
    path: publicPath, 
    port: 8080
}, (result) => {
    if (result.status === "success" || result.status === "exists") {
        console.log("服务器运行在:", result.url);
        
        // 心跳检查
        fetch(result.url + "__keepalive__")
            .then(response => response.json())
            .then(data => console.log("心跳检查:", data));
    } else {
        console.error("启动失败:", result.message);
    }
});

// 或者直接使用绝对路径
webserver.startWebServer({
    path: "file:///bundlejs/eeui/public", 
    port: 8080
}, (result) => {
    console.log("启动结果:", result);
});

// 获取本地IP
webserver.getLocalIPAddress((result) => {
    if (result.status === "success") {
        console.log("本地IP:", result.ip);
    }
});

// 停止服务器
webserver.stopWebServer((result) => {
    console.log("停止结果:", result.message);
});
```

## 注意事项

1. 服务器使用静态变量保存，应用重启后仍会保持运行状态
2. 路径支持自动去除 `file://` 前缀
3. **推荐使用 `eeui.rewriteUrl()` 将相对路径转换为完整路径**
4. 所有方法都使用统一的响应格式，通过 `status` 字段判断结果
5. 心跳接口默认路径为 `/__keepalive__`，返回服务器状态和时间戳

## 支持的文件类型

插件支持丰富的MIME类型：

### 📱 **技术实现**
- **iOS**: 使用 `GCDWebServer` 内置MIME类型处理  
- **Android**: 使用 `MimeTypeMap.getSingleton()` 系统级映射

### ✅ **覆盖范围**
系统内置MIME类型映射支持**数百种**文件格式，包括但不限于：

### 📄 **常用Web文件**
- **HTML**: `.html`, `.htm`
- **JavaScript**: `.js`, `.mjs`  
- **CSS**: `.css`
- **JSON**: `.json`
- **XML**: `.xml`
- **文本**: `.txt`

### 🖼️ **图片格式**
- **常用**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp`
- **图标**: `.ico`, `.bmp`
- **专业**: `.tiff`, `.raw` 等

### 🎵 **音频格式**
- **常用**: `.mp3`, `.wav`, `.ogg`, `.m4a`
- **专业**: `.flac`, `.aac`, `.wma` 等

### 🎬 **视频格式**
- **常用**: `.mp4`, `.webm`, `.mov`, `.avi`
- **高清**: `.mkv`, `.flv`, `.wmv` 等

### 🔤 **字体文件**
- **Web字体**: `.ttf`, `.otf`, `.woff`, `.woff2`, `.eot`

### 📋 **文档类型**
- **PDF**: `.pdf`
- **Office**: `.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`
- **开放文档**: `.odt`, `.ods`, `.odp` 等

### 📦 **压缩文件**
- **常用**: `.zip`, `.tar`, `.gz`, `.rar`, `.7z`

### 🔧 **开发文件**
- **配置**: `.yml`, `.yaml`, `.toml`, `.ini`
- **数据**: `.csv`, `.tsv`
- **代码**: `.py`, `.java`, `.cpp`, `.go` 等

### 🎯 **优势特点**

#### ✅ **系统级支持**
- 自动跟随系统更新获得新的MIME类型支持
- 保证了最高的准确性和兼容性

#### ✅ **性能优良**  
- 系统优化的查找算法
- 无需维护庞大的映射表

#### ✅ **全面覆盖**
- 支持数百种文件类型
- 包括最新的文件格式

> **注意**: 如果系统无法识别某种文件类型，会自动返回 `application/octet-stream` 作为默认类型。 