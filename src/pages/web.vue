<template>
    <web-view
        ref="web"
        class="flex"
        :allowFileAccessFromFileURLs="allowAccess"
        :progressbarVisibility="showProgress"
        @receiveMessage="onReceiveMessage"
        @stateChanged="onStateChanged"/>
</template>

<style scoped>
.flex {
    flex: 1;
}
</style>
<script>
const eeui = app.requireModule('eeui');
const picture = app.requireModule("eeui/picture");
const navigationBar = app.requireModule('navigationBar');

export default {
    data() {
        return {
            url: app.config.params.url,
            browser: !!app.config.params.browser,
            titleFixed: !!app.config.params.titleFixed,
            showProgress: !!app.config.params.showProgress,
            allowAccess: !!app.config.params.allowAccess,

            navColor: "",
            themeName: "", // 主题名称
        }
    },

    mounted() {
        this.initTheme();
        this.$refs.web.setUrl(this.url);
    },

    methods: {
        /**
         * 初始化主题
         */
        initTheme() {
            const themeName = eeui.getCachesString("themeName", "")
            eeui.setStatusBarStyle(themeName === 'dark')
            eeui.setStatusBarColor(themeName === 'dark' ? '#1a1a1a' : '#f8f8f8')
            eeui.setBackgroundColor(themeName === 'dark' ? '#1a1a1a' : '#f8f8f8')
            //
            this.navColor = themeName === 'dark' ? '#cdcdcd' : '#232323'
            navigationBar.setLeftItem({
                icon: 'tb-back',
                iconSize: 40,
                iconColor: this.navColor,
                width: 120,
            }, _ => {
                eeui.closePage();
            })
            navigationBar.setTitle({
                titleColor: this.navColor,
            })
            if (this.browser) {
                navigationBar.setRightItem({
                    icon: WXEnvironment.platform === 'iOS' ? 'ios-share-alt' : 'md-share-alt',
                    iconSize: 40,
                    iconColor: this.navColor,
                    width: 120,
                }, _ => {
                    if (this.url) {
                        eeui.openWeb(this.url);
                    }
                })
            }
        },

        /**
         * 来自网页的消息
         * @param message
         */
        onReceiveMessage({message}) {
            switch (message.action) {
                case 'picturePreview':
                    picture.picturePreview(message.position, message.paths)
                    break;

                case 'videoPreview':
                    picture.videoPreview(message.path)
                    break;
            }
        },

        onStateChanged(info) {
            switch (info.status) {
                case 'title':
                    if (!this.titleFixed) {
                        if (["HitoseaTask", "DooTask", "about:blank"].includes(info.title)) {
                            return
                        }
                        navigationBar.setTitle({
                            title: info.title,
                            titleColor: this.navColor,
                        })
                    }
                    break;

                case 'url':
                    this.url = info.url;
                    break;

                case 'createTarget':
                    this.$refs.web.setUrl(info.url);
                    break;
            }
        }
    }
}
</script>
