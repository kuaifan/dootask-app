<template>
    <div class="mask" v-if="showShow" :style="videoStyle" >
        <div style="padding: 16px; flex:1;background-color: white;">
            <text style="font-size: 30px; padding: 16px;">{{title}}</text>
            <div class="render-views">
                <div class="grid-item" v-for="item in uuids">
                    <div class="local hidden">
                        <eeuiAgoro-com class="local" ref="local" :uuid="item.uuid" @load="load"></eeuiAgoro-com>
                    </div>
                    <image v-if="item.videoStatus == 0" :src="item.avatar" style="position: absolute; top: 15px;left: 15px;right: 5px;bottom: 15px; border-radius: 16px;flex-direction: row; background-color: #00A77D;"></image>
                    <div style="position: absolute; top: 16px;right: 10px; flex-direction: row;" >
                        <image v-if="!item.video"  style="width:40px;height: 40px;margin-right: 12px;" :src="'root://pages/assets/images/meeting_video_err.png'"></image>
                        <image v-if="!item.audio"  style="width:40px;height: 40px;margin-right: 12px;" :src="'root://pages/assets/images/meeting_audio_err.png'"></image>
                    </div>

                    <div style="position: absolute; bottom: 0px; right: 0px; width: 80px; height: 80px; border-radius: 40px; background-color: white;overflow: hidden;">
                        <image style="width: 70px; height: 70px; margin-top: 5px; margin-left: 5px; border-radius: 35px; background-color: greenyellow;" :src="item.avatar"></image>
                    </div>
                    <div class="status-indicator" >
                        <div class="sub-status-indicator" :style="getStatus(item.audioStatus,item.videoStatus)"></div>
                    </div>
                </div>
            </div>

            <div style="flex: 1;"></div>

            <div style="flex-wrap: wrap;flex-direction: row; justify-content: space-between; background-color: white;">
                <div class="button" @click="videoEnable">
                    <image style="width:40px;height: 40px;" :src="video? 'root://pages/assets/images/meeting_video_on.png':'root://pages/assets/images/meeting_video_off.png'"></image>
                </div>
                <div class="button" @click="audioEnable">
                    <image style="width:40px;height: 40px;" :src="audio? 'root://pages/assets/images/meeting_audio_on.png':'root://pages/assets/images/meeting_audio_off.png'"></image>
                </div>
                <div class="button" @click="switchClicked">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_camera_reverse.png"></image>
                </div>
                <div class="button" @click="invent">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_invent.png"></image>
                </div>
                <div class="button" @click="hideClicked">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_mini.png"></image>
                </div>
<!--                exitAction-->
                <div class="button" :style="{backgroundColor:'#f28500'}" @click="exitAction">
                    <image style="width:40px;height: 40px;" src="root://pages/assets/images/meeting_exit.png"></image>
                </div>
            </div>

            <div style="flex-direction: row; position: absolute; justify-content: right; background-color: white; top: 0;left: 0;right: 0;bottom: 0;" v-if="mini" @click="zoomClick(false)" @touchstart="touchstart" @touchmove="touchAction" @touchend="touchend">
                <div style="padding: 12px;align-self: center; margin-left: 22px;">
                    <image style="width:40px;height: 40px;" :src="video? 'root://pages/assets/images/meeting_black_video_on.png':'root://pages/assets/images/meeting_black_video_off.png'"></image>
                </div>
                <div style="padding: 12px;align-self: center; margin-left: 4px;">
                    <image style="width:40px;height: 40px;align-self: center" :src="audio? 'root://pages/assets/images/meeting_black_audio_on.png':'root://pages/assets/images/meeting_black_audio_off.png'"></image>
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
    justify-content: space-between;
}
.grid-item {
    width: 350px;
    height: 350px;
    align-items: center;
}

.status-indicator {
    position: absolute;
    width: 20px;
    height: 20px;
    border-radius: 10px;
    bottom: 6px;
    right: 6px;
    background-color: white;
}

.sub-status-indicator {
    width: 16px;
    height: 16px;
    border-radius: 8px;
    margin-top: 2px;
    margin-left: 2px;
}

.local {
    width: 320px;
    height: 320px;
    border-radius: 16px;
    overflow: hidden;
}

