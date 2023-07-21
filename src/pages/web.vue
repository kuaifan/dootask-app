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

    // APP进入前台：App从【后台】切换至【前台】时触发
    appActive() {
        this.updateStatusBar()
    },

    // 页面激活：页面【恢复】时触发（渲染完成时也会触发1次）
    pageResume() {
        this.updateStatusBar()
    },

    mounted() {
        this.$refs.web.setUrl(this.url);
    },

    methods: {
        /**
         * 更新状态栏
         */
        updateStatusBar() {
            const name = eeui.getThemeName()
            if (this.themeName !== name) {
                this.themeName = name
                //
                eeui.setStatusBarStyle(name === 'dark')
                eeui.setStatusBarColor(name === 'dark' ? '#1a1a1a' : '#f8f8f8')
                eeui.setBackgroundColor(name === 'dark' ? '#1a1a1a' : '#f8f8f8')
                //
                const javascript = `if (typeof window.__onThemeChange === "function"){window.__onThemeChange("${name}")}`;
                this.$refs.web.setJavaScript(javascript);
                //
                this.navColor = name === 'dark' ? '#cdcdcd' : '#232323'
                navigationBar.setLeftItem({
                    icon: 'tb-back',
                    iconColor: this.navColor,
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
