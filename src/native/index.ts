/**
 * WS3 原生能力总入口：注册所有 handler 到桥接 registry。
 * App 启动时（App.tsx）调用一次 registerNativeHandlers()。
 *
 * 各组按 CONTRACT.md 划分，互不依赖。WS4(push)、WS5(meeting) 各自独立注册。
 */
import { registerDeviceHandlers } from './device';
import { registerUiHandlers } from './ui';
import { registerStorageHandlers } from './storage';
import { registerMediaHandlers } from './media';
import { registerLinkHandlers } from './link';
import { registerNotifyHandlers } from './notify';
import { registerPushHandlers, setupPush } from '../push';
import { registerMeetingHandlers } from '../meeting';
import { registerShareHandlers } from './share';

export function registerNativeHandlers(): void {
  registerDeviceHandlers();
  registerUiHandlers();
  registerStorageHandlers();
  registerMediaHandlers();
  registerLinkHandlers();
  registerNotifyHandlers();
  registerPushHandlers();
  registerMeetingHandlers();
  registerShareHandlers();
  // 推送 SDK 初始化（依赖 app.config extra.doopush；未配置时安全跳过）
  setupPush();
}

export { setBridgeEmitter } from './shared';
