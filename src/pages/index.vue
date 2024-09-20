<template>
    <div class="flex" :style="warpStyle">
        <web-view
            ref="web"
            class="flex"
            :hiddenDone="true"
            :transparency="true"
            :progressbarVisibility="false"
            :allowFileAccessFromFileURLs="true"
            @receiveMessage="onReceiveMessage"
            @stateChanged="onStateChanged"/>
        <meetings ref="meeting" :theme-color="themeColor" :theme-name="themeName" :windowWidth="windowWidth" @meetingEvent="meetingEvent"/>
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
const shareFile = app.requireModule("eeuiShareFiles");

export default {
    components: {Meetings},
    data() {
        return {
            webReady: false,
            uniqueId: '',
            resumeNum: 0,
            appMessage: {},

            windowWidth: parseInt(eeui.getVariate("windowWidth", "0")) || 430,

            umengInit: false,
            umengApiUrl: null,
            umengError: false,

            navColor: null,                     // 导航栏颜色
            themeName: '',                      // 主题颜色
            themeColor: null,                   // 主题颜色
            systemTheme: eeui.getThemeName(),   // 主题名称

            appGroupID: "group.im.dootask",     // iOS共享储存的应用唯一标识符
            appSubPath: "share",                // iOS 储存下一级目录
        }
    },

    // APP进入前台：App从【后台】切换至【前台】时触发
    appActive() {
        const javascript = `if (typeof window.__onAppActive === "function"){window.__onAppActive()}`;
        this.$refs.web.setJavaScript(javascript);
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
                const data = encodeURIComponent(this.jsonStringify(message));
                const javascript = `if (typeof window.__onKeyboardStatus === "function"){window.__onKeyboardStatus("${data}")}`;
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

        this.$refs.web.setUrl(eeui.rewriteUrl('../public/index.html'));
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
         * 初始化主题
         * @param themeName
         */
        initTheme(themeName) {
            if (themeName) {
                eeui.setCachesString("themeName", themeName, 0)
            } else {
                themeName = eeui.getCachesString("themeName", "")
            }
            if (!['light', 'dark'].includes(themeName)) {
                themeName = this.systemTheme
            }
            this.themeName = themeName
            this.themeColor = themeName === 'dark' ? '#131313' : '#f8f8f8'
            this.navColor = themeName === 'dark' ? '#cdcdcd' : '#232323'
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
                    this.umengApiUrl = message.url;
                    this.webReady = true;
                    this.updateUmengAlias();
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

                case 'setBdageNotify':
                    notifications.setBadge(parseInt(message.bdage) || 0);
                    break;

                case 'gotoSetting':
                    notifications.gotoSet();
                    break;

                case 'callTel':
                    communication.call(message.tel)
                    break;

                case 'picturePreview':
                    picture.picturePreview(message.position, message.paths)
                    break;

                case 'videoPreview':
                    picture.videoPreview(message.path)
                    break;

                // iOS 储存本地获取聊天消息
                case 'userChatList':
                    if (WXEnvironment.platform.toLowerCase() === "ios") {
                        shareFile.setShareStorage('chatList', message.url)
                    } else {
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

        updateUmengAlias() {
            const alias = `${WXEnvironment.platform}-${this.appMessage.userid}-${this.uniqueId}`;
            umengPush.deleteAlias(alias, "userid", () => {
                umengPush.addAlias(alias, "userid", data => {
                    if (data.status === 'success') {
                        // 别名保存到服务器
                        eeui.ajax({
                            url: this.umengApiUrl,
                            method: 'get',
                            data: {
                                alias,
                                osName: WXEnvironment.osName,
                                osVersion: WXEnvironment.osVersion,
                                deviceModel: WXEnvironment.deviceModel,
                                userAgent: this.appMessage.userAgent,
                            },
                            headers: {
                                token: this.appMessage.token,
                            }
                        }, result => {
                            console.log(result);
                        });
                    } else {
                        console.log("[UmengAlias] add error");
                    }
                    this.umengError = data.status !== 'success'
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
            if (param.act == 'invent') {
                this.inventEvent(param)
                return
            }
            const javascript = `if (typeof window.__onMeetingEvent === "function"){window.__onMeetingEvent({"uuid":"${param.uuid}","act":"${param.act}"})}`;
            this.$refs.web.setJavaScript(javascript);
        },

        /**
         * 邀请点击时与H5交互
         * @param param
         */
        inventEvent(param) {
            const javascript = `if (typeof window.__onMeetingEvent === "function"){window.__onMeetingEvent({"meetingid":"${param.meetingid}","act":"${param.act}"})}`;
            this.$refs.web.setJavaScript(javascript);
        },

        linkEvent(link) {
            const javascript = `if (typeof window.__handleLink === "function"){window.__handleLink("${link}")}`;
            this.$refs.web.setJavaScript(javascript);
        },
    }
}
</script>
