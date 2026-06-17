/**
 * WS10 跨 App 分享接收：从原生侧（iOS Share Extension / Android Intent）写到本地的
 * 共享 payload 读出来，交给 Web 端处理。
 *
 * 落点约定（与 WS8/WS9 plugin 协议）：
 *   <Paths.document>/share/<token>/payload.json
 *   <Paths.document>/share/<token>/files/<n>.<ext>
 *
 * 之所以统一用主 App documentDirectory：
 * - Android：MainActivity 本就跑在主 App 进程，cacheDir/documentDirectory 都同进程可读，
 *   plugin 直接写到 documentDirectory 即可。
 * - iOS：Share Extension 沙箱与主 App 不同，只能用 App Group container 跨界写。
 *   主 App 启动时 plugin 注入的 AppDelegate 代码会把 App Group 下的 share/<token>/
 *   迁移到 documentDirectory（见 plugins/withShareExtension）。
 *   handler 只读 documentDirectory 这一处，避免跨平台分支。
 *
 * payload.json 形状（由原生侧写入）：
 *   {
 *     "token": "<uuid>",
 *     "createdAt": 1718600000,
 *     "items": [
 *       { "name": "photo.jpg", "mime": "image/jpeg", "size": 12345, "relPath": "files/0.jpg" }
 *     ],
 *     "text"?: "shared text",
 *     "url"?: "https://..."
 *   }
 */
import { Directory, File, Paths } from 'expo-file-system';
import { registerHandlers } from '../bridge';

interface SharedPayloadItem {
  name: string;
  mime: string;
  size: number;
  /** payload.json 同目录下的相对路径；handler 会拼成完整 file:// uri 返回前端 */
  relPath: string;
}

interface SharedPayloadFile {
  token: string;
  createdAt: number;
  items: SharedPayloadItem[];
  text?: string;
  url?: string;
}

interface SharedPayloadResult {
  token: string;
  createdAt: number;
  text?: string;
  url?: string;
  items: Array<{
    name: string;
    mime: string;
    size: number;
    /** WebView 可直接用 fetch(uri) 读到文件二进制（file:// 协议） */
    uri: string;
  }>;
}

function getTokenDir(token: string): Directory {
  const safe = token.replace(/[^a-zA-Z0-9_-]/g, '');
  if (!safe) throw new Error('invalid token');
  return new Directory(Paths.document, 'share', safe);
}

async function readPayload(token: string): Promise<SharedPayloadResult | null> {
  const dir = getTokenDir(token);
  const payloadFile = new File(dir, 'payload.json');
  if (!payloadFile.exists) return null;
  const raw = await payloadFile.text();
  const data = JSON.parse(raw) as SharedPayloadFile;
  const dirUri = dir.uri.endsWith('/') ? dir.uri : dir.uri + '/';
  return {
    token: data.token,
    createdAt: data.createdAt,
    text: data.text,
    url: data.url,
    items: (data.items ?? []).map((it) => ({
      name: it.name,
      mime: it.mime,
      size: it.size,
      uri: dirUri + it.relPath,
    })),
  };
}

function clearPayload(token: string): void {
  const dir = getTokenDir(token);
  if (dir.exists) dir.delete();
}

export function registerShareHandlers(): void {
  registerHandlers({
    /**
     * 取一份 share payload。token 缺失/无效返回 null（前端据此跳回主页）。
     */
    getSharedPayload: (args: { token?: string }) => {
      const token = args?.token;
      if (!token) return null;
      return readPayload(token);
    },

    /** Web 处理完后清理共享文件 */
    clearSharedPayload: (args: { token?: string }) => {
      const token = args?.token;
      if (!token) return;
      clearPayload(token);
    },
  });
}
