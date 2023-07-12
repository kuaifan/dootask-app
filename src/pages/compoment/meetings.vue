<template>
    <div ref="root" class="mask" v-if="showShow" :style="videoStyle" >
        <scroller style="position:absolute; top:0px; left: 0px; bottom: 0px; right: 0px; padding: 16px; background-color: white;">
            <text :style="titleStyle">{{title}}</text>
            <div class="render-views" :style="{justifyContent:miniRate<1?'start':'space-between'}">
                <div class="grid-item" :style="gridItemStyle" v-for="item in uuids">
                    <div class="local hidden" :style="localStyle">
                        <eeuiAgoro-com class="local" :style="camaraStyle" ref="local" :uuid="item.uuid" @load="load"></eeuiAgoro-com>
                    </div>
                    <image v-if="item.videoStatus == 0"  :src="item.avatar" :style="avatarStyle"></image>
                    <div :style="videoButtonStyle" >
                        <image v-if="!item.video"  :style="videoSubStyle" :src="'root://pages/assets/images/meeting_video_err.png'"></image>
                        <image v-if="!item.audio"  :style="videoSubStyle" :src="'root://pages/assets/images/meeting_audio_err.png'"></image>
                    </div>

                    <div :style="subAvatarContainerStyle">
                        <image :style="subAvatarStyle" :src="item.avatar"></image>
                    </div>
                    <div class="status-indicator" :style="indicatorStyle">
                        <div class="sub-status-indicator" :style="getStatus(item.audioStatus,item.videoStatus)"></div>
                    </div>
                </div>
            </div>
        </scroller>
        <div style="position: absolute; flex-direction: row; bottom: 16px;right: 0px;left: 0px;">

            <div v-if="miniRate< 1" style="flex: 1;"></div>
            <div style="flex-direction: row; justify-content: space-between;" :style="subButtonStyle">
                <div class="button" :style="buttonPadding" @click="audioEnable">
                    <image :style="buttonSize" :src="audio? 'root://pages/assets/images/meeting_audio_on.png':'root://pages/assets/images/meeting_audio_off.png'"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="videoEnable">
                    <image :style="buttonSize" :src="video? 'root://pages/assets/images/meeting_video_on.png':'root://pages/assets/images/meeting_video_off.png'"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="switchClicked">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_camera_reverse.png"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="invent">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_invent.png"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="hideClicked">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_mini.png"></image>
                </div>

                <div class="exit" :style="buttonPadding"  @click="exitClick">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_exit.png"></image>
                </div>

<!--                :style="{backgroundColor:'#f28500'}"-->
<!--                <div v-if="isAndroid" class="exit" :style="buttonPadding"  @click="exitClick">-->
<!--                    <image :style="buttonSize" src="root://pages/assets/images/meeting_exit.png"></image>-->
<!--                </div>-->
            </div>


        </div>
        <div style="flex-direction: row; position: absolute; justify-content: right; background-color: white; border-color:#D9E2E9; border-width: 2px; top: -4px;left: -4px;right: -4px;;bottom: -4px; overflow: hidden;" v-if="mini" @click="zoomClick(false)" @touchstart="touchstart" @touchmove="touchAction" @touchend="touchend">
            <div :style="popVideoContainerStyle" style="align-self: center; margin-left: 22px;">
                <image :style="popVideoStyle" :src="video? 'root://pages/assets/images/meeting_black_video_on.png':'root://pages/assets/images/meeting_black_video_off.png'"></image>
            </div>
            <div :style="popAudioContainerStyle">
                <image :style="popVideoStyle":src="audio? 'root://pages/assets/images/meeting_black_audio_on.png':'root://pages/assets/images/meeting_black_audio_off.png'"></image>
            </div>
        </div>
        <custom-alert ref="alert" :mini-rate="miniRate" :pos="'top'" :offset="150" @exitConfirm="exitAction"></custom-alert>
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
    flex-direction: row;
}

.grid-item {
}

.status-indicator {
    position: absolute;

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
    overflow: hidden;
    background-color: lightgray;
}

.hidden {
    margin-top: 15px;
    margin-left: 15px;
    overflow: hidden;
}

.button {

    /*border-width: 1px;*/
    /*border-color: rgb(20, 172, 78);*/
    background-color: rgb(20, 172, 78);
    border-radius: 8px;
}

.exit {
    background-color: #f28500;
    border-radius: 8px;
}

