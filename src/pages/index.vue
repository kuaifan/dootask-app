<template>
    <div class="app">
        <web-view
            ref="web"
            class="web"
            :hiddenDone="true"
            :progressbarVisibility="false"
            @receiveMessage="onReceiveMessage"/>
    </div>
</template>

<style scoped>
.app,
.web {
    flex: 1;
}
</style>
<script>
const eeui = app.requireModule('eeui');
const umengPush = app.requireModule("eeui/umengPush");

export default {
    data() {
        return {
            uniqueId: '',
            resumeNum: 0,
        }
    },

    pageResume() {
        const javascript = `if (typeof window.__onPageResume === "function"){window.__onPageResume(${this.resumeNum})}`;
        this.$refs.web.setJavaScript(javascript);
        this.resumeNum++;
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
        }
    },

    mounted() {
        this.uniqueId = eeui.getCachesString("appUniqueId", "");
        if (this.count(this.uniqueId) < 5) {
            this.uniqueId = this.randomString(6);
            eeui.setCachesString("appUniqueId", this.uniqueId, 0);
        }
        //
        eeui.setStatusBarStyle(false)
        // this.$refs.web.setUrl("http://192.168.0.111:2222");
        // this.$refs.web.setUrl("http://192.168.200.120:2222");
        this.$refs.web.setUrl(eeui.rewriteUrl('../public/index.html'));
    },

    computed: {

    },

    methods: {
        /**
         * 来自网页的消息
         * @param message
         */
        onReceiveMessage({message}) {
            if (message.action === 'setUmengAlias') {
                const alias = `${WXEnvironment.platform}-${message.userid}-${this.uniqueId}`;
                umengPush.addAlias(alias, "userid", ({status}) => {
                    if (status === 'success') {
                        // 别名保存到服务器
                        eeui.ajax({
                            url: message.url,
                            method: 'get',
                            data: {
                                alias,
                            },
                            headers: {
                                token: message.token,
                            }
                        }, result => {
                            console.log(result);
                        });
                    }
                });
            }
        }
    }
}
</script>
