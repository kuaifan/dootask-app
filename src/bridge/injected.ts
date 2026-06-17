/**
 * 注入到 WebView 的传输层 JS（通过 injectedJavaScriptBeforeContentLoaded 注入，
 * 保证在 DooTask 前端代码运行前 window.__nativeBridge 已就绪）。
 *
 * 该层只负责"传输"：postMessage 发送、pending 配对、resolve/reject、事件分发。
 * 上层 $A.nativeAppXXX 的语义封装在主程序前端 functions/native-app.js（WS6）。
 */
export const BRIDGE_INJECTED_JS = `(function(){
  if (window.__nativeBridge) { return; }
  var seq = 0;
  var pending = {};
  function post(obj){
    if (window.ReactNativeWebView && window.ReactNativeWebView.postMessage) {
      window.ReactNativeWebView.postMessage(JSON.stringify(obj));
    }
  }
  window.__nativeBridge = {
    platform: 'app',
    /** 发起一次原生方法调用，返回 Promise */
    call: function(method, args){
      return new Promise(function(resolve, reject){
        var id = ++seq;
        pending[id] = { resolve: resolve, reject: reject };
        post({ ns: 'nativeApp', type: 'call', id: id, method: method, args: (args === undefined ? null : args) });
      });
    },
    /** 由 Native 调用：兑现成功 */
    _resolve: function(id, payload){
      var p = pending[id];
      if (p) { delete pending[id]; p.resolve(payload); }
    },
    /** 由 Native 调用：兑现失败 */
    _reject: function(id, message){
      var p = pending[id];
      if (p) { delete pending[id]; p.reject(new Error(message || 'native error')); }
    },
    /** 由 Native 调用：触发前端全局回调 window[name](payload) */
    _emit: function(name, payload){
      try {
        var fn = window[name];
        if (typeof fn === 'function') { fn(payload); }
      } catch (e) { /* 忽略前端回调内部异常，避免影响原生侧 */ }
    }
  };
  true;
})();
true;`;
