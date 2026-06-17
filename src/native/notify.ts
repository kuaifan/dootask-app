/**
 * WS3 notify 组：通知权限、清空、跳设置、角标。
 *
 * 注：registerPush/unregisterPush 走 WS4（doopush SDK）。本组只做与推送通道无关的本地通知。
 */
import { Linking } from 'react-native';
import * as Notifications from 'expo-notifications';
import { registerHandlers } from '../bridge';
import { emitNative } from './shared';

async function getEnabled(): Promise<boolean> {
  const { status } = await Notifications.getPermissionsAsync();
  return status === 'granted';
}

export function registerNotifyHandlers(): void {
  registerHandlers({
    getNotificationPermission: async () => {
      const ok = await getEnabled();
      emitNative('__onNotificationPermissionStatus', ok);
      return ok;
    },

    requestNotificationPermission: async () => {
      const { status } = await Notifications.requestPermissionsAsync({
        ios: { allowAlert: true, allowBadge: true, allowSound: true },
      });
      const ok = status === 'granted';
      emitNative('__onNotificationPermissionStatus', ok);
      return ok;
    },

    clearAllNotify: () => Notifications.dismissAllNotificationsAsync(),

    gotoNotificationSetting: () => Linking.openSettings(),

    /** 角标：本地通知通道；WS4 集成 doopush 后可在那里同步 */
    setBadge: (args: { count?: number }) => {
      const n = Number(args?.count) || 0;
      return Notifications.setBadgeCountAsync(n);
    },
  });
}
