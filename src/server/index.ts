/**
 * 本地静态服务：serve 打进 App 的前端离线包。
 *
 * 离线包（DooTask 前端构建产物）通过 WS1 的 config plugin（./plugins/withWebAssets）
 * 注入到原生 bundle（Android assets / iOS main bundle），运行时由本模块解压/提取到
 * 可访问目录并启动本地 HTTP 服务，返回形如 http://127.0.0.1:<port> 的 origin。
 *
 * 之所以用本地 HTTP 服务而非 file://：复刻旧 EEUI 行为——保证稳定的 http origin，
 * 使 SPA 同源 XHR、localStorage/IndexedDB 正常持久化（iOS WKWebView 在 file:// 下受限）。
 *
 * 真实实现见 ./staticServer（WS1）。此处为对外契约。
 */

export interface StaticServerOptions {
  /** 离线包在原生 bundle 内的子目录名，默认 'web' */
  bundleDir?: string;
}

/**
 * 启动本地静态服务，返回 origin（如 http://127.0.0.1:22223）。
 * 幂等：重复调用返回同一已启动实例的 origin。
 */
export async function startStaticServer(_options?: StaticServerOptions): Promise<string> {
  const { startStaticServer: impl } = await import('./staticServer');
  return impl(_options);
}

/** 停止本地静态服务（App 退出/重置时调用）。 */
export async function stopStaticServer(): Promise<void> {
  const { stopStaticServer: impl } = await import('./staticServer');
  return impl();
}
