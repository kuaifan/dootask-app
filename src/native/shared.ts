/**
 * native→web 事件发射器共享通道。
 *
 * 桥接 hook 只有 WebView 挂载后才有 emit 能力；handler 注册发生在 App 启动时，
 * 此时尚无 emit。WebView 挂载后通过 setBridgeEmitter 把 emit 注入进来，
 * 各 handler 模块通过 emitNative(name,payload) 间接调用，自动处理"尚未就绪"的情况。
 */

type Emitter = (eventName: string, payload?: unknown) => void;

let _emit: Emitter | null = null;

export function setBridgeEmitter(emit: Emitter | null): void {
  _emit = emit;
}

export function emitNative(eventName: string, payload?: unknown): void {
  if (_emit) {
    _emit(eventName, payload);
  }
}
