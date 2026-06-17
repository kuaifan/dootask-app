/**
 * WS3 media 组：扫码 / 取最新照片 / 上传 / 复制文本。
 *
 * 注：picturePreview / videoPreview 需要全屏 overlay UI 组件，本期占位为打开外部 App 兜底，
 * 完整 UI 由后续 WebView 内置预览或单独迭代实现。
 */
import * as Clipboard from 'expo-clipboard';
import * as MediaLibrary from 'expo-media-library';
import * as WebBrowser from 'expo-web-browser';
import { registerHandlers } from '../bridge';

interface UploadArgs {
  url: string;
  headers?: Record<string, string>;
  data?: Record<string, string>;
  path: string;
  fieldName?: string;
}

const _uploadAborters = new Map<string, AbortController>();

async function getLatestPhoto(): Promise<{
  path: string;
  width: number;
  height: number;
  created: number;
}> {
  const perm = await MediaLibrary.requestPermissionsAsync(false);
  if (!perm.granted) throw new Error('permission denied');
  const page = await MediaLibrary.getAssetsAsync({
    mediaType: 'photo',
    sortBy: [['creationTime', false]],
    first: 1,
  });
  const asset = page.assets[0];
  if (!asset) throw new Error('no photo');
  const info = await MediaLibrary.getAssetInfoAsync(asset);
  return {
    path: info.localUri ?? info.uri,
    width: asset.width,
    height: asset.height,
    created: Math.floor(asset.creationTime / 1000),
  };
}

async function uploadPhoto(args: UploadArgs): Promise<unknown> {
  const id = String(Date.now()) + Math.random().toString(36).slice(2, 6);
  const aborter = new AbortController();
  _uploadAborters.set(id, aborter);

  try {
    const form = new FormData();
    if (args.data) {
      for (const k of Object.keys(args.data)) form.append(k, args.data[k]);
    }
    // RN FormData 文件项约定：{ uri, name, type }；标准 lib.dom 的 FormData 类型不识别此结构，
    // RN 运行时支持。用 unknown 桥过类型检查。
    const fileName = args.path.split('/').pop() || 'photo.jpg';
    const filePart = { uri: args.path, name: fileName, type: 'image/jpeg' };
    form.append(args.fieldName || 'file', filePart as unknown as Blob);
    const res = await fetch(args.url, {
      method: 'POST',
      headers: args.headers,
      body: form,
      signal: aborter.signal,
    });
    const json = (await res.json().catch(() => ({}))) as { ret?: number; msg?: string; data?: unknown };
    if (json.ret !== 1) throw new Error(json.msg || 'upload failed');
    return json.data;
  } finally {
    _uploadAborters.delete(id);
  }
}

export function registerMediaHandlers(): void {
  registerHandlers({
    /**
     * 扫码：本期占位实现——抛 not implemented，由 WS3 增强阶段接 expo-camera 全屏扫码 UI。
     * 不能用 silent fallback 避免前端误以为扫到空字符串。
     */
    scan: () => {
      throw new Error('scan not implemented yet');
    },

    getLatestPhoto: () => getLatestPhoto(),

    uploadPhoto: (args: UploadArgs) => uploadPhoto(args),

    cancelUploadPhoto: (args: { id: string }) => {
      const a = _uploadAborters.get(args?.id);
      if (a) {
        a.abort();
        _uploadAborters.delete(args.id);
      }
    },

    /** 临时实现：用系统浏览器打开第一张图片；完整预览待后续迭代 */
    picturePreview: (args: { position?: number; paths: string[] }) => {
      const idx = Math.max(0, Math.min(args.paths.length - 1, args.position ?? 0));
      const url = args.paths[idx];
      if (url) void WebBrowser.openBrowserAsync(url);
    },

    /** 临时实现：用系统浏览器打开视频；完整预览待后续迭代 */
    videoPreview: (args: { path: string }) => {
      if (args?.path) void WebBrowser.openBrowserAsync(args.path);
    },

    copyText: (text: string) => Clipboard.setStringAsync(typeof text === 'string' ? text : ''),
  });
}