.switch {
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

.shut {
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
import CustomAlert from "./customAlert.vue";

const agoro = app.requireModule("eeuiAgoro");
const eeui = app.requireModule("eeui")
const animation = app.requireModule("animation")
const deviceInfo = app.requireModule("eeui/deviceInfo");

export default {
    name: "meetings",
    components: {CustomAlert},
    data() {
        return {
            title: "",
            uuids: [],
            uuid: 0,
            meetingid: 0,
            mini: false,
            showShow: false,
            video: false,
            audio: false,
            infos: [],
            screenH: WXEnvironment.deviceHeight / WXEnvironment.deviceWidth * 750,
            screenW: 750,
            bottomPos: 100,
            rightPos: 0,
            isTouch: false,
            startPosX: 0,
            startPosY: 0,
            bottomShow: true,
            bottomColor: 'white',
            alertParams: {
                title: "",
                message: "",
                cancel: "",
                confirm: ""
            },
            miniRate: 1,
            exitAlert: false,
            isAndroid: false //android bug 只有一项无法显示
        };
    },

    computed: {
        titleStyle() {
            return {
                fontSize: this.miniRate < 1 ? '28px' : '36px',
                padding: this.scaleSize(16)
            }
        },

        gridItemStyle() {
            return {
                width: this.scaleSize(350),
                height: this.scaleSize(350)
            }
        },
        localStyle() {
            return {
                width: this.scaleSize(320),
                height: this.scaleSize(320),
                marginTop: this.scaleSize(15),
                marginLeft: this.scaleSize(15),
                borderRadius: '16px'
            }
        },
        camaraStyle() {
            return {
                width: this.scaleSize(320),
                height: this.scaleSize(320),
                borderRadius: '16px'
            }
        },
        avatarStyle() {
            return {
                position: 'absolute',
                top: this.scaleSize(15),
                left: this.scaleSize(15),
                right: this.scaleSize(15),
                bottom: this.scaleSize(15),
                borderRadius: '16px',
                flexDirection: 'row',
                backgroundColor: 'white'
            };
        },

        videoButtonStyle() {
            return {
                position: 'absolute',
                top: this.scaleSize(16),
                right: this.scaleSize(10),
                flexDirection: 'row'
            }
        },
        videoSubStyle() {
            return {
                width: this.scaleSize(40),
                height: this.scaleSize(40),
                marginRight: this.scaleSize(12)
            };
        },
        subAvatarContainerStyle() {
            return {
                position: 'absolute',
                bottom: '0px',
                right: '0px',
                width: this.scaleSize(80),
                height: this.scaleSize(80),
                borderRadius: this.scaleSize(40),
                backgroundColor: 'white',
                overflow: 'hidden'
            };
        },
        subAvatarStyle() {
            return {
                width: this.scaleSize(70),
                height: this.scaleSize(70),
                marginTop: this.scaleSize(5),
                marginLeft: this.scaleSize(5),
                borderRadius: this.scaleSize(35),
                backgroundColor: 'greenyellow'
            };
        },
        indicatorStyle() {
            return {
                width: this.scaleSize(20),
                height: this.scaleSize(20),
                borderRadius: this.scaleSize(10),
                bottom: this.scaleSize(6),
                right: this.scaleSize(6)
            };
        },
        subIndicatorStyle() {

        },
        subButtonStyle() {
            return {
                marginLeft: this.scaleSize(16),
                marginRight: this.scaleSize(18)
            }
        },
        popVideoContainerStyle() {
            return {
                padding: this.scaleSize(12),
                marginLeft: this.scaleSize(22)
            }
        },
        popAudioContainerStyle() {
            return {
                padding: this.scaleSize(12),
                marginLeft: this.scaleSize(4),
                alignSelf: 'center'
            }
        },
        popVideoStyle() {
            return {
                width: this.scaleSize(40),
                height: this.scaleSize(40)
            }
        },
        popAudioStyle() {

        },
        videoStyle() {
            let style = {}
            if (this.mini) {
                style.width = this.scaleSize(182);
                style.height = this.scaleSize(80);
                style.right = this.rightPos + "px";
                style.bottom = this.bottomPos + "px";
                style.borderRadius = this.scaleSize(8);
                style.borderWidth = "1px";
                style.borderColor = "#D9E2E9";
            } else {
                style.top = "0px";
                style.bottom = "0px";
                style.right = "0px";
                style.left = "0px";
            }
            return style;
        },

        /**
         * 转译样式类型 （还是会在标签里调用方法是否多此一举？）
         * @return {function(*): *}
         */
        styleChange() {
            return function (params) {
                return params
            };
        },
        buttonPadding() {
            return {
                marginLeft: this.scaleSize(15),
                paddingTop: this.scaleSize(12),
                paddingBottom: this.scaleSize(12),
                paddingLeft: this.scaleSize(32),
                paddingRight: this.scaleSize(32),
            }
        },
        buttonSize() {
            return {
                width: this.scaleSize(40),
                height: this.scaleSize(40)
            }
        }

    },

    mounted() {
        // console.info(WXEnvironment.deviceHeight)
        // console.info(this.screenH)
        this.isAndroid = WXEnvironment.platform.toLowerCase() == 'android'

        let height = WXEnvironment.deviceHeight
        let width = WXEnvironment.deviceWidth

        //取宽高最小值
        let min = height > width ? width : height;

        let currentScale = width / 750.0

        if (width > height) {
            //横屏
            let realScale = height / 750.0
            this.screenW = width / realScale;
        }

        // console.info(currentScale)
        let maxScale = 1.92;

        let minScale = maxScale / currentScale;
        if (minScale < 1) {
            this.miniRate = minScale
        }
        // console.info(minScale)
    },
    methods: {

        scaleSize(current) {

            return this.miniRate * current + 'px';
        },

        /**
         *
         * @param appid
         */
        initAgoro(appid) {
            agoro.initialWithParam({
                id: appid
            }, (jointData) => {
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
                    this.infos.map((item) => {
                        if (item.uuid == this.uuids) {
                            avatar = item.avatar;
                        }
                        return item
                    })
                    if (shouldAdd == true) {
                        this.uuids.push({
                            uuid: uuid,
                            audio: false,
                            video: false,
                            videoStatus: 0,
                            audioStatus: 0,
                            avatar: avatar
                        });

                        if (this.uuid !== uuid) {
                            this.infoParam(uuid);
                        }

                    }

                } else if (jointData.action == "leave") {
                    // console.info("leave:"+ uuid);
                    // console.info(this.uuids);
                    this.uuids = this.uuids.filter(item => {
                        return item.uuid != uuid;
                    })
                    // console.info(this.uuids);
                }
            });
            agoro.statusCallback((statsParam) => {
                console.info("statsParam:", statsParam);
                // console.info(statsParam);
                if (statsParam.uuid === "me") {

                    // 本地状态回调
                    if (statsParam.type === "video") {
                        if (this.uuids[0]) this.uuids[0].video = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3);
                        if (this.uuids[0]) this.uuids[0].videoStatus = statsParam.status;
                    } else {
                        if (this.uuids[0]) this.uuids[0].audio = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3);
                        if (this.uuids[0]) this.uuids[0].audioStatus = statsParam.status;
                    }
                } else {
                    // 其他状态回调
                    let uuid = statsParam.uuid
                    // console.info("beforeStatus:",this.uuids)
                    this.uuids = this.uuids.map(item => {
                        if (item.uuid == uuid) {
                            if (statsParam.type === "video") {
                                item.videoStatus = statsParam.status;
                                item.video = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3)
                                return item;
                            } else {
                                item.audioStatus = statsParam.status;
                                item.audio = (statsParam.status == 1 || statsParam.status == 2 || statsParam.status == 3)
                                return item;
                            }

                        } else {
                            return item
                        }
                    })
                    // console.info("afterStatus:",this.uuids)
                }

            });
            agoro.localStatusCallback((stats) => {
                // console.info("leaveRoom");

                if (stats == -1) {
                    this.destroyed();
                    this.uuids = [];
                } else if (stats == 5) {
                    this.errorParam(this.uuid)
                }
            });
        },

        destroyed() {
            agoro.destroy()
            //关闭屏幕常亮
            deviceInfo.keepScreenOn(false);
            this.showShow = false
            this.infos = []
            this.uuids = []
            this.title = ""
            let param = {
                act: 'endMeeting',
                uuid: this.uuid + ""
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
        joint(param) {
            console.info("joint:")
            console.info(param)

            let appid = param.appid;

            this.initAgoro(appid)

            this.video = param.video;
            this.audio = param.audio;

            setTimeout(() => {
                agoro.jointChanel(param, (info) => {

                    this.uuid = info.uuid;
                    this.meetingid = param.meetingid
                    this.title = param.name
                    this.alertParams = param.alert
                    let avatar = ""
                    this.infos.map((item) => {
                        if (item.uuid == this.uuid) {
                            avatar = item.avatar;
                        }

                        return item
                    })

                    this.uuids.push({
                        uuid: this.uuid,
                        audio: param.audio,
                        video: param.video,
                        videoStatus: 0,
                        audioStatus: 0,
                        avatar: param.avatar
                    })
                    console.info("afterjoint:")
                    console.info(this.uuids)

                    this.showShow = true;
                    this.mini = false;
                    //开启屏幕常亮
                    deviceInfo.keepScreenOn(true);
                    // 延迟一秒发送
                    this.$nextTick(() => {
                        this.successParam(this.uuid);
                    })

                    if (!param.video) {
                        agoro.enableVideo(param.video)
                    }
                    agoro.enableAudio(param.audio)
                })
            }, 500)

        },
        zoomClick() {
            if (this.isTouch === true) {
                return;
            }

            this.mini = false;
            this.bottomShow = false;
            this.$nextTick(() => {

                this.bottomShow = true;
            })

        },

        miniClick() {
            this.mini = true
            if (this.bottomPos < 0) {
                this.bottomPos = 100;
            }

            if (this.rightPos < 0) {
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
                act: 'invent',
                meetingid: this.meetingid + ""
            }
            this.callbackParam(param);
        },
        infoParam(uuid) {
            let param = {
                act: 'getInfo',
                uuid: uuid + ""
            }

            this.callbackParam(param);
        },
        successParam(uuid) {
            let param = {
                act: 'success',
                uuid: uuid + ""
            }
            this.callbackParam(param);
        },
        errorParam(uuid) {
            let param = {
                act: 'error',
                uuid: uuid + ""
            }
            this.callbackParam(param);
        },
        callbackParam(param) {
            this.$emit("meetingEvent", param);
        },

        switchClicked() {
            agoro.switchCamera()
        },

        silenceClicked(uids) {
            // agoro.
            // agoro.silence(true);
        },
        remoteSlicent(item) {
            agoro.muteRemoteAudioStream(item.uuids, !item.mute);
        },

        remoteVideo(item) {
            agoro.muteRemoteVideoStream(item.uuids, !item.mute);
        },

        loudlyClicked() {

        },

        shutClicked() {
            agoro.leaveChannel();
        },
        hideClicked() {
            this.miniClick();
        },
        exitClick() {
            this.$refs.alert.showWithParam(this.alertParams);
        },

        load(param) {
            let uuid = param.target.attr.uuid;
            // console.info("load:"+uuid);
            if (uuid === this.uuid) {
                // console.info("blindLocal");
                this.$nextTick(() => {
                    agoro.blindLocal(this.uuid);
                })
                return;
            }
            // console.info("blindRemote");
            agoro.blindRemote(uuid);

        },

        getStatus(videoStatus, audioStatus) {
            let style = {}
            style.width = this.scaleSize(16)
            style.height = this.scaleSize(16)
            style.borderRadius = this.scaleSize(8)
            style.marginTop = this.scaleSize(2)
            style.marginLeft = this.scaleSize(2)
            if (videoStatus > 2 || audioStatus > 2) {
                style.backgroundColor = "#f28500"
            } else {
                style.backgroundColor = "#00ff00"
            }
            return style
        },

        /**
         * 加入用户的信息
         * meetingInfos = {uuid,avatar}
         * @param meetingInfos
         */
        updateMeetingInfo(meetingInfos) {
            this.infos.push(meetingInfos);
            this.updateUidInfo();
        },

        /**
         * 更新个人信息
         */
        updateUidInfo() {
            if (this.infos.length == 0) {
                return;
            }
            this.uuids = this.uuids.map(item => {

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
        /**
         * 拖拽开始
         */
        touchstart(touch) {

            this.isTouch = true
            if (this.mini == true) {
                this.startPosX = this.screenW - touch.changedTouches[0].screenX - this.rightPos;
                this.startPosY = this.screenH - touch.changedTouches[0].screenY - this.bottomPos;
            }

        },
        /**
         * 拖拽中
         */
        touchAction(touch) {
            if (this.mini == true) {

                this.isTouch = true
                this.rightPos = this.screenW - touch.changedTouches[0].screenX - this.startPosX;
                this.bottomPos = this.screenH - touch.changedTouches[0].screenY - this.startPosY;
            }
        },
        /**
         * 拖拽结束
         * (安卓的触碰结束时间出现比较晚，稍微有延迟)
         */
        touchend() {
            this.isTouch = false;
            if (this.mini == true) {
                this.startPosX = 0;
                this.startPosY = 0;
                this.stickyMoving()
            }
        },
        stickyMoving() {

            let move = 0
            let center = 284

            if (this.miniRate < 1) {
                let des = (this.screenW - 750) / 2.0
                center = center + des
            }
            if (this.rightPos > center) {
                move = this.screenW - 182 * this.miniRate;
            }
            console.info(this.screenW)

            animation.transition(this.$refs.root, {
                styles: {
                    translateX: move + "px",
                },
                duration: 400, //ms
                timingFunction: 'linear',
                needLayout: false,
                delay: 0 //ms
            }, () => {
                this.rightPos = move
            })
        }
    },

}
</script>
