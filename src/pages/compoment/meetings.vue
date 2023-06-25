<template>
    <div class="mask" v-if="showShow" :style="videoStyle" @click="zoomClick(false)">
        <div style="padding: 16px;">
            <div class="render-views">
                <div class="grid-item" v-for="item in uuids">
                    <eeuiAgoro-com class="local" ref="local" :uuid="item.uuid" @load="load"></eeuiAgoro-com>
                    <image class="mute" :src="item.mute?'root://assets/mute_on@2x.png':'root://assets/mute_off@2x.png'" @click="remoteSlicent(item)"></image>
                    <image class="mute" :src="item.video?'root://assets/mute_on@2x.png':'root://assets/mute_off@2x.png'" @click="remoteVideo(item)"></image>
                </div>
            </div>

            <div style="flex: 1;"></div>

            <div style="flex-wrap: wrap;flex-direction: row;">
                <div class="button" @click="jointClicked">
                    <text class="content">加入房间</text>
                </div>
                <div class="button" @click="switchClicked">
                    <text class="content">切换摄像头</text>
                </div>
                <div class="button" @click="silenceClicked">
                    <text class="content">静音</text>
                </div>
                <div class="button" @click="loudlyClicked">
                    <text class="content">扬声器</text>
                </div>
                <div class="button" @click="shutClicked">
                    <text class="content">闭麦</text>
                </div>
                <div class="button" @click="hideClicked">
                    <text class="content">隐藏</text>
                </div>
            </div>

        </div>

    </div>
</template>

<style scoped>
.mask {
    position: fixed;
    overflow: hidden;
}
.render-views {
    flex-wrap: wrap;
    flex-direction:row;
}
.grid {
    width: 750px;
    height: 570px;
}
.grid-item {
    width: 230px;
    height: 280px;
    align-items: center;
}
.remote {
    margin-top: 50px;
    margin-left: 400px;
    width: 300px;
    height: 300px;
    align-items: center;
    position: absolute;

}

.items{
    margin-top: 10px;
    margin-left: 0px;
}
.local {
    width: 230px;
    height: 230px;
    border-width: 3px;
    border-color: blue;

}
.button {
    align-self: center;
    margin-top: 1000px;
    margin-left: 15px;
    position: absolute;
    border-width: 1px;
    border-color: rgb(20, 172, 78);
    padding: 18px;
    border-radius: 40px;
}
.switch{
    margin-top: 850px;
    margin-left: -420px;
}
.silence {
    margin-top: 850px;
    margin-left: 0px;
}
.loudly {
    margin-top: 850px;
    margin-left: 320px;
}
.shut{
    margin-left: 420px;
}
.hide {
    margin-top: 1100px;
    margin-left: 100px;
}
.content {
    font-size: 40px;
    color: gray;
}
</style>

<script>
const agoro = app.requireModule("eeuiAgoro");
const eeui = app.requireModule("eeui")

export default {
    data() {
        return {
            title: "Hello, World!",
            uuids:[],
            uuid:0,
            mini:false,
            showShow: false,
        };
    },

    computed:{
        videoStyle(){
            let style = {}
            if (this.mini) {
                style.width = "400px";
                style.height = "100px";
                style.right = "10px";
                style.bottom = "100px";
            }else {
                style.top = "0px";
                style.bottom = "0px";
                style.right = "0px";
                style.left = "0px";
            }
            return style;
        }
    },
    watch:{
        uuids(){
            if(this.uuids.length == 1){
                this.$nextTick(()=>{

                })
            }
        }
    },
    methods:{
        /**
         *
         * @param appid
         */
        initAgoro(appid) {
            // 342c604542484b0d9659527f79aefcdb
            var param = eeui.getConfigString("agoro");
            var jsonOBJ = JSON.parse(param);

            agoro.initialWithParam({
                id: appid
            },(jointData)=>{
                let uuid = jointData.uuid;
                if (jointData.action == "joint") {
                    console.info("joint:"+ uuid);
                    var shouldAdd = true;
                    for (let index = 0; index < this.uuids.length; index++) {
                        const element = this.uuids[index];
                        if (element.uuid == uuid) {
                            shouldAdd = false;
                        }
                    }
                    if (shouldAdd == true) {
                        this.uuids.push({uuid:uuid, mute:false, video:true});
                    }
                    //

                } else if (jointData.action == "leave") {
                    console.info("leave:"+ uuid);
                    for (let index = 0; index < this.uuids.length; index++) {
                        const element = this.uuids[index];
                        if (element.uuid == uuid) {
                            this.uuids.splice(index, 1);
                        }
                    }
                }
            });
            agoro.statusCallback((statsParam)=>{
                console.info("statsParam:",statsParam);
                // console.info(statsParam);
            });
            agoro.localStatusCallback((stats)=>{
                console.info("leaveRoom");
                if(stats == -1){
                    this.uuids = [];
                }
            });
        },

        destroyed() {
            agoro.destroy()
            this.showShow = false
        },

        jointClicked(){
            this.initAgoro("342c604542484b0d9659527f79aefcdb")

            agoro.jointChanel({
                "token": "007eJxSYOA/pmF5IfWF7FLxx3e2fIw8zHR4Rtknn9NpKtuvHLtesP+XAoOxiVGymYGJqYmRiYVJkkGKpZmppamReZq5ZWJqWnJK0pvMiSkNRkwMZe2hjIwMjAwsDIwMID4TmGQGkyxgkpWhJLW4xJCBARAAAP//iTAkOA==",
                "channel":"test1",
                "uuid": "1",
            }, (info)=>{
                this.mini = false;
                this.uuid = info.uuid;
                this.uuids.push({
                    uuid: this.uuid,
                    mute:false,
                    video:true
                })

                console.info(info)
            })
        },
        zoomClick() {
            this.mini = false;
        },

        miniClick() {
            this.mini = true
        },

        switchClicked(){
            agoro.switchCamera()
        },

        silenceClicked(uids){
            // agoro.
            // agoro.silence(true);
        },
        remoteSlicent(item){
            agoro.muteRemoteAudioStream(item.uuids, !item.mute);
        },

        remoteVideo(item){
            agoro.muteRemoteVideoStream(item.uuids, !item.mute);
        },

        loudlyClicked(){

        },

        shutClicked(){
            agoro.leaveChannel();
        },
        hideClicked(){
            this.miniClick();
        },

        load(param){
            let uuid = param.target.attr.uuid;

            if (uuid == this.uuid) {
                agoro.blindLocal(this.uuids[0].uuid);
                return;
            }

            agoro.blindRemote(uuid);

            console.info("load:"+uuid);
            console.info(param);
        }
    },

}
</script>
