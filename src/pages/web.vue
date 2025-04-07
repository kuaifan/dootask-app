<template>
    <div class="flex" :style="warpStyle">
        <web-view
            ref="web"
            class="flex"
            :hiddenDone="hiddenDone"
            :transparency="true"
            :allowFileAccessFromFileURLs="allowAccess"
            :progressbarVisibility="showProgress"
            @receiveMessage="onReceiveMessage"
            @stateChanged="onStateChanged"/>
        <div v-if="moreShow===true" class="more" @click="moreShow=false">
            <icon class="more-top" :style="moreTopStyle" content="tb-triangle-up-fill"/>
            <div class="more-box" :style="moreBoxStyle">
                <template v-if="canGoBack">
                    <text class="more-item" :style="moreItemStyle" @click="itemClick('back')">{{moreBackText}}</text>
                    <div class="more-line" :style="moreLineStyle"></div>
                </template>
                <template v-if="canGoForward">
                    <text class="more-item" :style="moreItemStyle" @click="itemClick('forward')">{{moreForwardText}}</text>
                    <div class="more-line" :style="moreLineStyle"></div>
                </template>
                <template v-if="browser">
                    <text class="more-item" :style="moreItemStyle" @click="itemClick('browser')">{{moreBrowserText}}</text>
                    <div class="more-line" :style="moreLineStyle"></div>
                </template>
                <text class="more-item" :style="moreItemStyle" @click="itemClick('refresh')">{{moreRefreshText}}</text>
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
    color: #464646;
}
.more-box {
    position: absolute;
    background-color: #464646;
}
.more-item {
    text-align: center;
    color: #ffffff;
}
.more-line {
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
            urlFixed: !!app.config.params.urlFixed,
            showProgress: !!app.config.params.showProgress,
            allowAccess: !!app.config.params.allowAccess,
            hiddenDone: !!app.config.params.hiddenDone,
            canGoBack: false,
            canGoForward: false,

            windowWidth: parseInt(eeui.getVariate("windowWidth", "0")) || 430,

            moreShow: false,
            moreBackText: eeui.getCachesString("languageWebBack", "后退"),
            moreForwardText: eeui.getCachesString("languageWebForward", "前进"),
            moreBrowserText: eeui.getCachesString("languageWebBrowser", "浏览器打开"),
            moreRefreshText: eeui.getCachesString("languageWebRefresh", "刷新"),

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
            systemTheme: eeui.getThemeName(),   // 系统主题

            allowedUrls: /^(?:https?|mailto|tel|callto):/i,
        }
    },

    mounted() {
        this.initTheme(null);
        this.initNav();
        this.$refs.web.setUrl(this.url);
    },

    computed: {
        miniRate() {
            return Math.min(2, Math.max(1, this.windowWidth / 430));
        },

        warpStyle() {
            if (this.themeColor) {
                return {
                    backgroundColor: this.themeColor,
                }
            }
            return {}
        },

        moreTopStyle() {
            return {
                width: this.scaleSize(40),
                height: this.scaleSize(40),
                marginTop: this.scaleSize(2),
                marginRight: this.scaleSize(30),
                fontSize: this.scaleSize(30),
            }
        },

        moreBoxStyle() {
            return {
                top: this.scaleSize(26),
                right: this.scaleSize(16),
                width: this.scaleSize(264),
                borderRadius: this.scaleSize(12),
            }
        },

        moreLineStyle() {
            return {
                width: this.scaleSize(264),
                height: this.scaleSize(1),
            }
        },

        moreItemStyle() {
            return {
                height: this.scaleSize(76),
                fontSize: this.scaleSize(26),
                lineHeight: this.scaleSize(76),
            }
        }
    },

    methods: {
        scaleSize(current) {
            return (current / this.miniRate) + 'px';
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
            this.themeColor = this.themeDefault.theme[themeName]
            this.navColor = this.themeDefault.nav[themeName]
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
            }, async () => {
                this.canGoBack = await new Promise(resolve => this.$refs.web.canGoBack(resolve));
                this.canGoForward = await new Promise(resolve => this.$refs.web.canGoForward(resolve));
                this.moreShow = !this.moreShow;
            })
        },

        /**
         * 更多按钮点击
         * @param action
         */
        itemClick(action) {
            switch (action) {
                case 'back':
                    this.$refs.web.goBack(async () => {
                        this.canGoBack = await new Promise(resolve => this.$refs.web.canGoBack(resolve));
                    });
                    break;
                case 'forward':
                    this.$refs.web.goForward(async () => {
                        this.canGoForward = await new Promise(resolve => this.$refs.web.canGoForward(resolve));
                    });
                    break;
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

                case 'setPageData':
                    for (let key in message.data) {
                        this[key] = message.data[key];
                    }
                    break;

                case 'createTarget':
                    if (!this.allowedUrls.test(message.url)) {
                        return;
                    }
                    this.$refs.web.setUrl(message.url);
                    break;

                case 'openUrl':
                    eeui.openWeb(message.url);
                    break;

                case 'windowSize':
                    this.windowWidth = parseInt(message.width) || 0
                    eeui.setVariate("windowWidth", this.windowWidth)
                    break;
            }
        },

        onStateChanged(info) {
            switch (info.status) {
                case 'title':
                    if (!this.titleFixed) {
                        if (["HitoseaTask", "DooTask", "about:blank", "App"].includes(info.title)) {
                            return
                        }
                        navigationBar.setTitle({
                            title: info.title,
                            titleColor: this.navColor,
                        })
                    }
                    break;

                case 'url':
                    if (!this.urlFixed) {
                        this.url = info.url;
                    }
                    break;

                case 'createTarget':
                    if (!this.allowedUrls.test(info.url)) {
                        return;
                    }
                    this.$refs.web.setUrl(info.url);
                    break;
            }
        }
    }
}
</script>
