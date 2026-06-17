/**
 * WS3 storage 组：变量（内存，会话级）+ 缓存（AsyncStorage 持久化，可带过期）。
 *
 * 复刻旧 EEUI 语义：
 * - setVariate/getVariate：内存级，App 重启失效（旧 weex 框架的运行时变量表）。
 * - setCache/getCache(expired=0 永久)：持久化键值，配套过期戳。
 */
import AsyncStorage from '@react-native-async-storage/async-storage';
import { registerHandlers } from '../bridge';

const variates = new Map<string, unknown>();

const CACHE_PREFIX = 'nativeCache:';
const META_PREFIX = 'nativeCacheMeta:';

interface CacheMeta {
  /** 过期时戳（秒级 unix）；0 表示永久 */
  exp: number;
}

async function readCache(key: string, defaultVal = ''): Promise<string> {
  const metaRaw = await AsyncStorage.getItem(META_PREFIX + key);
  if (metaRaw) {
    try {
      const meta = JSON.parse(metaRaw) as CacheMeta;
      if (meta.exp > 0 && meta.exp < Math.floor(Date.now() / 1000)) {
        // 已过期：清理后返回默认值
        await AsyncStorage.multiRemove([CACHE_PREFIX + key, META_PREFIX + key]);
        return defaultVal;
      }
    } catch {
      // meta 损坏，按未命中处理
    }
  }
  const v = await AsyncStorage.getItem(CACHE_PREFIX + key);
  return v ?? defaultVal;
}

async function writeCache(key: string, value: string, expired = 0): Promise<void> {
  const exp = expired > 0 ? Math.floor(Date.now() / 1000) + expired : 0;
  await AsyncStorage.multiSet([
    [CACHE_PREFIX + key, value],
    [META_PREFIX + key, JSON.stringify({ exp } satisfies CacheMeta)],
  ]);
}

export function registerStorageHandlers(): void {
  registerHandlers({
    setVariate: (args: { key: string; value: unknown }) => {
      if (args?.key) variates.set(args.key, args.value);
    },

    getVariate: (args: { key: string; defaultVal?: unknown }) => {
      if (!args?.key) return args?.defaultVal ?? null;
      return variates.has(args.key) ? variates.get(args.key) : (args.defaultVal ?? null);
    },

    setCache: (args: { key: string; value: string; expired?: number }) =>
      writeCache(args.key, args.value, args.expired ?? 0),

    getCache: (args: { key: string; defaultVal?: string }) =>
      readCache(args.key, args.defaultVal ?? ''),
  });
}
