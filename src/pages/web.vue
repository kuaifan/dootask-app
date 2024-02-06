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
        <div v-if="moreShow===true" class="more" @click="moreShow=false">
            <icon class="more-top" content="tb-triangle-up-fill"/>
            <div class="more-box">
                <template v-if="browser">
                    <text class="more-item" @click="itemClick('browser')">{{moreBrowserText}}</text>
                    <div class="more-line"></div>
                </template>
                <text class="more-item" @click="itemClick('refresh')">{{moreRefreshText}}</text>
            </div>
        </div>
    </div>
</template>

<style scoped>
.flex {
    flex: 1;
}
.more {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    align-items: flex-end;
    background-color: rgba(0, 0, 0, 0);
}
.more-top {
    width: 40px;
    height: 40px;
    margin-top: 2px;
    margin-right: 30px;
    color: #464646;
    font-size: 30px;
}
.more-box {
    position: absolute;
    top: 26px;
    right: 16px;
    width: 264px;
    border-radius: 12px;
    background-color: #464646;
}
.more-item {
    height: 76px;
    font-size: 26px;
    line-height: 76px;
    text-align: center;
    color: #ffffff;
}
.more-line {
    width: 264px;
    height: 1px;
    background-color: #333333;
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

            moreShow: false,
            moreBrowserText: eeui.getVariate("languageWebBrowser", "浏览器打开"),
            moreRefreshText: eeui.getVariate("languageWebRefresh", "刷新"),

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
                icon: 'ios-arrow-back',
                iconSize: 40,
                iconColor: this.navColor,
                width: 110,
            }, _ => {
                eeui.closePage();
            })
            navigationBar.setTitle({
                titleColor: this.navColor,
            })
            navigationBar.setRightItem({
                icon: 'ios-more',
                iconSize: 40,
                iconColor: this.navColor,
                width: 120,
            }, _ => {
                this.moreShow = !this.moreShow;
            })
        },

        /**
         * 更多按钮点击
         * @param action
         */
        itemClick(action) {
            switch (action) {
                case 'browser':
                    if (this.url) {
                        eeui.openWeb(this.url);
                    }
                    break;

                case 'refresh':
                    this.$refs.web.setUrl(this.url);
                    break;
            }
            this.moreShow = false;
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
