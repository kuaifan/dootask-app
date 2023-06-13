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
    </div>
</template>

<style scoped>
.flex {
    flex: 1;
}
</style>
<script>
const eeui = app.requireModule('eeui');
const deviceInfo = app.requireModule("eeui/deviceInfo");
const umengPush = app.requireModule("eeui/umengPush");
const communication = app.requireModule("eeui/communication");
const notifications = app.requireModule("eeui/notifications");
const picture = app.requireModule("eeui/picture");
const shareFile = app.requireModule("eeuiShareFiles");

export default {
    data() {
        return {
            uniqueId: '',
            resumeNum: 0,

            umengInit: false,
            umengMessage: {},
            umengError: false,
            appGroupID:"group.im.dootask", // iOS共享储存的应用唯一标识符
            appSubPath:"share" //iOS 储存下一级目录
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
        //     // this.onReceiveMessage(123)
        //     let message = {
        //         action:"userUploadUrl",
        //         url:"http://www.google.com",
        //     }
        //
        //     this.onReceiveMessage({
        //         message
        //     })
        //
        // },2000)
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
        }
    }
}
</script>
