import { Platform } from 'react-native';
import StaticServer, {
  STATES,
  resolveAssetsPath,
} from '@dr.pogodin/react-native-static-server';
import { copyFileAssets, exists, unlink } from '@dr.pogodin/react-native-fs';

import type { StaticServerOptions } from './index';

/**
 * 本地静态服务真实实现（WS1）。
 *
 * 资源就绪策略（复刻旧 EEUI，对齐 @dr.pogodin/react-native-static-server 0.26 推荐用法）：
 *
 * - iOS：离线包以「folder reference」形式打进 main bundle（见 plugins/withWebAssets.js），
 *   `resolveAssetsPath('web')` 解析到 `<MainBundle>/web`，可被 lighttpd 直接 serve，无需提取。
 * - Android：APK 内 `assets/` 不是普通文件，无法被 lighttpd 直接读取；需先用
 *   `copyFileAssets('web', target)` 从 assets 提取到可写目录（document 目录），
 *   `resolveAssetsPath('web')` 在 Android 上解析到 `<DocumentDirectory>/web`。
 *
 * 端口策略：默认 22223；若被占用（启动 CRASHED / bind 失败）则回退到随机可用端口（port=0）。
 *
 * 生命周期：保存单例 server 实例与 origin，startStaticServer 幂等。
 */

const DEFAULT_PORT = 22223;
/** 离线包在原生 bundle 内的默认子目录名。 */
const DEFAULT_BUNDLE_DIR = 'web';

let _server: StaticServer | null = null;
let _origin: string | null = null;
/** 并发去重：同一时刻只跑一次启动流程。 */
let _starting: Promise<string> | null = null;

/**
 * 确保离线包资源就绪在一个 lighttpd 可读的文件系统目录，返回可被 serve 的绝对路径。
 *
 * Android：从 APK assets 提取到 document 目录（仅首次或缺失时）。
 * 其它平台（iOS / macOS）：bundle 内已是 folder reference，直接返回解析路径。
 */
async function ensureWebroot(bundleDir: string): Promise<string> {
  // resolveAssetsPath 在 Android 上以 DocumentDirectory 为基，其它平台以 MainBundle 为基。
  const target = resolveAssetsPath(bundleDir);

  if (Platform.OS !== 'android') {
    // iOS / macOS：资源随 main bundle 一起分发，直接 serve。
    return target;
  }

  // Android：copyFileAssets 会要求目标目录不存在（其内部按目录树递归复制），
  // 若已存在先清理再提取，保证 App 升级后离线包随之刷新。
  const alreadyExtracted = await exists(target);
  if (alreadyExtracted) {
    await unlink(target);
  }
  // copyFileAssets 在非 Android 平台是 noop；这里已用平台分支保护。
  await copyFileAssets(bundleDir, target);

  return target;
}

/**
 * 用给定端口启动一个 StaticServer 实例并返回 origin。
 * 若启动后即 CRASHED（通常是端口占用），抛出错误交由上层回退。
 */
async function startOnPort(fileDir: string, port: number): Promise<{ server: StaticServer; origin: string }> {
  const server = new StaticServer({
    fileDir,
    port,
    // 仅监听回环地址，避免暴露到局域网（hostname 缺省即 127.0.0.1）。
    hostname: '127.0.0.1',
    // App 进入后台时不主动停服，保证 WebView 恢复时静态资源仍可用。
    stopInBackground: false,
  });

  let crashError: Error | null = null;
  // addStateListener 返回一个「取消订阅」函数。
  const unsubscribe = server.addStateListener((newState, _details, error) => {
    if (newState === STATES.CRASHED && error) {
      crashError = error;
    }
  });

  try {
    const origin = await server.start();
    // start() 返回后再校验是否已 CRASHED（端口占用等会反映为崩溃）。
    if (crashError) {
      throw crashError;
    }
    return { server, origin };
  } catch (e) {
    // 启动失败：尽力清理实例，避免泄漏。
    try {
      await server.stop();
    } catch {
      // 忽略停服失败。
    }
    throw e;
  } finally {
    unsubscribe();
  }
}

async function startInternal(options?: StaticServerOptions): Promise<string> {
  const bundleDir = options?.bundleDir || DEFAULT_BUNDLE_DIR;
  const fileDir = await ensureWebroot(bundleDir);

  // 先尝试默认端口；占用则回退随机可用端口（port=0 由原生选择空闲端口）。
  try {
    const { server, origin } = await startOnPort(fileDir, DEFAULT_PORT);
    _server = server;
    _origin = origin;
    return origin;
  } catch {
    const { server, origin } = await startOnPort(fileDir, 0);
    _server = server;
    _origin = origin;
    return origin;
  }
}

/**
 * 启动本地静态服务，返回 origin（如 http://127.0.0.1:22223）。
 * 幂等：已启动则直接返回现有 origin；并发调用共享同一次启动流程。
 */
export async function startStaticServer(options?: StaticServerOptions): Promise<string> {
  if (_origin && _server) {
    return _origin;
  }
  if (_starting) {
    return _starting;
  }

  _starting = startInternal(options).finally(() => {
    _starting = null;
  });
  return _starting;
}

/** 停止本地静态服务（App 退出/重置时调用）。幂等。 */
export async function stopStaticServer(): Promise<void> {
  const server = _server;
  _server = null;
  _origin = null;
  if (server) {
    await server.stop();
  }
}
