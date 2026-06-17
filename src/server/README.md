# 本地静态服务（src/server）

serve 打进 App 原生 bundle 的 DooTask 前端离线包。复刻旧 EEUI 行为：运行时启动本地 HTTP
服务（lighttpd，默认端口 22223）serve 离线包，WebView 加载 `http://127.0.0.1:<port>/`。

用本地 HTTP 而非 `file://`：保证稳定的 http origin，使 SPA 同源 XHR、localStorage/IndexedDB
正常持久化（iOS WKWebView 在 `file://` 下受限）。

## 对外契约（src/server/index.ts，签名勿改）

- `startStaticServer(options?: { bundleDir?: string }): Promise<string>` —— 启动并返回 origin，幂等。
- `stopStaticServer(): Promise<void>` —— 停止。

实现见 `staticServer.ts`。

## 工作流程（staticServer.ts）

1. 资源就绪 `ensureWebroot(bundleDir)`：
   - iOS / macOS：离线包以 folder reference 形式在 main bundle 内，`resolveAssetsPath('web')`
     解析到 `<MainBundle>/web`，直接 serve，无需提取。
   - Android：APK 内 `assets/` 不是普通文件，无法被 lighttpd 直接读取；用
     `copyFileAssets('web', target)` 从 assets 提取到 document 目录（`resolveAssetsPath('web')`
     在 Android 上的基目录），App 升级时先 `unlink` 再提取以刷新离线包。
2. 端口策略：默认 22223；启动后若 CRASHED（通常端口占用）回退随机可用端口（`port: 0`）。
3. 生命周期：单例保存 server 实例与 origin，`startStaticServer` 幂等且并发去重。

依赖：`@dr.pogodin/react-native-static-server`（含其传递依赖 `@dr.pogodin/react-native-fs`，
提供 `copyFileAssets` / `resolveAssetsPath` / `exists` / `unlink`）。

## 离线包来源与注入

- 源目录：`resources/mobile/assets/web/`（前端构建产物，含 `index.html` + `js/` 等）。
  该目录在 `.gitignore` 中被忽略，真正的产物由 `electron/build.js` 同步进来。
- 注入：`plugins/withWebAssets.js`（Expo config plugin）在 `expo prebuild` 时把 `assets/web/`
  注入原生工程：
  - Android → `android/app/src/main/assets/web/`
  - iOS → 复制到 `ios/web/` 并以 folder reference 加入 main bundle target。

## 占位文件

`assets/web/index.html` 是占位文件（"DooTask offline package placeholder"，回显
`window.systemInfo`），仅供本地真机验证服务可用。由于 `assets/web/` 被 git 忽略，该占位文件
不入库；前端正式产物就绪后会被 `electron/build.js` 整体覆盖，无需手动清理（其内容会被替换）。
