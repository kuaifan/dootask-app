import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, AppState, StyleSheet, Text, View } from 'react-native';
import WebView from 'react-native-webview';
import * as Linking from 'expo-linking';
import { BRIDGE_INJECTED_JS, NativeEvents, useNativeBridge } from '../bridge';
import { setBridgeEmitter } from '../native';
import { startStaticServer } from '../server';

/**
 * 把 dootask://... deep link 转成主程序前端可消费的内部路径。
 * 主程序 App.vue 已绑定 window.__handleLink(path) → goForward({path})，约定 path 形如
 * '/share?token=...' 即可被路由跳转复用。
 */
function deepLinkToInternalPath(rawUrl: string): string | null {
  if (!rawUrl || !rawUrl.startsWith('dootask://')) return null;
  // 去掉 scheme，剩 "host/path?query"
  const rest = rawUrl.slice('dootask://'.length);
  if (!rest) return null;
  return '/' + rest.replace(/^\/+/, '');
}

/**
 * 套壳主屏：启动本地静态服务加载前端离线包，挂载桥接，全屏沉浸式显示。
 *
 * 沉浸式：WebView 全屏（延伸到状态栏/底部），安全区由前端通过
 * nativeAppGetSafeAreaInsets 自行留白（复刻旧 EEUI statusBarType=immersion）。
 */
export function WebViewShell() {
  const webviewRef = useRef<WebView>(null);
  const bridge = useNativeBridge(webviewRef);
  const [origin, setOrigin] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // 启动本地静态服务（serve 离线包）
  useEffect(() => {
    let mounted = true;
    startStaticServer()
      .then((url) => {
        if (mounted) setOrigin(url);
      })
      .catch((e: unknown) => {
        if (mounted) setError(e instanceof Error ? e.message : '本地服务启动失败');
      });
    return () => {
      mounted = false;
    };
  }, []);

  // 把桥接 emit 共享给 WS3 各 handler（让 native→web 事件能找到 WebView）
  useEffect(() => {
    setBridgeEmitter(bridge.emit);
    return () => setBridgeEmitter(null);
  }, [bridge.emit]);

  // 前后台生命周期 -> 通知前端（复刻 __onAppActive / __onAppDeactive）
  useEffect(() => {
    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') {
        bridge.emit(NativeEvents.appActive);
      } else if (state === 'background') {
        bridge.emit(NativeEvents.appDeactive);
      }
    });
    return () => sub.remove();
  }, [bridge]);

  // Deep link：dootask://share?token=... 等冷/热启动 deep link 都转给前端 __handleLink
  // 冷启动：getInitialURL；热启动/Extension 拉起：Linking 'url' 事件
  useEffect(() => {
    let cancelled = false;
    (async () => {
      const initial = await Linking.getInitialURL();
      if (!cancelled && initial) {
        const path = deepLinkToInternalPath(initial);
        if (path) bridge.emit(NativeEvents.handleLink, path);
      }
    })();
    const sub = Linking.addEventListener('url', ({ url }) => {
      const path = deepLinkToInternalPath(url);
      if (path) bridge.emit(NativeEvents.handleLink, path);
    });
    return () => {
      cancelled = true;
      sub.remove();
    };
  }, [bridge]);

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errTitle}>无法启动应用</Text>
        <Text style={styles.errMsg}>{error}</Text>
      </View>
    );
  }

  if (!origin) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" />
      </View>
    );
  }

  return (
    <WebView
      ref={webviewRef}
      source={{ uri: origin }}
      originWhitelist={['*']}
      // 桥接传输层须在前端代码运行前就绪
      injectedJavaScriptBeforeContentLoaded={BRIDGE_INJECTED_JS}
      onMessage={bridge.onMessage}
      // 追加到默认 UA，供前端识别 isMobileApp（/DooTaskApp/）
      // TODO(WS7): 接 expo-constants 后改为 DooTaskApp/<codeVersion>
      applicationNameForUserAgent="DooTaskApp"
      javaScriptEnabled
      domStorageEnabled
      // 媒体/WebRTC（会议虽走原生，仍保留以兼容 WebView 内媒体）
      allowsInlineMediaPlayback
      mediaCapturePermissionGrantType="grant"
      allowsBackForwardNavigationGestures
      // 离线包内可能引用 file 资源
      allowFileAccess
      allowUniversalAccessFromFileURLs
      style={styles.flex}
    />
  );
}

const styles = StyleSheet.create({
  flex: {
    flex: 1,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#fff',
  },
  errTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
  },
  errMsg: {
    color: '#888',
    paddingHorizontal: 32,
    textAlign: 'center',
  },
});
