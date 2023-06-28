<template>
    <div class="mask" v-if="showShow" :style="videoStyle" @click="zoomClick(false)">
        <div style="padding: 16px; flex:1;background-color: #00A77D;">
            <div class="render-views">
                <div class="grid-item" v-for="item in uuids">
                    <eeuiAgoro-com class="local" ref="local" :uuid="item.uuid" @load="load"></eeuiAgoro-com>
<!--                    <image class="mute" :src="item.mute?'root://assets/mute_on@2x.png':'root://assets/mute_off@2x.png'" @click="remoteSlicent(item)"></image>-->
<!--                    <image class="mute" :src="item.video?'root://assets/mute_on@2x.png':'root://assets/mute_off@2x.png'" @click="remoteVideo(item)"></image>-->
                </div>
            </div>

            <div style="flex: 1;"></div>

            <div style="flex-wrap: wrap;flex-direction: row; background-color: #0a3069;">
<!--                <div class="button" @click="joint">-->
<!--                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_video_off.png"></image>-->
<!--                </div>-->
                <div class="button" @click="videoEnable">
                    <image style="width:40px;height: 40px;" :src="video? 'root://pages/assets/images/meeting_video_on.png':'root://pages/assets/images/meeting_video_off.png'"></image>
                </div>
                <div class="button" @click="audioEnable">
                    <image style="width:40px;height: 40px;" :src="audio? 'root://pages/assets/images/meeting_audio_on.png':'root://pages/assets/images/meeting_audio_off.png'"></image>
                </div>
                <div class="button" @click="invent">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_invent.png"></image>
                </div>
                <div class="button" @click="hideClicked">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_mini.png"></image>
                </div>
<!--                exitAction-->
                <div class="button" :style="{backgroundColor:'yellow'}" @click="exitAction">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_exit.png"></image>
                </div>
            </div>

            <div style="flex-direction: row; position: absolute; justify-content: right; background-color: white; top: 0;left: 0;right: 0;bottom: 0;" v-if="mini">
                <div style="padding: 12px;align-self: center;">
                    <image style="width:40px;height: 40px;" :src="video? 'root://pages/assets/images/meeting_black_video_on.png':'root://pages/assets/images/meeting_black_video_off.png'"></image>
                </div>
                <div style="padding: 12px;align-self: center;">
                    <image style="width:40px;height: 40px;align-self: center" :src="audio? 'root://pages/assets/images/meeting_black_audio_on.png':'root://pages/assets/images/meeting_black_audio_off.png'"></image>
                </div>
                <div style="padding: 12px;align-self: center;">
                    <text style="align-self: center">{{"会议中"}}</text>
                </div>

            </div>
        </div>
    </div>
</template>

<style scoped>
.mask {
    position: fixed;
    overflow: hidden;
    background-color: white;
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
    width: 350px;
    height: 350px;
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
    width: 350px;
    height: 350px;
    border-width: 3px;
    border-color: blue;

}
.button {
    margin-left: 15px;
    /*border-width: 1px;*/
    /*border-color: rgb(20, 172, 78);*/
    background-color: rgb(20, 172, 78);
    padding: 12px 32px;
    border-radius: 8px;
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
    name:"meetings",
    data() {
        return {
            title: "Hello, World!",
            uuids:[],
            uuid:0,
            mini:false,
            showShow: false,
            video:false,
            audio:false
        };
    },

    computed:{
        videoStyle(){
            let style = {}
            if (this.mini) {
                style.width = "300px";
                style.height = "100px";
                style.right = "0px";
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
                if (statsParam.uuid === "me") {
                    // 本地状态回调
                    if (statsParam.type === "video"){
                        if (this.uuids[0]) this.uuids[0].video = statsParam.status == 1;
                    } else  {
                        if (this.uuids[0]) this.uuids[0].audio = statsParam.status == 1;
                    }
                } else {
                    // 其他状态回调
                    let uuid = statsParam.uuid
                    this.uuids = this.uuids.map(item =>{
                        if(item.uuid == uuid) {
                            if (statsParam.type === "video"){
                                return item.video = statsParam.status == 1;
                            } else  {
                                return item.audio = statsParam.status == 1;
                            }

                        }else  {
                            return item
                        }
                    })
                }

            });
            agoro.localStatusCallback((stats)=>{
                // console.info("leaveRoom");

                if(stats == -1){
                    this.destroyed();
                    this.uuids = [];
                }
            });
        },

        destroyed() {
            agoro.destroy()
            this.showShow = false
            this.$emit("endMeeting",'')
        },

        exitAction() {
            agoro.leaveChannel();
        },

        joint(param){

            param = {
                token: "007eJxSYHB1ZDm6ZefX4G+7EyYri6bse6e01/mQaavpi3k/X90vZTunwGBsYpRsZmBiamJkYmGSZJBiaWZqaWpknmZumZialpySZPFodkqDERMD3+P5jIwMjAwsDIwMID4TmGQGkyxgkpWhJLW4xJCBARAAAP//KYwjNg==",
                channel:"test1",
                uuid: "0",
                appid:"342c604542484b0d9659527f79aefcdb",
                video:true,
                audio:true,
            }

            let appid = param.appid;
            console.info("param",param);
            this.initAgoro(appid)
            param.uuid = param.uid

            this.video = param.video;
            this.audio = param.audio;

            agoro.jointChanel(param, (info)=>{
                this.showShow = true;
                this.mini = false;
                this.uuid = info.uuid;
                this.uuids.push({
                    uuid: this.uuid,
                    audio: param.audio,
                    video: param.video
                })
                this.$nextTick(()=>{
                    agoro.enableVideo(param.video)
                    agoro.enableAudio(param.audio)
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

        videoEnable() {
            this.video = !this.video
            agoro.enableVideo(this.video)
        },

        audioEnable() {
            this.audio = !this.audio
            agoro.enableAudio(this.video)
        },

        invent() {

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
