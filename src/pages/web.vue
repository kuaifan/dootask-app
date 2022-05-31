<template>
    <div class="flex">
        <navbar class="navbar">
            <navbar-item type="left">
                <icon :content="backIcon" class="icon" @click="close"></icon>
            </navbar-item>
            <navbar-item type="title">
                <text class="text">{{webTitle}}</text>
            </navbar-item>
            <navbar-item type="right">
                <icon :content="browserIcon" class="icon" @click="browser"></icon>
            </navbar-item>
        </navbar>
        <web-view ref="web" class="flex" @stateChanged="onStateChanged"/>
    </div>
</template>

<style scoped>
.flex {
    flex: 1;
}
.navbar {
    width: 750px;
    height: 90px;
    background-color: #f8f8f8;
}
.icon {
    width: 90px;
    height: 90px;
    font-size: 40px;
    color: #333333;
}
.text {
    width: 550px;
    font-size: 32px;
    text-align: center;
    text-overflow: ellipsis;
    lines: 1;
}
</style>
<script>
const eeui = app.requireModule('eeui');

export default {
    data() {
        return {
            backIcon: WXEnvironment.platform === 'iOS' ? 'ios-arrow-back' : 'md-arrow-back',
            browserIcon: WXEnvironment.platform === 'iOS' ? 'ios-share-alt' : 'md-share-alt',
            title: null,
            url: null,
        }
    },

    mounted() {
        eeui.setStatusBarStyle(false)
        this.url = app.config.params.url;
        this.$refs.web.setUrl(this.url);
    },

    computed: {
        webTitle() {
            if (this.title === null) {
                return 'Loading'
            }
            return this.title || ''
        }
    },

    methods: {
        close() {
            eeui.closePage();
        },

        browser() {
            eeui.openWeb(this.url);
        },

        onStateChanged(info) {
            switch (info.status) {
                case 'title':
                    this.title = info.title;
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
