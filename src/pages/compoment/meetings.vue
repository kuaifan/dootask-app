<template>
    <div ref="root" class="mask" v-if="showShow" :style="videoStyle">
        <scroller class="scroller">
            <text :style="titleStyle">{{title}}</text>
            <div class="render-views">
                <div :style="gridItemStyle" v-for="item in uuids">
                    <div class="local hidden" :style="localStyle">
                        <eeuiAgoro-com class="local" :style="camaraStyle" ref="local" :uuid="item.uuid" @load="load"/>
                    </div>
                    <image v-if="item.videoStatus == 0" :src="item.avatar" :style="avatarStyle"></image>
                    <div :style="videoButtonStyle" >
                        <image v-if="!item.video" :style="videoSubStyle" src="root://pages/assets/images/meeting_video_err.png"></image>
                        <image v-if="!item.audio" :style="videoSubStyle" src="root://pages/assets/images/meeting_audio_err.png"></image>
                    </div>

                    <div :style="subAvatarContainerStyle">
                        <image :style="subAvatarStyle" :src="item.avatar"></image>
                    </div>
                    <div class="status-indicator" :style="indicatorStyle">
                        <div :style="getStatus(item.audioStatus, item.videoStatus)"></div>
                    </div>
                </div>
            </div>
        </scroller>
        <div class="menu">
            <div class="flex"></div>
            <div class="menu-buttons" :style="subButtonStyle">
                <div class="button" :style="buttonPadding" @click="audioEnable">
                    <image :style="buttonSize" :src="audio? 'root://pages/assets/images/meeting_audio_on.png':'root://pages/assets/images/meeting_audio_off.png'"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="videoEnable">
                    <image :style="buttonSize" :src="video? 'root://pages/assets/images/meeting_video_on.png':'root://pages/assets/images/meeting_video_off.png'"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="switchClicked">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_camera_reverse.png"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="inventClick">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_invent.png"></image>
                </div>
                <div class="button" :style="buttonPadding" @click="hideClicked">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_mini.png"></image>
                </div>

                <div class="exit" :style="buttonPadding" @click="exitClick">
                    <image :style="buttonSize" src="root://pages/assets/images/meeting_exit.png"></image>
                </div>
            </div>
        </div>
        <div class="mini-box" v-if="mini" :style="popMiniBoxStyle" @click="zoomClick(false)" @touchstart="touchstart" @touchmove="touchAction" @touchend="touchend">
            <div :style="popContainerStyle">
                <image :style="popVideoStyle" :src="video? 'root://pages/assets/images/meeting_black_video_on.png':'root://pages/assets/images/meeting_black_video_off.png'"></image>
            </div>
            <div :style="popContainerStyle">
                <image :style="popVideoStyle":src="audio? 'root://pages/assets/images/meeting_black_audio_on.png':'root://pages/assets/images/meeting_black_audio_off.png'"></image>
            </div>
        </div>
        <custom-alert ref="alert" :mini-rate="miniRate" pos="top" :offset="100" @exitConfirm="exitAction"></custom-alert>
    </div>
</template>

<style scoped>
.flex {
    flex: 1;
}

.mask {
    position: fixed;
    overflow: hidden;
    background-color: white;
}

.scroller {
    position: absolute;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
    padding: 16px;
    background-color: white;
}

.menu {
    position: absolute;
    flex-direction: row;
    bottom: 16px;
    right: 0;
    left: 0;
}

.menu-buttons {
    flex-direction: row;
    justify-content: space-between;
}

.mini-box {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    flex-direction: row;
    background-color: white;
}

.render-views {
    flex-wrap: wrap;
    flex-direction: row;
    justify-content: start;
}

.status-indicator {
    position: absolute;
    background-color: white;
}

.local {
    overflow: hidden;
    background-color: lightgray;
}

.hidden {
    overflow: hidden;
}

.button {
    background-color: rgb(20, 172, 78);
}

.exit {
    background-color: #f28500;
}
</style>

<script>
import CustomAlert from "./customAlert.vue";

