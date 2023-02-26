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
            allowAccess: !!app.config.params.allowAccess
        }
    },

    mounted() {
        eeui.setStatusBarStyle(false)
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
