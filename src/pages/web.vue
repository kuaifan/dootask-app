<template>
    <div class="flex" :style="warpStyle">
        <web-view
            ref="web"
            class="flex"
            :transparency="true"
            :allowFileAccessFromFileURLs="allowAccess"
            :progressbarVisibility="showProgress"
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

            navColor: null,                     // 导航栏颜色
            themeColor: null,                   // 主题颜色
            systemTheme: eeui.getThemeName(),   // 系统主题
        }
    },

    mounted() {
        this.initTheme(null);
        this.initNav();
        this.$refs.web.setUrl(this.url);
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
            this.themeColor = themeName === 'dark' ? '#131313' : '#f8f8f8'
            this.navColor = themeName === 'dark' ? '#cdcdcd' : '#232323'
            eeui.setStatusBarStyle(themeName === 'dark')
            eeui.setStatusBarColor(this.themeColor)
            eeui.setBackgroundColor(this.themeColor)
        },

        /**
         * 初始化导航栏
         */
        initNav() {
            navigationBar.setLeftItem({
                icon: 'tb-back',
                iconSize: 36,
                iconColor: this.navColor,
                width: 110,
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
