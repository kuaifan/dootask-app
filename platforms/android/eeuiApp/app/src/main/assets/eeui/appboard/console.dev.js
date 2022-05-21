"use strict";

var _debug = app.requireModule('debug');

console = {
  open: true,
  _: function _(e) {
    return e.map(function (e) {
      return e = "[object object]" === Object.prototype.toString.call(e).toLowerCase() ? JSON.stringify(e) : e;
    });
  },
  debug: function debug() {
    for (var e = [], t = arguments.length; t--;) {
      e[t] = arguments[t];
    }

    _debug.addLog("debug", this._(e));
  },
  log: function log() {
    for (var e = [], t = arguments.length; t--;) {
      e[t] = arguments[t];
    }

    _debug.addLog("log", this._(e));
  },
  info: function info() {
    for (var e = [], t = arguments.length; t--;) {
      e[t] = arguments[t];
    }

    _debug.addLog("info", this._(e));
  },
  warn: function warn() {
    for (var e = [], t = arguments.length; t--;) {
      e[t] = arguments[t];
    }

    _debug.addLog("warn", this._(e));
  },
  error: function error() {
    for (var e = [], t = arguments.length; t--;) {
      e[t] = arguments[t];
    }

    _debug.addLog("error", this._(e));
  }
};