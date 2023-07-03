<template>
    <div class="flex">
        <web-view
            ref="web"
            class="flex"
            :hiddenDone="true"
            :progressbarVisibility="false"
            :allowFileAccessFromFileURLs="true"
            @receiveMessage="onReceiveMessage"
            @stateChanged="onStateChanged"/>
        <meetings ref="meeting" @endMeeting="endMeeting"></meetings>
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
            uniqueId: '',
            resumeNum: 0,

            umengInit: false,
            umengMessage: {},
            umengError: false,
            screenHeight:0,
            appGroupID:"group.im.dootask", // iOS共享储存的应用唯一标识符
            appSubPath:"share", //iOS 储存下一级目录
        }
    },

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

    pagePause() {
        const javascript = `if (typeof window.__onPagePause === "function"){window.__onPagePause()}`;
        this.$refs.web.setJavaScript(javascript);
    },

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
        }
    },

    mounted() {
        this.screenHeight = WXEnvironment.deviceHeight

        // iOS初始化共享内存
        if (WXEnvironment.platform.toLowerCase() === "ios") {
            shareFile.shareFileWithGroupID(this.appGroupID,this.appSubPath);
        }

        this.uniqueId = eeui.getCachesString("appUniqueId", "");
        if (this.count(this.uniqueId) < 5) {
            this.uniqueId = this.randomString(6);
            eeui.setCachesString("appUniqueId", this.uniqueId, 0);
        }
        //
        eeui.setStatusBarStyle(false)
        // this.$refs.web.setUrl("http://192.168.0.111:2222");
        // this.$refs.web.setUrl("http://192.168.100.36:2222");
        this.$refs.web.setUrl(eeui.rewriteUrl('../public/index.html'));

        // setTimeout(()=>{
        //     let param = {
        //         token: "007eJxSYHB1ZDm6ZefX4G+7EyYri6bse6e01/mQaavpi3k/X90vZTunwGBsYpRsZmBiamJkYmGSZJBiaWZqaWpknmZumZialpySZPFodkqDERMD3+P5jIwMjAwsDIwMID4TmGQGkyxgkpWhJLW4xJCBARAAAP//KYwjNg==",
        //         channel:"test1",
        //         uuid: "0",
        //         appid:"342c604542484b0d9659527f79aefcdb",
        //         video:true,
        //         audio:true,
        //     }
        //     this.$refs.meeting && this.$refs.meeting.joint(param)
        // },12000)
    },

    computed: {

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
                        shareFile.setShareStorage('chatList',message.url)
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
        /**
         *  结束会议
         */
        endMeeting(){
            // const javascript = `if (typeof window.__onPageResume === "function"){window.__onPageResume(${this.resumeNum})}`;
            // this.$refs.web.setJavaScript(javascript);
        }
    }
}
</script>
