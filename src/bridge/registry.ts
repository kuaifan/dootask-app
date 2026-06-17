import type { BridgeHandler } from './protocol';

/**
 * 能力 handler 注册表：method 语义名 -> handler。
 * WS3 各原生能力模块通过 registerHandlers 把自己的方法注册进来。
 */
const handlers = new Map<string, BridgeHandler>();

export function registerHandler(method: string, handler: BridgeHandler): void {
  if (handlers.has(method)) {
    // 重复注册视为覆盖，给出告警便于排查命名冲突
    console.warn(`[bridge] handler 重复注册并覆盖: ${method}`);
  }
  handlers.set(method, handler);
}

export function registerHandlers(map: Record<string, BridgeHandler>): void {
  for (const method of Object.keys(map)) {
    registerHandler(method, map[method]);
  }
}

export function getHandler(method: string): BridgeHandler | undefined {
  return handlers.get(method);
}

export function hasHandler(method: string): boolean {
  return handlers.has(method);
}

export function listMethods(): string[] {
  return Array.from(handlers.keys());
}
