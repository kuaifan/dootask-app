import { useCallback, useMemo } from 'react';
import type { RefObject } from 'react';
import type WebView from 'react-native-webview';
import type { WebViewMessageEvent } from 'react-native-webview';
import { BRIDGE_NS, type BridgeCallMessage, type BridgeContext } from './protocol';
import { getHandler } from './registry';

/** 把任意值编码为可安全嵌入注入 JS 的字面量（转义 JS 字符串中非法的行分隔符 U+2028/U+2029） */
function toJsLiteral(value: unknown): string {
  const LS = String.fromCharCode(0x2028);
  const PS = String.fromCharCode(0x2029);
  return JSON.stringify(value === undefined ? null : value)
    .split(LS).join('\\u2028')
    .split(PS).join('\\u2029');
}

export interface NativeBridge {
  /** 绑定到 WebView 的 onMessage */
  onMessage: (event: WebViewMessageEvent) => void;
  /** native 到 web 主动触发前端全局回调 window[eventName](payload) */
  emit: (eventName: string, payload?: unknown) => void;
}

/**
 * 桥接 hook：解析 WebView 上来的调用消息，分发到 registry 注册的 handler，
 * 并通过 injectJavaScript 把结果/错误兑现回前端 Promise。
 */
export function useNativeBridge(webviewRef: RefObject<WebView | null>): NativeBridge {
  const inject = useCallback(
    (js: string) => {
      webviewRef.current?.injectJavaScript(js);
    },
    [webviewRef],
  );

  const emit = useCallback(
    (eventName: string, payload?: unknown) => {
      inject(
        `window.__nativeBridge && window.__nativeBridge._emit(${toJsLiteral(eventName)}, ${toJsLiteral(payload)});true;`,
      );
    },
    [inject],
  );

  const ctx = useMemo<BridgeContext>(() => ({ emit }), [emit]);

  const onMessage = useCallback(
    async (event: WebViewMessageEvent) => {
      const raw = event.nativeEvent.data;
      let msg: BridgeCallMessage | undefined;
      try {
        msg = JSON.parse(raw) as BridgeCallMessage;
      } catch {
        return; // 非桥接消息（前端可能有其它 postMessage），忽略
      }
      if (!msg || (msg as { ns?: string }).ns !== BRIDGE_NS || msg.type !== 'call') {
        return;
      }
      const { id, method, args } = msg;
      const handler = getHandler(method);
      if (!handler) {
        inject(
          `window.__nativeBridge._reject(${id}, ${toJsLiteral('method not found: ' + method)});true;`,
        );
        return;
      }
      try {
        const result = await handler(args, ctx);
        inject(`window.__nativeBridge._resolve(${id}, ${toJsLiteral(result)});true;`);
      } catch (e) {
        const message = e instanceof Error ? e.message : 'native error';
        inject(`window.__nativeBridge._reject(${id}, ${toJsLiteral(message)});true;`);
      }
    },
    [ctx, inject],
  );

  return { onMessage, emit };
}
