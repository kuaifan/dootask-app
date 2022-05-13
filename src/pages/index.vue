<template>

    <div class="app">

        <!-- 顶部导航 -->
        <div class="nav">
            <text class="nav-title">{{title}}</text>
        </div>

        <!-- 页面内容 -->
        <scroller class="app">
            <text class="app-desc">{{desc}}</text>
        </scroller>

    </div>

</template>

<style scoped>
    .app {
        flex: 1;
    }
    .nav {
        width: 750px;
        height: 96px;
        display: flex;
        background-color: #3EB4FF;
    }
    .nav-title {
        flex: 1;
        color: #ffffff;
        text-align: center;
        line-height: 96px;
        font-size: 32px;
        font-weight: 300;
    }
    .app-desc {
        padding: 24px;
        font-size: 36px;
    }
</style>
<script>
    const eeui = app.requireModule('eeui');

    export default {
        data() {
            return {
                title: 'Hello, World!',
                desc: 'Hello, World!  Hello, EEUI! '
            }
        },

        appActive(data) {
            //APP进入前台：App从【后台】切换至【前台】时触发
        },

        appDeactive(data) {
            //APP进入后台：App从【前台】切换至【后台】时触发
        },

        pageReady(data) {
            //页面挂载：页面【渲染完成】时触发
        },
        
        pageResume(data) {
            //页面激活：页面【恢复】时触发（渲染完成时也会触发1次）
        },

        pagePause(data) {
            //页面失活：页面【暂停】时触发
        },

        pageDestroy(data) {
            //页面停止：页面【销毁】时触发
        },

        mounted() {
            
        },

        methods: {
            /**
             * 打开新页面
             * @param jsPageName    (String)JS页面名称
             * @param params        (Object)传递参数
             */
            goForward(jsPageName, params) {
                eeui.openPage({
                    url: str + ".js",
                    pageType: "app",
                    statusBarColor: "#3EB4FF",
                    params: params ? params : {}
                });
            },

            /**
             * 返回上一页(关闭当前页)
             */
            goBack() {
                eeui.closePage();
            },
        }
    }
</script>
