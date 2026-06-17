/**
 * WS3 ui 组：UI 容器控制（alert/toast/keyboard/振动/常亮/返回键/滚动）。
 */
import {
  Alert,
  BackHandler,
  Keyboard,
  NativeModules,
  Platform,
  ToastAndroid,
  Vibration,
} from 'react-native';
import { activateKeepAwakeAsync, deactivateKeepAwake } from 'expo-keep-awake';
import * as Haptics from 'expo-haptics';
import { registerHandlers } from '../bridge';
import { emitNative } from './shared';

interface AlertArgs {
  title?: string;
  message?: string;
  buttons?: Array<{ text: string }>;
}

interface ToastArgs {
  message: string;
  duration?: 'short' | 'long';
}

let _keyboardSubs: Array<{ remove: () => void }> = [];
let _keyboardListening = false;
function ensureKeyboardListeners(): void {
  if (_keyboardListening) return;
  _keyboardListening = true;
  const showEv = Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow';
  const hideEv = Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide';
  _keyboardSubs.push(
    Keyboard.addListener(showEv, (e) => {
      emitNative('__onKeyboardStatus', { visible: true, height: e.endCoordinates?.height ?? 0 });
    }),
  );
  _keyboardSubs.push(
    Keyboard.addListener(hideEv, () => {
      emitNative('__onKeyboardStatus', { visible: false, height: 0 });
    }),
  );
}

let _backHandlerSub: { remove: () => void } | null = null;

/** 调用方注册 setPageBackPressed({enabled:true}) 后，Android 返回键被拦截并触发 __onBackPressed */
function setBackPressedEnabled(enabled: boolean): void {
  if (Platform.OS !== 'android') return;
  if (enabled && !_backHandlerSub) {
    _backHandlerSub = BackHandler.addEventListener('hardwareBackPress', () => {
      emitNative('__onBackPressed');
      return true; // 拦截，由前端决定行为
    });
  } else if (!enabled && _backHandlerSub) {
    _backHandlerSub.remove();
    _backHandlerSub = null;
  }
}

export function registerUiHandlers(): void {
  registerHandlers({
    alert: (args: AlertArgs) =>
      new Promise<{ index: number }>((resolve) => {
        const buttons = args.buttons?.length
          ? args.buttons.map((b, i) => ({ text: b.text, onPress: () => resolve({ index: i }) }))
          : [{ text: 'OK', onPress: () => resolve({ index: 0 }) }];
        Alert.alert(args.title ?? '', args.message ?? '', buttons, { cancelable: false });
      }),

    toast: (args: ToastArgs) => {
      const dur = args.duration === 'long' ? ToastAndroid.LONG : ToastAndroid.SHORT;
      if (Platform.OS === 'android') {
        ToastAndroid.show(args.message, dur);
      } else {
        // iOS 无原生 Toast；最小实现：用 Alert 兜底，避免静默失败。
        // 美观替代由 WS3 增强阶段考虑（如 react-native-root-toast）。
        Alert.alert('', args.message);
      }
    },

    keyboardHide: () => {
      Keyboard.dismiss();
    },

    /** 启用键盘状态广播；幂等，多次调用只挂一次监听 */
    keyboardStatus: () => {
      ensureKeyboardListeners();
      return { visible: Keyboard.isVisible(), height: Keyboard.metrics()?.height ?? 0 };
    },

    vibrate: (args?: { time?: number }) => {
      const t = args?.time;
      if (typeof t === 'number' && t > 0) {
        Vibration.vibrate(t);
      } else {
        Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {
          Vibration.vibrate(20);
        });
      }
    },

    setHapticBackEnabled: (_enabled: boolean) => {
      // Android 长按震动反馈：交由前端在 onLongPress 时主动调 vibrate；
      // 此 method 仅作为开关占位以兼容旧调用，避免抛错。
    },

    setScrollDisabled: (_disabled: boolean) => {
      // 由前端用 CSS overflow 控制更可靠；此处保留接口避免抛错。
    },

    keepScreenOn: () => activateKeepAwakeAsync(),

    keepScreenOff: () => {
      deactivateKeepAwake();
    },

    setPageBackPressed: (args: { enabled?: boolean }) => {
      setBackPressedEnabled(!!args?.enabled);
    },

    goDesktop: () => {
      if (Platform.OS === 'android') {
        const mod = NativeModules.PlatformConstants;
        // RN 无统一 moveTaskToBack API；最小实现：触发 BackHandler 退栈到底。
        // 真实方案在 prebuild 后用 native module；本期占位以保接口兼容。
        BackHandler.exitApp();
        void mod; // 避免未用变量警告
      }
    },

    /** 接收前端反馈的窗口宽度（高度可选），写入内存（旧逻辑用于响应式布局） */
    windowSize: (args: { width?: number; height?: number }) => {
      // 仅记录，必要时由 storage 层持久化；当前不持久化（与旧 setVariate 语义一致：会话级）
      void args;
    },
  });
}