const dom = app.requireModule('dom')
const eeui = app.requireModule("eeui")
const agoro = app.requireModule("eeuiAgoro");
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

            isTouch: false,
            bottomPos: 100,
            rightPos: 0,
            startPosX: 0,
            startPosY: 0,

            screenW: 0,
            screenH: 0,

            bottomShow: true,
            bottomColor: 'white',
            alertParams: {
                title: "",
                message: "",
                cancel: "",
                confirm: ""
            },
            miniRate: 1.0,
        };
    },

    computed: {
        titleStyle() {
            return {
                fontSize: this.scaleSize(32),
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
                borderRadius: this.scaleSize(16),
            }
        },

        camaraStyle() {
            return {
                width: this.scaleSize(320),
                height: this.scaleSize(320),
                borderRadius: this.scaleSize(16),
            }
        },

        avatarStyle() {
            return {
                position: 'absolute',
                top: this.scaleSize(15),
                left: this.scaleSize(15),
                right: this.scaleSize(15),
                bottom: this.scaleSize(15),
                borderRadius: this.scaleSize(16),
                flexDirection: 'row',
                backgroundColor: 'white'
            };
        },

        videoButtonStyle() {
            return {
                position: 'absolute',
                top: this.scaleSize(24),
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
                bottom: '0',
                right: '0',
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

        subButtonStyle() {
            return {
                marginLeft: this.scaleSize(16),
                marginRight: this.scaleSize(18)
            }
        },

        popMiniBoxStyle() {
            return {
                paddingLeft: this.scaleSize(12),
            }
        },

        popContainerStyle() {
            return {
                width: this.scaleSize(68),
                height: this.scaleSize(72),
                alignItems: "center",
                justifyContent: "center",
            }
        },

        popVideoStyle() {
            return {
                width: this.scaleSize(40),
                height: this.scaleSize(40)
            }
        },

        videoStyle() {
            let style = {}
            if (this.mini) {
                style.width = this.scaleSize(160);
                style.height = this.scaleSize(72);
                style.right = this.rightPos + "px";
                style.bottom = this.bottomPos + "px";
                style.borderWidth = "1px";
                style.borderColor = "#D9E2E9";
                style.borderRadius = this.scaleSize(8);
            } else {
                style.top = "0";
                style.bottom = "0";
                style.right = "0";
                style.left = "0";
            }
            return style;
        },

        buttonPadding() {
            return {
                marginLeft: this.scaleSize(15),
                paddingTop: this.scaleSize(12),
                paddingBottom: this.scaleSize(12),
                paddingLeft: this.scaleSize(32),
                paddingRight: this.scaleSize(32),
                borderRadius: this.scaleSize(8),
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
        //
    },

    methods: {
        /**
         * 计算放大倍数
         */
        scaleSize(current) {
            return (current / this.miniRate) + 'px';
        },

        /**
         * 声网初始化
         * @param appid
         */
        initAgoro(appid) {
            agoro.initialWithParam({
                id: appid
            }, (jointData) => {
                let uuid = jointData.uuid;
                if (jointData.action == "joint") {
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
                    this.uuids = this.uuids.filter(item => {
                        return item.uuid != uuid;
                    })
                }
            });
            agoro.statusCallback((statsParam) => {
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
                }
            });
            agoro.localStatusCallback((stats) => {
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
         * 加入会议
         * @param param
         */
        joint(param) {
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
                    this.miniRate = Math.min(2, Math.max(1, this.runNum(eeui.getVariate("outerWidth", "430")) / 430));
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
            dom.getComponentRect(this.$refs.root, (res) => {
                this.screenW = res.size.width;
                this.screenH = WXEnvironment.deviceHeight / WXEnvironment.deviceWidth * this.screenW;

                this.mini = true
                if (this.bottomPos < 0) {
                    this.bottomPos = 100;
                }
                this.stickyMoving()
            });
        },

        videoEnable() {
            this.video = !this.video
            agoro.enableVideo(this.video)
        },

        audioEnable() {
            this.audio = !this.audio
            agoro.enableAudio(this.audio)
        },

        inventClick() {
            this.miniClick()
            this.callbackParam({
                act: 'invent',
                meetingid: `${this.meetingid}`
            });
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

        /**
         * 切换摄像头
         */
        switchClicked() {
            agoro.switchCamera()
        },

        /**
         * 隐藏视频语音
         */
        hideClicked() {
            this.miniClick();
        },

        /**
         * 退出视频语音
         */
        exitClick() {
            this.$refs.alert.showWithParam(this.alertParams);
        },

        /**
         * 关键交互方法 自定义本地view load方法的回调
         * @param param
         */
        load(param) {
            let uuid = param.target.attr.uuid;
            if (uuid === this.uuid) {
                this.$nextTick(() => {
                    agoro.blindLocal(this.uuid);
                })
                return;
            }
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
                style.backgroundColor = "#ff9900"
            } else {
                style.backgroundColor = "#84C56A"
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
            let size = 160 / this.miniRate
            let center = (this.screenW - size) / 2
            if (this.rightPos > center) {
                move = this.screenW - size;
            }
            this.rightPos = move
        }
    },
}
</script>
