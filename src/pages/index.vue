<template>
    <div class="flex" :style="warpStyle">
        <web-view
            ref="web"
            class="flex"
            :fullscreen="true"
            :hiddenDone="true"
            :transparency="true"
            :progressbarVisibility="false"
            :allowFileAccessFromFileURLs="true"
            @receiveMessage="onReceiveMessage"
            @stateChanged="onStateChanged"/>
        <meetings
            ref="meeting"
            :theme-color="themeColor"
            :theme-name="themeName"
            :safe-area-size="safeAreaSize"
            :windowWidth="windowWidth"
            @meetingEvent="meetingEvent"/>
    </div>
</template>

<style scoped>
.flex {
    flex: 1;
}
</style>
<script>
import Meetings from "./compoment/meetings.vue";
const eeui = app.requireModule('eeui');
const deviceInfo = app.requireModule("eeui/deviceInfo");
const umengPush = app.requireModule("eeui/umengPush");
const communication = app.requireModule("eeui/communication");
const notifications = app.requireModule("eeui/notifications");
const picture = app.requireModule("eeui/picture");
const shareFile = app.requireModule("eeui/shareFiles");
const webServer = app.requireModule("eeui/webserver");

export default {
    components: {Meetings},
    data() {
        return {
            webReady: false,
            uniqueId: '',
            resumeNum: 0,
            appMessage: {},
            webServerPort: 22223,

            windowWidth: parseInt(eeui.getVariate("windowWidth", "0")) || 430,
            safeAreaSize: {top: 0, bottom: 0, data: null},

            umengInit: false,
            umengApiUrl: null,
            umengError: false,

            themeName: '',                      // 主题颜色
            themeColor: null,                   // 主题颜色
            themeDefault: {                     // 主题默认值
                theme: {
                    dark: '#131313',
                    light: '#f8f8f8'
                },
                nav: {
                    dark: '#cdcdcd',
                    light: '#232323'
                }
            },
            navColor: null,                     // 导航栏颜色
            systemTheme: eeui.getThemeName(),   // 主题名称

            appGroupID: "group.im.dootask",     // iOS共享储存的应用唯一标识符
            appSubPath: "share",                // iOS 储存下一级目录
        }
    },

    // APP进入前台：App从【后台】切换至【前台】时触发
    appActive() {
        const javascript = `if (typeof window.__onAppActive === "function"){window.__onAppActive()}`;
        this.$refs.web.setJavaScript(javascript);
        this.startWebServer(false);
    },

    // APP进入后台：App从【前台】切换至【后台】时触发
    appDeactive() {
        const javascript = `if (typeof window.__onAppDeactive === "function"){window.__onAppDeactive()}`;
        this.$refs.web.setJavaScript(javascript);
    },

    // 页面激活：页面【恢复】时触发（渲染完成时也会触发1次）
    pageResume() {
        const javascript = `if (typeof window.__onPageResume === "function"){window.__onPageResume(${this.resumeNum})}`;
        this.$refs.web.setJavaScript(javascript);
        this.resumeNum++;
        this.refreshNotificationPermission()
        
        // 清除所有通知
        notifications.clearAll();
        //
        if (this.umengError) {
            this.updateUmengAlias()
        }
    },

    // 页面失活：页面【暂停】时触发
    pagePause() {
        const javascript = `if (typeof window.__onPagePause === "function"){window.__onPagePause()}`;
        this.$refs.web.setJavaScript(javascript);
    },

    // 接收到的信息
    pageMessage({message}) {
        // noinspection JSUnreachableSwitchBranches
        switch (message.messageType) {
            case 'notificationClick':
                // console.log('点击了通知栏消息：', message);
                break;

            case 'keyboardStatus':
                const data = this.jsonStringify(message);
                const javascript = `if (typeof window.__onKeyboardStatus === "function"){window.__onKeyboardStatus(${data})}`;
                this.$refs.web.setJavaScript(javascript);
                break;

            case "link":
                if (this.webReady) {
                    this.linkEvent(message.jumpUrl)
                } else {
                    setTimeout(() => {
                        // 延迟执行
                        this.linkEvent(message.jumpUrl)
                    }, 2000)
                }

        }
    },

    mounted() {
        this.initTheme(null);

        // iOS初始化共享内存
        if (WXEnvironment.platform.toLowerCase() === "ios") {
            shareFile.shareFileWithGroupID(this.appGroupID, this.appSubPath);
        }

        this.uniqueId = eeui.getCachesString("appUniqueId", "");
        if (this.count(this.uniqueId) < 5) {
            this.uniqueId = this.randomString(6);
            eeui.setCachesString("appUniqueId", this.uniqueId, 0);
        }

        eeui.getSafeAreaInsets(result => {
            if (result.status === 'success') {
                this.safeAreaSize = result
            }
        });

        this.startWebServer(true, 3)
    },

    computed: {
        warpStyle() {
            if (this.themeColor) {
                return {
                    backgroundColor: this.themeColor,
                }
            }
            return {}
        }
    },

    methods: {
        /**
         * 启动Web服务器
         * @param init  // 是否初始化，如果是初始化则设置WebView的URL
         */
        async startWebServer(init, retry = 0) {
            const status = await (new Promise(resolve => webServer.getServerStatus(resolve)));
            console.log(status);

            if (status.status !== "success") {
                const result = await (new Promise(resolve => webServer.startWebServer({
                    path: eeui.rewriteUrl('../public'),
                    port: this.webServerPort
                }, resolve)));
                console.log(result);
                // 重试机制
                if (result.status !== "success" || result.port === 0) {
                    console.log("启动Web服务器失败");
                    if (retry > 0) {
                        console.log("准备重新启动Web服务器...");
                        setTimeout(() => {
                            this.startWebServer(init, retry - 1)
                        }, 1000)
                        return;
                    }
                }
            }

            if (init) {
                eeui.setCachesString("appWebServerPort", this.webServerPort, 0);
                this.$refs.web.setUrl(`http://localhost:${this.webServerPort}/`);
            }
        },

        /**
         * 初始化主题
         * @param themeName
         */
        initTheme(themeName) {
            const config = this.jsonParse(eeui.getCachesString("themeDefault", "{}"), this.themeDefault)
            if (config.theme && config.nav) {
                this.themeDefault = config
            }
            //
            if (themeName) {
                eeui.setCachesString("themeName", themeName, 0)
            } else {
                themeName = eeui.getCachesString("themeName", "")
            }
            if (!['light', 'dark'].includes(themeName)) {
                themeName = this.systemTheme
            }
            //
            this.themeName = themeName
            this.themeColor = this.themeDefault.theme[themeName]
            this.navColor = this.themeDefault.nav[themeName]
            eeui.setStatusBarStyle(themeName === 'dark')
            eeui.setStatusBarColor(this.themeColor)
            eeui.setBackgroundColor(this.themeColor)
        },

        /**
         * 来自网页的消息
         * @param message
         */
        onReceiveMessage({message}) {
            switch (message.action) {
                case 'initApp':
                    this.appMessage = message;
                    if (!this.umengInit) {
                        this.umengInit = true;
                        umengPush.initialize();
                    }
                    break;

                case 'setUmengAlias':
                    this.webReady = true;
                    this.umengApiUrl = message.url;
                    this.updateUmengAlias();
                    break;

                case 'delUmengAlias':
                    this.umengApiUrl = message.url;
                    this.removeUmengAlias();
                    break;

                case 'setVibrate':
                    const time = parseInt(message.time) || 0;
                    if (time > 0) {
                        deviceInfo.setVibrate(time);
                    } else {
                        deviceInfo.setVibrate();
                    }
                    break;

                case 'getNotificationPermission':
                    this.refreshNotificationPermission()
                    break;

                case 'setBadgeNum':
                case 'setBdageNotify':
                    umengPush.setBadgeNum(parseInt(message.bdage) || 0);
                    break;

                case 'clearAllNotify':
                    notifications.clearAll();
                    break;

                case 'gotoSetting':
                    notifications.gotoSet();
                    break;

                case 'callTel':
                    communication.call(message.tel)
                    break;

                case 'picturePreview':
                    message.language && picture.setLanguage(message.language)
                    picture.picturePreview(message.position, message.paths)
                    break;

                case 'videoPreview':
                    message.language && picture.setLanguage(message.language)
                    picture.videoPreview(message.path)
                    break;

                // iOS 储存本地获取聊天消息
                case 'userChatList':
                    if (WXEnvironment.platform.toLowerCase() === "ios") {
                        message.language && shareFile.setShareStorage('language', message.language)
                        shareFile.setShareStorage('chatList', message.url)
                    } else {
                        message.language && eeui.setCaches('language', message.language, 0)
                        eeui.setCaches('chatList', message.url, 0)
                    }
                    break;

                // iOS 储存本地上传地址
                case 'userUploadUrl':
                    if (WXEnvironment.platform.toLowerCase() === "ios") {
                        shareFile.setShareStorage('upLoadUrl', message.chatUrl)
                        shareFile.setShareStorage('fileUpLoadUrl', message.dirUrl)
                    } else {
                        eeui.setCaches('upLoadUrl', message.chatUrl, 0)
                        eeui.setCaches('fileUpLoadUrl', message.dirUrl, 0)
                    }
                    break

                case 'startMeeting':
                    this.$refs.meeting && this.$refs.meeting.joint(message.meetingParams)
                    break

                case 'updateMeetingInfo':
                    this.$refs.meeting && this.$refs.meeting.updateMeetingInfo(message.infos)
                    break

                // 更新状态栏
                case 'updateTheme':
                    if (this.isJson(message.themeDefault)) {
                        eeui.setCachesString("themeDefault", this.jsonStringify(message.themeDefault), 0)
                    }
                    this.initTheme(message.themeName)
                    break

                // 更新网页尺寸
                case 'windowSize':
                    this.windowWidth = parseInt(message.width) || 0
                    eeui.setVariate("windowWidth", this.windowWidth)
                    break
            }
        },

        onStateChanged({status, url}) {
            switch (status) {
                case 'createTarget':
                    const javascript = `if (typeof window.__onCreateTarget === "function"){window.__onCreateTarget("${url}")}`;
                    this.$refs.web.setJavaScript(javascript);
                    break;
            }
        },

        async updateUmengAlias() {
            const alias = await this.aliasDelete()
            umengPush.addAlias(alias, "userid", data => {
                if (data.status === 'success') {
                    this.ajaxUmengAlias(alias, 'update')
                } else {
                    console.log("[UmengAlias] add error");
                }
                this.umengError = data.status !== 'success'
            });
        },

        async removeUmengAlias() {
            const alias = await this.aliasDelete()
            await this.ajaxUmengAlias(alias, 'remove')
        },

        async ajaxUmengAlias(alias, action) {
            eeui.ajax({
                url: this.umengApiUrl,
                method: 'get',
                data: {
                    alias,
                    action,
                    osName: WXEnvironment.osName,
                    osVersion: WXEnvironment.osVersion,
                    deviceModel: WXEnvironment.deviceModel,
                    appVersion: eeui.getLocalVersion(),
                    appVersionName: eeui.getLocalVersionName(),
                    isDebug: eeui.isDebug(),
                    userAgent: this.appMessage.userAgent,
                    isNotified: await this.getPermissionStatus(),
                },
                headers: {
                    token: this.appMessage.token,
                    language: this.appMessage.language,
                }
            }, result => {
                console.log(result);
            });
        },

        aliasDelete() {
            return new Promise(resolve => {
                const alias = `${WXEnvironment.platform}-${this.appMessage.userid}-${this.uniqueId}`;
                umengPush.deleteAlias(alias, "userid", () => {
                    resolve(alias)
                })
            })
        },

        getPermissionStatus() {
            return new Promise(resolve => {
                notifications.getPermissionStatus(ret => {
                    resolve(ret)
                });
            })
        },

        refreshNotificationPermission() {
            notifications.getPermissionStatus(ret => {
                const javascript = `if (typeof window.__onNotificationPermissionStatus === "function"){window.__onNotificationPermissionStatus(${ret})}`;
                this.$refs.web.setJavaScript(javascript);
            });
        },

        meetingEvent(param) {
            const paramStr = this.jsonStringify(param);
            const javascript = `if (typeof window.__onMeetingEvent === "function"){window.__onMeetingEvent(${paramStr})}`;
            this.$refs.web.setJavaScript(javascript);
        },

        linkEvent(link) {
            const javascript = `if (typeof window.__handleLink === "function"){window.__handleLink("${link}")}`;
            this.$refs.web.setJavaScript(javascript);
        },
    }
}
</script>
