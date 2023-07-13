// { "framework": "Vue"} 
if("undefined"==typeof app&&(app=weex),void 0===eeuiLog)var eeuiLog={_:function(t,e){var i=e.map((function(t){return"[object object]"===Object.prototype.toString.call(t).toLowerCase()?JSON.stringify(t):t}));void 0===this.__m&&(this.__m=app.requireModule("debug")),this.__m.addLog(t,i)},debug:function(){for(var t=[],e=arguments.length;e--;)t[e]=arguments[e];this._("debug",t)},log:function(){for(var t=[],e=arguments.length;e--;)t[e]=arguments[e];this._("log",t)},info:function(){for(var t=[],e=arguments.length;e--;)t[e]=arguments[e];this._("info",t)},warn:function(){for(var t=[],e=arguments.length;e--;)t[e]=arguments[e];this._("warn",t)},error:function(){for(var t=[],e=arguments.length;e--;)t[e]=arguments[e];this._("error",t)}};!function(t){var e={};function i(n){if(e[n])return e[n].exports;var o=e[n]={i:n,l:!1,exports:{}};return t[n].call(o.exports,o,o.exports,i),o.l=!0,o.exports}i.m=t,i.c=e,i.d=function(t,e,n){i.o(t,e)||Object.defineProperty(t,e,{enumerable:!0,get:n})},i.r=function(t){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(t,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(t,"__esModule",{value:!0})},i.t=function(t,e){if(1&e&&(t=i(t)),8&e)return t;if(4&e&&"object"==typeof t&&t&&t.__esModule)return t;var n=Object.create(null);if(i.r(n),Object.defineProperty(n,"default",{enumerable:!0,value:t}),2&e&&"string"!=typeof t)for(var o in t)i.d(n,o,function(e){return t[e]}.bind(null,o));return n},i.n=function(t){var e=t&&t.__esModule?function(){return t.default}:function(){return t};return i.d(e,"a",e),e},i.o=function(t,e){return Object.prototype.hasOwnProperty.call(t,e)},i.p="",i(i.s=8)}([function(t,e){t.exports={"g-cover":{position:"absolute",top:0,left:0,right:0,bottom:0,backgroundColor:"rgba(0,0,0,0.5)"},container:{backgroundColor:"#FFFFFF",borderRadius:"16",alignSelf:"center"},confirmTitle:{paddingTop:"16",paddingRight:"32",paddingBottom:"16",paddingLeft:"32",backgroundColor:"#84c56a",borderRadius:"8"}}},function(t,e,i){"use strict";i.r(e),e.default={props:{pos:{type:String,default:"center"},offset:{type:Number,default:0},canOverlayClick:{type:Boolean,default:!0},miniRate:{default:1}},data:function(){return{back:!1,show:!1,title:"",message:"",cancel:"",confirm:""}},computed:{posStyle:function(){var t={},e=this.pos?this.pos:"center";switch(t.position="absolute",t.width=this.scaleSize(718),t.padding=this.scaleSize(48),e){case"center":t.alignSelf="center";break;case"bottom":t.bottom=this.offset+"px";break;case"top":t.top=this.offset*this.miniRate+"px"}return t},iconStyle:function(){return{width:this.scaleSize(50),height:this.scaleSize(50)}},HStyle:function(){return{justifyContent:"left",marginLeft:this.scaleSize(32)}},titleStyle:function(){return{fontSize:this.scaleSize(30),marginTop:this.scaleSize(4)}},subTitleStyle:function(){return{fontSize:this.scaleSize(26),marginTop:this.scaleSize(32)}},buttonGroupStyle:function(){return{marginTop:this.scaleSize(64)}},buttonBGStyle:function(){return{marginRight:this.scaleSize(64)}},confirmButtonStyle:function(){return{paddingLeft:this.scaleSize(32),paddingRight:this.scaleSize(32),paddingTop:this.scaleSize(12),paddingBottom:this.scaleSize(12)}},buttonTextStyle:function(){return{fontSize:this.scaleSize(26)}}},mounted:function(){this.show=!1},methods:{scaleSize:function(t){return this.miniRate*t+"px"},hide:function(){this.show=!1},cancelClick:function(){this.hide()},confirmClick:function(){this.hide(),this.$emit("exitConfirm")},showWithParam:function(t){this.title=t.title,this.message=t.message,this.cancel=t.cancel,this.confirm=t.confirm,this.show=!0}}}},function(t,e){t.exports={render:function(){var t=this,e=t.$createElement,i=t._self._c||e;return t.show?i("div",{staticClass:["g-cover"],on:{overlay:t.cancelClick}},[i("div",{staticClass:["container","flex-d-c"],style:t.posStyle},[i("div",{staticStyle:{flexDirection:"row"}},[i("image",{style:t.iconStyle,attrs:{src:"root://pages/assets/images/alert-icon.png"}}),i("div",{style:t.HStyle},[i("text",{staticStyle:{fontWeight:"300",color:"black"},style:t.titleStyle},[t._v(t._s(t.title))]),i("text",{staticStyle:{fontSize:"26px",fontWeight:"300",color:"black"},style:t.subTitleStyle},[t._v(t._s(t.message))])])]),i("div",{staticStyle:{flexDirection:"row"}},[i("div",{staticStyle:{flex:"1"}}),i("div",{staticStyle:{flexDirection:"row",justifyContent:"space-between"},style:t.buttonGroupStyle},[i("div",{staticClass:["cancelTitle"],staticStyle:{justifyContent:"center"},style:t.buttonBGStyle,on:{click:t.cancelClick}},[i("text",{staticStyle:{fontWeight:"300",color:"black"},style:t.buttonTextStyle},[t._v(t._s(t.cancel))])]),i("div",{staticClass:["confirmTitle"],style:t.confirmButtonStyle,on:{click:t.confirmClick}},[i("text",{staticStyle:{fontWeight:"300",color:"white"},style:t.buttonTextStyle},[t._v(t._s(t.confirm))])])])])])]):t._e()},staticRenderFns:[]},t.exports.render._withStripped=!0},,,,,,function(t,e,i){var n,o,r=[];r.push(i(0)),n=i(1);var s=i(2);o=n=n||{},"object"!=typeof n.default&&"function"!=typeof n.default||(Object.keys(n).some((function(t){return"default"!==t&&"__esModule"!==t}))&&console.error("named exports are not supported in *.vue files."),o=n=n.default),"function"==typeof o&&(o=o.options),o.__file="/Users/WEIYI/wwwroot/dootask/resources/mobile/src/pages/compoment/customAlert.vue",o.render=s.render,o.staticRenderFns=s.staticRenderFns,o._scopeId="data-v-07ed30b4",o.style=o.style||{},r.forEach((function(t){for(var e in t)o.style[e]=t[e]})),"function"==typeof __register_static_styles__&&__register_static_styles__(o._scopeId,r),t.exports=n,t.exports.el="true",new Vue(t.exports)}]);