.hidden {
    margin-top: 15px;
    margin-left: 15px;
    overflow: hidden;
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
            title: "",
            uuids:[],
            uuid:0,
            meetingid:0,
            mini:false,
            showShow: false,
            video:false,
            audio:false,
            infos:[],
            screenH:WXEnvironment.deviceHeight/WXEnvironment.deviceWidth *750 ,
            bottomPos:100,
            rightPos:0,
            isTouch:false,
            startPosX:0,
            startPosY:0,
        };
    },

    computed:{
        videoStyle(){
            let style = {}
            if (this.mini) {
                style.width = "182px";
                style.height = "80px";
                style.right = this.rightPos+"px";
                style.bottom = this.bottomPos+"px";
                style.borderRadius = "8px";
                style.borderWidth = "2px";
                style.borderColor = "#D9E2E9";
            }else {
                style.top = "0px";
                style.bottom = "0px";
                style.right = "0px";
                style.left = "0px";
            }
            return style;
        },

    },
    methods:{
        /**
         *
         * @param appid
         */
        initAgoro(appid) {
            agoro.initialWithParam({
                id: appid
            },(jointData)=>{
                let uuid = jointData.uuid;
                if (jointData.action == "joint") {
                    // console.info("joint:"+ uuid);
                    // console.info("jointData:"+ uuid);
                    var shouldAdd = true;
                    let avatar = ""
                    for (let index = 0; index < this.uuids.length; index++) {
                        const element = this.uuids[index];
                        if (element.uuid == uuid) {
                            shouldAdd = false;
                        }
                    }
                    this.infos.map((item)=>{
                        if (item.uuid == this.uuids) {
                            avatar = item.avatar;
                        }
                        return item
                    })
                    if (shouldAdd == true) {
                        this.uuids.push({
                            uuid:uuid,
                            audio:false,
                            video:false,
                            videoStatus:0,
                            audioStatus:0,
                            avatar:avatar
                        });
                        this.infoParam(uuid);
                    }

                } else if (jointData.action == "leave") {
                    // console.info("leave:"+ uuid);
                    // console.info(this.uuids);
                    this.uuids = this.uuids.filter(item=>{
                        return item.uuid != uuid;
                    })
                    // console.info(this.uuids);
                }
            });
            agoro.statusCallback((statsParam)=>{
                console.info("statsParam:",statsParam);
                // console.info(statsParam);
                if (statsParam.uuid === "me") {

                    // 本地状态回调
                    if (statsParam.type === "video"){
                        if (this.uuids[0]) this.uuids[0].video = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3);
                        if (this.uuids[0]) this.uuids[0].videoStatus = statsParam.status;
                    } else  {
                        if (this.uuids[0]) this.uuids[0].audio = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3);
                        if (this.uuids[0]) this.uuids[0].audioStatus = statsParam.status;
                    }
                } else {
                    // 其他状态回调
                    let uuid = statsParam.uuid
                    // console.info("beforeStatus:",this.uuids)
                    this.uuids = this.uuids.map(item =>{
                        if(item.uuid == uuid) {
                            if (statsParam.type === "video"){
                                item.videoStatus = statsParam.status;
                                item.video = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3)
                                return item;
                            } else  {
                                item.audioStatus = statsParam.status;
                                item.audio = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3)
                                return item;
                            }

                        }else  {
                            return item
                        }
                    })
                    // console.info("afterStatus:",this.uuids)
                }

            });
            agoro.localStatusCallback((stats)=>{
                // console.info("leaveRoom");

                if(stats == -1){
                    this.destroyed();
                    this.uuids = [];
                }else if (stats == 5) {
                    this.errorParam(this.uuid)
                }
            });
        },

        destroyed() {
            agoro.destroy()
            this.showShow = false
            this.infos = []
            this.uuids = []
            this.title = ""
            let param = {
                act:'endMeeting',
                uuid:this.uuid+""
            }
            this.callbackParam(param);
        },

        exitAction() {
            agoro.leaveChannel();
            this.showShow = false;
        },

        /**
         *
         * param = {
         *                 token: "007eJxSYBDWMQtcavZkw8++a6sKXpQ6nrhdsm/O+y1nDzlzm18ImXRegcHYxCjZzMDE1MTIxMIkySDF0szU0tTIPM3cMjE1LTklKVlnUUqDERPD1w9XWBgZGBlYGBgZQHwmMMkMJlnAJCtDSWpxiSEDAyAAAP//gmokgQ==",
         *                 channel:"test1",
         *                 uuid: "0",
         *                 appid:"342c604542484b0d9659527f79aefcdb",
         *                 avatar:"",
         *                 username:"",
         *                 video:true,
         *                 audio:true,
         *             }
         *
         * @param param
         */
        joint(param){
            console.info("joint:")
            console.info(param)

            let appid = param.appid;

            this.initAgoro(appid)

            this.video = param.video;
            this.audio = param.audio;

            setTimeout(()=>{
                agoro.jointChanel(param, (info)=>{

                    this.uuid = info.uuid;
                    this.meetingid = param.meetingid
                    this.title = param.name
                    let avatar = ""
                    this.infos.map((item)=>{
                        if (item.uuid == this.uuid) {
                            avatar = item.avatar;
                        }

                        return item
                    })

                    this.uuids.push({
                        uuid: this.uuid,
                        audio: param.audio,
                        video: param.video,
                        videoStatus:0,
                        audioStatus:0,
                        avatar:param.avatar
                    })
                    console.info("afterjoint:")
                    console.info(this.uuids)

                    this.successParam(this.uuid);
                    this.showShow = true;
                    this.mini = false;
                    if (!param.video) {
                        agoro.enableVideo(param.video)
                    }
                    agoro.enableAudio(param.audio)

                    // console.info(info)
                })
            },500)

        },
        zoomClick() {
            if (this.isTouch) {
                return;
            }

            this.mini = false;
        },

        miniClick() {
            this.mini = true
            if (this.bottomPos <0) {
                this.bottomPos = 100;
            }

            if (this.rightPos <0) {
                this.rightPos = 0;
            }
        },

        videoEnable() {
            this.video = !this.video
            agoro.enableVideo(this.video)
        },

        audioEnable() {
            this.audio = !this.audio
            agoro.enableAudio(this.audio)
        },

        invent() {
            this.mini = true;
            let param = {
                act:'invent',
                meetingid:this.meetingid+""
            }
            this.callbackParam(param);
        },
        infoParam(uuid){
            let param = {
                act:'getInfo',
                uuid:uuid+""
            }

            this.callbackParam(param);
        },
        successParam(uuid){
            let param = {
                act:'success',
                uuid:uuid+""
            }
            this.callbackParam(param);
        },
        errorParam(uuid){
            let param = {
                act:'error',
                uuid:uuid+""
            }
            this.callbackParam(param);
        },
        callbackParam(param){
            this.$emit("meetingEvent",param);
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
            // console.info("load:"+uuid);
            if (uuid === this.uuid) {
                // console.info("blindLocal");
                this.$nextTick(()=>{
                    agoro.blindLocal(this.uuid);
                })
                return;
            }
            // console.info("blindRemote");
            agoro.blindRemote(uuid);

        },

        getStatus(videoStatus,audioStatus) {
            let style = {}
            if (videoStatus > 2 || audioStatus >2) {
                style.backgroundColor = "#f28500"
            } else {
                style.backgroundColor = "#00ff00"
            }
            return style
        },

        /**
         * meetingInfos = [{uuid,avatar}]
         * @param meetingInfos
         */
        updateMeetingInfo(meetingInfos){
            this.infos.push(meetingInfos);
            this.updateUidInfo();
        },

        /**
         * 更新个人信息
         */
        updateUidInfo(){
            if (this.infos.length == 0) {
                return;
            }

            this.uuids = this.uuids.map(item=>{

                for (let i = 0; i < this.infos.length; i++) {
                    const element = this.infos[i];
                    if (element.uuid == item.uuid) {
                        item.username = element.username;
                        item.avatar = element.avatar;
                    }
                }

                return item;
            })

        },
        touchstart(touch){

            if (this.mini == true) {
                this.startPosX = 750 - touch.changedTouches[0].screenX - this.rightPos;
                this.startPosY = this.screenH - touch.changedTouches[0].screenY - this.bottomPos;
            }

        },

        touchAction(touch) {

            if (this.mini == true) {

                this.isTouch = true
                this.rightPos = 750 - touch.changedTouches[0].screenX-this.startPosX;
                this.bottomPos = this.screenH - touch.changedTouches[0].screenY -this.startPosY;
            }
        },
        touchend() {

            this.isTouch = false;
            if (this.mini == true) {
                this.startPosX = 0;
                this.startPosY = 0;
            }

        }
    },

}
</script>
