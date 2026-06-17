# 桥接方法契约 (Bridge Contract)

新 Expo 移动端与 WebView 内 DooTask 前端之间的方法/事件契约，是 WS3（原生能力）、WS4（推送）、WS5（会议）、WS6（前端封装）的单一事实源。

## 命名规则

- **bridge method**：语义短名、小驼峰，不带前缀。例：`getSafeAreaInsets`、`scan`、`copyText`。
- **前端封装** `$A.nativeAppXxx`：method 名 = 去掉 `nativeApp` 前缀后首字母小写。
  - 例：`$A.nativeAppGetSafeAreaInsets()` → `call('getSafeAreaInsets')`
  - 例：`$A.nativeAppCopyText(text)` → `call('copyText', text)`
- **native→web 事件**：保留旧 `window.__onXxx` 全局回调名（前端已注册），原生通过 `bridge.emit(name, payload)` 触发。
- **拆解 sendMessage**：旧 `eeuiAppSendMessage({action, ...})` 的各 action 拆为独立 method（如 `updateTheme`/`windowSize`/`updateUserChatList`），不保留笼统 sendMessage。
- **纯前端**：`eeuiAppConvertLanguage` 是纯前端 languageName 映射，**不走桥接**，前端封装保留即可。

## 方法表

### 设备/系统

| method | 旧 eeuiAppXxx | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `getDeviceInfo` | `GetDeviceInfo` | - | `{platform,brand,model,systemVersion,appVersion,...}` | - | expo-device + expo-constants | |
| `getAppVersion` | `Version` | - | `string`（语义版本，如 `1.7.91`） | - | expo-constants | |
| `getAppLocalVersion` | `LocalVersion` | - | `number`（codeVersion） | - | expo-constants `extra.codeVersion` | |
| `getSafeAreaInsets` | `GetSafeAreaInsets` | - | `{top,bottom,left,right}` | - | safe-area-context 通过 emit 推送或 handler 同步返回 | 旧返回 `{status:'success',top,bottom,data}`，新返回扁平结构 |
| `getThemeName` | `GetThemeName` | - | `'light' \| 'dark'` | - | RN Appearance | |
| `isWindowed` | `IsWindowed` | - | `boolean` | - | 平板/分屏（移动端通常 false） | |

### UI 容器控制

| method | 旧 eeuiAppXxx | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `alert` | `Alert` | `{title?,message?,buttons?}` | `{index:number}` | - | RN Alert | |
| `toast` | `Toast` | `{message:string,duration?:'short'\|'long'}` | - | RN ToastAndroid + iOS 自实现 | |
| `keyboardHide` | `KeyboardHide` | - | - | - | RN Keyboard.dismiss | 高频(7处) |
| `keyboardStatus` | `KeyboardStatus` | - | `{visible:boolean,height:number}` | `__onKeyboardStatus({visible,height})` | RN Keyboard 监听 | |
| `setScrollDisabled` | `SetScrollDisabled` | `boolean` | - | - | 转给 WebView 注入 `document.body.style.overflow` | iOS 限制，尽力而为 |
| `setHapticBackEnabled` | `SetHapticBackEnabled` | `boolean` | - | - | expo-haptics 包装 | Android 主，iOS noop |
| `goDesktop` | `GoDesktop` | - | - | - | Android `moveTaskToBack`，iOS noop | |
| `keepScreenOn` | `KeepScreenOn` | - | - | - | expo-keep-awake `activate` | |
| `keepScreenOff` | `KeepScreenOff` | - | - | - | expo-keep-awake `deactivate` | |
| `setPageBackPressed` | `SetPageBackPressed` | `{enabled:boolean}` | - | 触发回调（通过 emit 推送 `__onBackPressed`） | RN BackHandler | Android 专属 |
| `vibrate` | （sendMessage `setVibrate`） | `{time?:number}` | - | - | expo-haptics | |
| `windowSize` | （sendMessage `windowSize`） | `{width:number,height?:number}` | - | - | 接收前端反馈，写入 storage | |

### 存储

| method | 旧 eeuiAppXxx | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `setVariate` | `SetVariate` | `{key:string,value:unknown}` | - | - | 内存 Map（重启失效，复刻旧语义） | |
| `getVariate` | `GetVariate` | `{key:string,defaultVal?:unknown}` | `unknown` | - | 同上 | |
| `setCache` | `SetCachesString` | `{key:string,value:string,expired?:number}` | - | - | AsyncStorage + 过期戳 | `expired=0` 永久 |
| `getCache` | `GetCachesString` | `{key:string,defaultVal?:string}` | `string` | - | AsyncStorage | |

### 媒体

| method | 旧 eeuiAppXxx | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `scan` | `Scan` | - | `string`（扫到的文本，取消则 reject） | - | expo-camera barcode | |
| `getLatestPhoto` | `GetLatestPhoto` | `{expiration?:number}` | `{path,base64,width,height,created}` | - | expo-media-library | |
| `uploadPhoto` | `UploadPhoto` | `{url,headers,data,path,fieldName,onReady?}` | `unknown`（服务端 data 字段） | - | RN fetch + FormData | onReady 走 emit `__onUploadReady` |
| `cancelUploadPhoto` | `CancelUploadPhoto` | `{id:string}` | - | - | 管理 AbortController 表 | |
| `picturePreview` | （sendMessage `picturePreview`） | `{position,paths:string[]}` | - | - | RN 内部图片预览 overlay 或 expo-image + Modal | |
| `videoPreview` | （sendMessage `videoPreview`） | `{path:string}` | - | - | expo-video Modal | |
| `copyText` | `CopyText` | `string` | - | - | expo-clipboard | |

### 交互/外链

