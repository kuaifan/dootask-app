<template>
    <div class="flex">
        <web-view
            ref="web"
            class="flex"
            :hiddenDone="true"
            :progressbarVisibility="false"
            :allowFileAccessFromFileURLs="true"
            @receiveMessage="onReceiveMessage"
            @stateChanged="onStateChanged"
            @ready="readyStatus"/>
        <meetings ref="meeting" @meetingEvent="meetingEvent"></meetings>
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
            webReady:false,

            uniqueId: '',
            resumeNum: 0,

            umengInit: false,
            umengMessage: {},
            umengError: false,

            appGroupID: "group.im.dootask", // iOS共享储存的应用唯一标识符
            appSubPath: "share", //iOS 储存下一级目录
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
                console.log('link：', message.jumpUrl);

                if (this.webReady) {
                    this.linkEvent(message.jumpUrl)
                } else {
                    setTimeout(()=>{
                        // 延迟执行
                        this.linkEvent(message.jumpUrl)
                    }, 2000)
                }

        }
    },

    mounted() {
        // iOS初始化共享内存
        if (WXEnvironment.platform.toLowerCase() === "ios") {
            shareFile.shareFileWithGroupID(this.appGroupID, this.appSubPath);
        }

        this.uniqueId = eeui.getCachesString("appUniqueId", "");
        if (this.count(this.uniqueId) < 5) {
            this.uniqueId = this.randomString(6);
            eeui.setCachesString("appUniqueId", this.uniqueId, 0);
        }

        // this.$refs.web.setUrl("http://192.168.0.111:2222");
        // this.$refs.web.setUrl("http://192.168.100.36:2222");
        this.$refs.web.setUrl(eeui.rewriteUrl('../public/index.html'));
        // 安卓拦截返回时间变成web返回事件
        eeui.setPageBackPressed({
            pageName: 'firstPage',
        }, () =>{
            //返回键触发事件

            this.$refs.web.canGoBack(res=>{
                if (res) {
                    this.$refs.web.goBack();
                } else {
                    eeui.goDesktop();
                }
            })
        });
    },

    methods: {
        /**
         * 获取时间戳
         * @returns {number}
         */
        time() {
            return Math.round(new Date().getTime() / 1000)
        },

        /**
         * webView准备好了
         *
         */
        readyStatus(){
            // this.webReady = true;
        },

        /**
         * 来自网页的消息
         * @param message
         */
        onReceiveMessage({message}) {
            switch (message.action) {
                case 'intiUmeng':
                    if (!this.umengInit) {
                        this.umengInit = true;
                        umengPush.initialize();
                    }
                    break;

                case 'setUmengAlias':
                    this.umengMessage = message;
                    this.webReady = true;
                    this.updateUmengAlias();
                    break;

                case 'setVibrate':
                    const time = this.runNum(message.time);
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
                    notifications.setBadge(this.runNum(message.bdage));
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
                    eeui.setStatusBarStyle(message.themeName === 'dark')
                    eeui.setStatusBarColor(message.themeName === 'dark' ? '#131313' : '#f8f8f8')
                    eeui.setBackgroundColor(message.themeName === 'dark' ? '#131313' : '#f8f8f8')
                    eeui.setCachesString("themeName", message.themeName, 0)
                    break
            }
        },

        onStateChanged({status, url}) {
            switch (status) {
                case 'createTarget':
                    eeui.openPage({
                        pageType: 'app',
                        pageTitle: ' ',
                        url: 'web.js',
                        params: {
                            url,
                            browser: true,
                            showProgress: true,
                        },
                    }, function (result) {
                        //......
                    });
                    break;
            }
        },

        updateUmengAlias() {
            const alias = `${WXEnvironment.platform}-${this.umengMessage.userid}-${this.uniqueId}`;
            //
            console.log("[UmengAlias] delete: " + alias);
            umengPush.deleteAlias(alias, "userid", data => {
                console.log("[UmengAlias] delete result: " + JSON.stringify(data));
                //
                console.log("[UmengAlias] add: " + alias);
                umengPush.addAlias(alias, "userid", data => {
                    console.log("[UmengAlias] add result: " + JSON.stringify(data));
                    if (data.status === 'success') {
                        console.log("[UmengAlias] add success");
                        // 别名保存到服务器
                        eeui.ajax({
                            url: this.umengMessage.url,
                            method: 'get',
                            data: {
                                alias,
                            },
                            headers: {
                                token: this.umengMessage.token,
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
                const javascript = `if (typeof window.__onPagePause === "function"){window.__onNotificationPermissionStatus(${ret})}`;
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
