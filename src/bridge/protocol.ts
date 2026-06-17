/**
 * 桥接协议：Web(WebView 内的 DooTask 前端) 与 Native(本 RN 工程) 双向通信
 *
 * Web 到 Native：window.ReactNativeWebView.postMessage(JSON.stringify(BridgeCallMessage))
 * Native 到 Web：webview.injectJavaScript(...)
 *   - 兑现调用：window.__nativeBridge._resolve(id, payload) / _reject(id, message)
 *   - 推送事件：window.__nativeBridge._emit(eventName, payload) 调用 window[eventName](payload)
 *
 * 设计要点：前端业务只通过 $A.nativeAppXXX(args)（WS6）转 window.__nativeBridge.call(method,args)
 * 发起调用；method 用语义名（如 'getSafeAreaInsets'），不带 nativeApp 前缀。
 */

export const BRIDGE_NS = 'nativeApp' as const;

/** Web 到 Native 的一次方法调用 */
export interface BridgeCallMessage {
  ns: typeof BRIDGE_NS;
  type: 'call';
  /** 调用序号，用于配对回调 */
  id: number;
  /** 语义方法名，对应 registry 中注册的 handler */
  method: string;
  /** 调用参数（任意可 JSON 序列化的值） */
  args?: unknown;
}

export type BridgeInbound = BridgeCallMessage;

/** 触发前端全局回调（window.__onXxx）的能力，注入到 handler 上下文 */
export interface BridgeContext {
  /** 调用 WebView 内 window[eventName](payload)，用于 native 到 web 主动通知 */
  emit: (eventName: string, payload?: unknown) => void;
}

/** 能力 handler：接收 args 与上下文，返回可序列化结果或抛错（错误会 reject 给前端） */
export type BridgeHandler = (args: any, ctx: BridgeContext) => Promise<unknown> | unknown;

/** native 到 web 的标准全局回调名（复刻旧 EEUI 契约，前端在这些名字上注册函数） */
export const NativeEvents = {
  initializeApp: '__initializeApp',
  appActive: '__onAppActive',
  appDeactive: '__onAppDeactive',
  pageResume: '__onPageResume',
  pagePause: '__onPagePause',
  notificationPermissionStatus: '__onNotificationPermissionStatus',
  keyboardStatus: '__onKeyboardStatus',
  handleLink: '__handleLink',
  meetingEvent: '__onMeetingEvent',
  createTarget: '__onCreateTarget',
} as const;
