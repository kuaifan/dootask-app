<template>
    <web-view
        ref="web"
        class="flex"
        :progressbarVisibility="showProgress"
        @stateChanged="onStateChanged"/>
</template>

<style scoped>
.flex {
    flex: 1;
}
</style>
<script>
const eeui = app.requireModule('eeui');
const navigationBar = app.requireModule('navigationBar');

export default {
    data() {
        return {
            url: null,
            browser: false,
            titleFixed: false,
            showProgress: false,
        }
    },

    mounted() {
        eeui.setStatusBarStyle(false)
        //
        this.url = app.config.params.url;
        this.browser = !!app.config.params.browser;
        this.titleFixed = !!app.config.params.titleFixed;
        this.showProgress = !!app.config.params.showProgress;
        //
        if (this.browser) {
            navigationBar.setRightItem({
                icon: WXEnvironment.platform === 'iOS' ? 'ios-share-alt' : 'md-share-alt',
                iconSize: 40,
                width: 120,
            }, _ => {
                if (this.url) {
                    eeui.openWeb(this.url);
                }
            })
        }
        this.$refs.web.setUrl(this.url);
    },

    methods: {
        onStateChanged(info) {
            switch (info.status) {
                case 'title':
                    if (!this.titleFixed) {
                        navigationBar.setTitle({
                            title: info.title,
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
