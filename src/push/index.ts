/**
 * WS4 推送（doopush）：
 *
 * - App 启动时 configure（appId/apiKey/baseURL 来自 app.config extra.doopush）
 * - 监听消息/点击事件，点击 → 解析 payload(dialog_id) → 注入 window.__initializeApp 跳转
 * - 暴露 registerPush/unregisterPush 给桥接（前端登录/登出时调用）
 * - setBadge 沿用 expo-notifications 实现（见 notify.ts），与本模块协同
 */
import Constants from 'expo-constants';
import { DooPush, type DooPushMessage, type DooPushVendor } from 'doopush-react-native-sdk';
import { registerHandlers } from '../bridge';
import { emitNative } from '../native/shared';

interface DooPushConfigExtra {
  appId?: string;
  apiKey?: string;
  baseURL?: string;
}

interface RegisterArgs {
  /** 备用：若主流程拿到了外部 token（如 expo-notifications）可走 passive 注册 */
  externalToken?: string;
  externalVendor?: DooPushVendor;
}

let _configured = false;
let _subs: Array<{ remove: () => void }> = [];

/**
 * 把点击/接收的消息转给前端：复刻旧 EEUI 流程——把 dialog_id 写进 hash，触发 __initializeApp
 * 让前端的全局深链逻辑接管（openDialog/路由切换）。
 */
function deliverClickToWeb(msg: DooPushMessage): void {
  const data = msg.data || {};
  const dialogId = data.dialog_id || data.dialogId;
  if (dialogId) {
    emitNative('__initializeApp', `#/manage/messenger?dialogId=${dialogId}`);
  } else {
    emitNative('__initializeApp', '');
  }
}

function ensureConfigured(): void {
  if (_configured) return;
  const extra = (Constants.expoConfig?.extra ?? {}) as { doopush?: DooPushConfigExtra };
  const cfg = extra.doopush || {};
  if (!cfg.appId || !cfg.apiKey) {
    // 未配置则不 configure，register 时会显式抛错，避免静默失败。
    return;
  }
  DooPush.configure({
    appId: cfg.appId,
    apiKey: cfg.apiKey,
    baseURL: cfg.baseURL || undefined,
  });
  _configured = true;

  // 接收消息（前台/后台均会触发）
  _subs.push(
    DooPush.addMessageListener((m) => {
      emitNative('__onPushMessage', m);
    }),
  );
  // 点击通知 → 跳转
  _subs.push(
    DooPush.addNotificationClickListener((m) => {
      deliverClickToWeb(m);
    }),
  );
  _subs.push(
    DooPush.addNotificationOpenListener((m) => {
      deliverClickToWeb(m);
    }),
  );
}

export function setupPush(): void {
  ensureConfigured();
}

export function disposePush(): void {
  for (const s of _subs) s.remove();
  _subs = [];
}

export function registerPushHandlers(): void {
  registerHandlers({
    registerPush: async (args?: RegisterArgs) => {
      ensureConfigured();
      if (!_configured) {
        throw new Error('doopush not configured (set extra.doopush in app.config)');
      }
      if (args?.externalToken) {
        const { deviceId } = await DooPush.registerWithToken(
          args.externalToken,
          args.externalVendor || 'fcm',
        );
        return { deviceId, token: args.externalToken, vendor: args.externalVendor || 'fcm' };
      }
      const r = await DooPush.register();
      return { deviceId: r.deviceId, token: r.token, vendor: r.vendor };
    },

    unregisterPush: async () => {
      // SDK 暂未提供主动注销接口；调用方应在服务端解绑 deviceId↔userid 映射（见 WS4 后端）。
      // 此处仅清理本地监听以便重新 configure。
      disposePush();
      _configured = false;
    },

    /** 获取 SDK 当前已注册的 deviceId（未注册返回 null） */
    getPushDeviceId: () => DooPush.getDeviceId(),
  });
}
