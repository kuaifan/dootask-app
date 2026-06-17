/**
 * WS3 link 组：外链/拨号/分享/拓展 WebView 等。
 */
import { Share } from 'react-native';
import * as Linking from 'expo-linking';
import * as WebBrowser from 'expo-web-browser';
import { registerHandlers } from '../bridge';

interface ShareArgs {
  title?: string;
  text?: string;
  url?: string;
}

export function registerLinkHandlers(): void {
  registerHandlers({
    openWeb: (url: string) => WebBrowser.openBrowserAsync(url),

    /**
     * openPage：旧调用主要用于地图等本地子 WebView 页。
     * 本期占位为外部浏览器打开；如需 in-app 子 WebView 模态，留待迭代。
     */
    openPage: (args: { url?: string }) => {
      if (args?.url) void WebBrowser.openBrowserAsync(args.url);
    },

    callTel: (args: { tel: string }) => {
      if (args?.tel) void Linking.openURL(`tel:${args.tel}`);
    },

    share: async (args: ShareArgs) => {
      await Share.share({
        title: args.title,
        message: [args.text, args.url].filter(Boolean).join(' '),
        url: args.url,
      });
    },

    /** setUrl：前端要求主 WebView 跳转到某 URL；由 WebView 内部 location 实现更简单 */
    setUrl: (_url: string) => {
      // 桥接侧无法直接拿到 WebView ref；前端可改为 window.location.href = url 自行实现。
      // 保留此 method 仅为兼容旧调用，避免抛错。
    },

    checkUpdate: () => {
      // 占位：后续接入应用商店打开链接或 OTA 检查。
    },
  });
}
