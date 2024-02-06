// { "framework": "Vue"} 
if("undefined"==typeof app&&(app=weex),void 0===eeuiLog)var eeuiLog={_:function(e,t){var r=t.map((function(e){return"[object object]"===Object.prototype.toString.call(e).toLowerCase()?JSON.stringify(e):e}));void 0===this.__m&&(this.__m=app.requireModule("debug")),this.__m.addLog(e,r)},debug:function(){for(var e=[],t=arguments.length;t--;)e[t]=arguments[t];this._("debug",e)},log:function(){for(var e=[],t=arguments.length;t--;)e[t]=arguments[t];this._("log",e)},info:function(){for(var e=[],t=arguments.length;t--;)e[t]=arguments[t];this._("info",e)},warn:function(){for(var e=[],t=arguments.length;t--;)e[t]=arguments[t];this._("warn",e)},error:function(){for(var e=[],t=arguments.length;t--;)e[t]=arguments[t];this._("error",e)}};!function(e){var t={};function r(o){if(t[o])return t[o].exports;var i=t[o]={i:o,l:!1,exports:{}};return e[o].call(i.exports,i,i.exports,r),i.l=!0,i.exports}r.m=e,r.c=t,r.d=function(e,t,o){r.o(e,t)||Object.defineProperty(e,t,{enumerable:!0,get:o})},r.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},r.t=function(e,t){if(1&t&&(e=r(e)),8&t)return e;if(4&t&&"object"==typeof e&&e&&e.__esModule)return e;var o=Object.create(null);if(r.r(o),Object.defineProperty(o,"default",{enumerable:!0,value:e}),2&t&&"string"!=typeof e)for(var i in e)r.d(o,i,function(t){return e[t]}.bind(null,i));return o},r.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return r.d(t,"a",t),t},r.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},r.p="",r(r.s=14)}({14:function(e,t,r){var o,i,s=[];s.push(r(15)),o=r(16);var n=r(17);i=o=o||{},"object"!=typeof o.default&&"function"!=typeof o.default||(Object.keys(o).some((function(e){return"default"!==e&&"__esModule"!==e}))&&console.error("named exports are not supported in *.vue files."),i=o=o.default),"function"==typeof i&&(i=i.options),i.__file="/Users/WEIYI/wwwroot/dootask/resources/mobile/src/pages/web.vue",i.render=n.render,i.staticRenderFns=n.staticRenderFns,i._scopeId="data-v-6f14c300",i.style=i.style||{},s.forEach((function(e){for(var t in e)i.style[t]=e[t]})),"function"==typeof __register_static_styles__&&__register_static_styles__(i._scopeId,s),e.exports=o,e.exports.el="true",new Vue(e.exports)},15:function(e,t){e.exports={flex:{flex:1},more:{position:"absolute",top:0,left:0,right:0,bottom:0,alignItems:"flex-end",backgroundColor:"rgba(0,0,0,0)"},"more-top":{width:"40",height:"40",marginTop:"2",marginRight:"30",color:"#464646",fontSize:"30"},"more-box":{position:"absolute",top:"26",right:"16",width:"264",borderRadius:"12",backgroundColor:"#464646"},"more-item":{height:"76",fontSize:"26",lineHeight:"76",textAlign:"center",color:"#ffffff"},"more-line":{width:"264",height:"1",backgroundColor:"#333333"}}},16:function(e,t,r){"use strict";r.r(t);var o=app.requireModule("eeui"),i=app.requireModule("eeuiPicture"),s=app.requireModule("navigationBar");t.default={data:function(){return{url:app.config.params.url,browser:!!app.config.params.browser,titleFixed:!!app.config.params.titleFixed,showProgress:!!app.config.params.showProgress,allowAccess:!!app.config.params.allowAccess,moreShow:!1,moreBrowserText:o.getVariate("languageWebBrowser","浏览器打开"),moreRefreshText:o.getVariate("languageWebRefresh","刷新"),navColor:null,themeColor:null,systemTheme:o.getThemeName()}},mounted:function(){this.initTheme(null),this.initNav(),this.$refs.web.setUrl(this.url)},computed:{warpStyle:function(){return this.themeColor?{backgroundColor:this.themeColor}:{}}},methods:{initTheme:function(e){e?o.setCachesString("themeName",e,0):e=o.getCachesString("themeName",""),["light","dark"].includes(e)||(e=this.systemTheme),this.themeColor="dark"===e?"#131313":"#f8f8f8",this.navColor="dark"===e?"#cdcdcd":"#232323",o.setStatusBarStyle("dark"===e),o.setStatusBarColor(this.themeColor),o.setBackgroundColor(this.themeColor)},initNav:function(){var e=this;s.setLeftItem({icon:"ios-arrow-back",iconSize:40,iconColor:this.navColor,width:110},(function(e){o.closePage()})),s.setTitle({titleColor:this.navColor}),s.setRightItem({icon:"ios-more",iconSize:40,iconColor:this.navColor,width:120},(function(t){e.moreShow=!e.moreShow}))},itemClick:function(e){switch(e){case"browser":this.url&&o.openWeb(this.url);break;case"refresh":this.$refs.web.setUrl(this.url)}this.moreShow=!1},onReceiveMessage:function(e){var t=e.message;switch(t.action){case"picturePreview":i.picturePreview(t.position,t.paths);break;case"videoPreview":i.videoPreview(t.path)}},onStateChanged:function(e){switch(e.status){case"title":if(!this.titleFixed){if(["HitoseaTask","DooTask","about:blank"].includes(e.title))return;s.setTitle({title:e.title,titleColor:this.navColor})}break;case"url":this.url=e.url;break;case"createTarget":this.$refs.web.setUrl(e.url)}}}}},17:function(e,t){e.exports={render:function(){var e=this,t=e.$createElement,r=e._self._c||t;return r("div",{staticClass:["flex"],style:e.warpStyle},[r("web-view",{ref:"web",staticClass:["flex"],attrs:{transparency:!0,allowFileAccessFromFileURLs:e.allowAccess,progressbarVisibility:e.showProgress},on:{receiveMessage:e.onReceiveMessage,stateChanged:e.onStateChanged}}),!0===e.moreShow?r("div",{staticClass:["more"],on:{click:function(t){e.moreShow=!1}}},[r("icon",{staticClass:["more-top"],attrs:{content:"tb-triangle-up-fill"}}),r("div",{staticClass:["more-box"]},[e.browser?[r("text",{staticClass:["more-item"],on:{click:function(t){e.itemClick("browser")}}},[e._v(e._s(e.moreBrowserText))]),r("div",{staticClass:["more-line"]})]:e._e(),r("text",{staticClass:["more-item"],on:{click:function(t){e.itemClick("refresh")}}},[e._v(e._s(e.moreRefreshText))])],2)],1):e._e()],1)},staticRenderFns:[]},e.exports.render._withStripped=!0}});