| method | 旧 eeuiAppXxx | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `openWeb` | `OpenWeb` | `string`（URL） | - | - | expo-web-browser `openBrowserAsync` | |
| `openPage` | `OpenPage` | `{pageType?,url,params?,title?}` | - | - | 新建 WebView Modal/Stack | 主要用于地图等本地子页 |
| `callTel` | （sendMessage `callTel`） | `{tel:string}` | - | - | expo-linking `tel:` | |
| `share` | `Share` | `{title?,text?,url?}` | - | - | expo-sharing 或 RN Share | |
| `setUrl` | `SetUrl` | `string` | - | - | webview.injectJavaScript window.location | |
| `checkUpdate` | `CheckUpdate` | - | - | - | 调 doopush/自有更新接口（占位） | 二期可对接 expo-updates |

### 通知/角标（与 WS4 推送共用）

| method | 旧 eeuiAppXxx / action | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `getNotificationPermission` | `getNotificationPermission` | - | `boolean` | `__onNotificationPermissionStatus(bool)` | expo-notifications | |
| `requestNotificationPermission` | （新增） | - | `boolean` | - | expo-notifications | 旧靠系统弹窗，新明确暴露 |
| `clearAllNotify` | `clearAllNotify` | - | - | - | expo-notifications `dismissAllNotificationsAsync` | |
| `gotoNotificationSetting` | `gotoSetting` | - | - | - | expo-linking `openSettings` | |
| `setBadge` | `setBadgeNum`/`setBdageNotify` | `{count:number}` | - | - | doopush `setBadge` 或 expo-notifications `setBadgeCountAsync` | WS4 |
| `registerPush` | `initApp` + `setUmengAlias` | `{userid,token,language,userAgent}` | `{deviceId,vendor,token}` | - | doopush-react-native-sdk | WS4 |
| `unregisterPush` | `delUmengAlias` | - | - | - | doopush | WS4 |

### 会议（WS5）

| method | 旧 action | 参数 | 返回 | 触发事件 | 实现 | 备注 |
|---|---|---|---|---|---|---|
| `startMeeting` | `startMeeting` | `{name,token,channel,uuid,appid,avatar,username,video,audio,meetingid,sharelink,alert}` | - | `__onMeetingEvent({act,uuid,...})` | react-native-agora | |
| `updateMeetingInfo` | `updateMeetingInfo` | `{infos:[{uuid,nickname,avatar}]}` | - | - | 同上 | |

### 跨 App 分享接收（WS10/二期）

| method | 参数 | 返回 | 备注 |
|---|---|---|---|
| `getSharedPayload` | `{token:string}` | `{token,createdAt,items:[{name,mime,size,uri}],text?,url?} \| null` | 读 documentDirectory/share/&lt;token&gt;/payload.json |
| `clearSharedPayload` | `{token:string}` | - | Web 处理完后清理共享文件目录 |

旧 `userChatList`/`userUploadUrl` sendMessage action 在二期被废弃——新方案不再让 Extension 直连后端，所有 API 在主 App WebView 完成。

## native→web 事件清单（`window.__onXxx`）

| 事件名 | 何时触发 | payload | 实现处 |
|---|---|---|---|
| `__initializeApp` | App 启动后端注入用户登录态/会话路由 | `loadHash:string?` | WS6 由原生主动调，本期可由 webview shell 配合启动 |
| `__onAppActive` | App 从后台回到前台 | - | WebViewShell（AppState='active'） |
| `__onAppDeactive` | App 进入后台 | - | WebViewShell（AppState='background'） |
| `__onPageResume` | 页面从暂停恢复 | `resumeNum:number` | 与 active 同源，可合并 |
| `__onPagePause` | 页面暂停 | - | 同上 |
| `__onNotificationPermissionStatus` | 通知权限状态变更 | `enabled:boolean` | WS3 通知组 |
| `__onKeyboardStatus` | 键盘弹出/收起 | `{visible:boolean,height:number}` | WS3 UI 组 |
| `__handleLink` | 收到 deep link（scheme://...） | `url:string` | WS6/WS7 接 expo-linking |
| `__onMeetingEvent` | 会议事件 | `{act,uuid,...}` | WS5 |
| `__onCreateTarget` | WebView 拦截到 target=_blank | `url:string` | WS1 已可在 onShouldStartLoadWithRequest 触发 |
| `__onBackPressed` | Android 返回键被拦截（setPageBackPressed enabled=true） | - | WS3 UI 组 |

## 实施分批（WS3）

按代码相关度分组实现，各组互不依赖：

1. **device** —— `getDeviceInfo`/`getAppVersion`/`getAppLocalVersion`/`getThemeName`/`isWindowed`/`getSafeAreaInsets`
2. **ui** —— `alert`/`toast`/`keyboardHide`/`keyboardStatus`/`vibrate`/`keepScreenOn`/`keepScreenOff`/`setPageBackPressed`/`goDesktop`/`windowSize`/`setHapticBackEnabled`/`setScrollDisabled`
3. **storage** —— `setVariate`/`getVariate`/`setCache`/`getCache`
4. **media** —— `scan`/`getLatestPhoto`/`uploadPhoto`/`cancelUploadPhoto`/`picturePreview`/`videoPreview`/`copyText`
5. **link** —— `openWeb`/`openPage`/`callTel`/`share`/`setUrl`/`checkUpdate`
6. **notify** —— `getNotificationPermission`/`requestNotificationPermission`/`clearAllNotify`/`gotoNotificationSetting`/`setBadge`（与 WS4 协作）

WS4 推送（`registerPush`/`unregisterPush` + 点击跳转）和 WS5 会议 (`startMeeting`/`updateMeetingInfo`) 独立工作流。
