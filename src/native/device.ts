/**
 * WS3 device 组：设备/系统信息。
 */
import { Appearance, Dimensions, Platform } from 'react-native';
import { initialWindowMetrics } from 'react-native-safe-area-context';
import * as Device from 'expo-device';
import Constants from 'expo-constants';
import { registerHandlers } from '../bridge';

function getCodeVersion(): number {
  const extra = (Constants.expoConfig?.extra ?? {}) as { codeVersion?: number };
  return Number(extra.codeVersion) || 0;
}

export function registerDeviceHandlers(): void {
  registerHandlers({
    /** 完整设备信息（前端用于 ua 上报等） */
    getDeviceInfo: () => {
      const win = Dimensions.get('window');
      return {
        platform: Platform.OS,
        brand: Device.brand ?? '',
        model: Device.modelName ?? Device.modelId ?? '',
        manufacturer: Device.manufacturer ?? '',
        systemName: Device.osName ?? Platform.OS,
        systemVersion: Device.osVersion ?? String(Platform.Version),
        appVersion: Constants.expoConfig?.version ?? '',
        codeVersion: getCodeVersion(),
        deviceType: Device.deviceType ?? null,
        isDevice: Device.isDevice,
        screen: { width: win.width, height: win.height, scale: win.scale },
      };
    },

    /** 应用语义版本号，如 1.7.91 */
    getAppVersion: () => Constants.expoConfig?.version ?? '',

    /** 应用 codeVersion（整数） */
    getAppLocalVersion: () => getCodeVersion(),

    /** 当前系统主题 light|dark */
    getThemeName: () => (Appearance.getColorScheme() === 'dark' ? 'dark' : 'light'),

    /** 移动端不存在窗口化概念，恒 false（保留接口以兼容前端调用） */
    isWindowed: () => false,

    /** 安全区域插入值（来自 SafeAreaProvider 的 initialWindowMetrics） */
    getSafeAreaInsets: () => {
      const insets = initialWindowMetrics?.insets ?? { top: 0, bottom: 0, left: 0, right: 0 };
      return {
        top: insets.top,
        bottom: insets.bottom,
        left: insets.left,
        right: insets.right,
      };
    },
  });
}
