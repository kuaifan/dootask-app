import { ExpoConfig, ConfigContext } from 'expo/config';

// 版本号与主仓库根 package.json 保持一致（version / codeVerson）
// 复刻原 EEUI 的版本同步语义：versionName=version，versionCode/buildNumber=codeVerson
// eslint-disable-next-line @typescript-eslint/no-var-requires
const root = require('../../package.json');
const VERSION: string = root.version || '1.0.0';
const CODE_VERSION: number = Number(root.codeVerson) || 1;

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'DooTask',
  slug: 'dootask',
  version: VERSION,
  orientation: 'portrait',
  icon: './assets/icon.png',
  scheme: 'dootask',
  userInterfaceStyle: 'automatic',
  ios: {
    supportsTablet: true,
    bundleIdentifier: 'com.dootask.task',
    buildNumber: String(CODE_VERSION),
    infoPlist: {
      NSCameraUsageDescription: '用于音视频会议、扫码与拍照上传',
      NSMicrophoneUsageDescription: '用于音视频会议与语音消息',
      NSPhotoLibraryUsageDescription: '用于选择和上传图片/视频',
      NSPhotoLibraryAddUsageDescription: '用于保存图片到相册',
      ITSAppUsesNonExemptEncryption: false,
      UIBackgroundModes: ['audio', 'remote-notification'],
    },
  },
  android: {
    package: 'com.dootask.task',
    versionCode: CODE_VERSION,
    adaptiveIcon: {
      foregroundImage: './assets/android-icon-foreground.png',
      backgroundImage: './assets/android-icon-background.png',
      monochromeImage: './assets/android-icon-monochrome.png',
      backgroundColor: '#FFFFFF',
    },
    permissions: [
      'CAMERA',
      'RECORD_AUDIO',
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'VIBRATE',
      'POST_NOTIFICATIONS',
      'INTERNET',
      'ACCESS_NETWORK_STATE',
    ],
  },
  // 需要原生配置的库（doopush / agora / static-server）的 config plugin 在各自 WS 接入
  plugins: [
    'expo-asset',
    'expo-web-browser',
    // 离线包（assets/web）注入原生 bundle，供本地静态服务 serve
    './plugins/withWebAssets',
    // Android 跨 App 分享接收：intent-filter + MainActivity 注入
    './plugins/withAndroidShareIntent',
    // iOS Share Extension target + App Group + AppDelegate 共享区迁移
    './plugins/withShareExtension',
    // 推送（doopush）：真实凭证由发版方提供，此处用 EAS_ENV / process.env 注入
    [
      'doopush-react-native-sdk',
      {
        appId: process.env.DOOPUSH_APP_ID || 'PLACEHOLDER',
        apiKey: process.env.DOOPUSH_API_KEY || 'PLACEHOLDER',
        baseURL: process.env.DOOPUSH_BASE_URL || undefined,
        ios: { mode: process.env.DOOPUSH_IOS_MODE || 'development' },
        // Android FCM/OEM 凭证通过 google-services.json 等文件在 ./assets 提供；
        // 这里仅声明使用 FCM，落地文件由发版方在仓库根放置（已 .gitignore）
      },
    ],
  ],
  extra: {
    codeVersion: CODE_VERSION,
    doopush: {
      appId: process.env.DOOPUSH_APP_ID || '',
      apiKey: process.env.DOOPUSH_API_KEY || '',
      baseURL: process.env.DOOPUSH_BASE_URL || '',
    },
  },
});
