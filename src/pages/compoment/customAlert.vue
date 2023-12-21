<template>
    <div class="g-cover" v-if="show" @overlay="cancelClick">
        <div class="container flex-d-c" :style="posStyle">
            <div class="flex-d-r">
                <image :style="iconStyle" src="root://pages/assets/images/alert-icon.png"></image>
                <div :style="hStyle" >
                    <text :style="titleStyle" class="font-weight-300 color-black">{{title}}</text>
                    <text :style="subTitleStyle" class="font-size-26 font-weight-300 color-black">{{message}}</text>
                </div>
            </div>

            <div class="flex-d-r">
                <div class="flex"></div>
                <div class="flex-d-r justify-content-sb" :style="buttonGroupStyle">
                    <div @click="cancelClick" class="justify-content-c" :style="buttonBGStyle">
                        <text :style="buttonTextStyle" class="font-weight-300 color-black">{{cancel}}</text>
                    </div>
                    <div class="confirmTitle" :style="confirmButtonStyle" @click="confirmClick">
                        <text :style="buttonTextStyle" class="font-weight-300 color-white">{{confirm}}</text>
                    </div>
                </div>
            </div>

        </div>
    </div>
</template>

<script>
export default {
    props: {
        pos: {
            type: String,
            default: "center"
        },
        offset: {
            type: Number,
            default: 0
        },
        canOverlayClick: {
            type: Boolean,
            default: true,
        },
        miniRate: {
            default: 1.0
        }
    },

    data() {
        return {
            back: false,
            show: false,
            title: "",
            message: "",
            cancel: "",
            confirm: "",
        }
    },

    computed: {
        posStyle() {
            const style = {};
            const pos = this.pos ? this.pos : "center";
            style.position = "absolute";
            style.width = this.scaleSize(718)
            style.padding = this.scaleSize(48)
            switch (pos) {
                case "center":
                    style.alignSelf = "center";
                    break;
                case "bottom":
                    style.bottom = this.offset + "px";
                    break;
                case "top":
                    style.top = (this.offset * this.miniRate) + "px";
                    break;
                default:
                    break;
            }
            return style
        },

        iconStyle() {
            return {
                width: this.scaleSize(50),
                height: this.scaleSize(50)
            };
        },

        hStyle() {
            return {
                justifyContent: 'left',
                marginLeft: this.scaleSize(32)
            }
        },

        titleStyle() {
            return {
                fontSize: this.scaleSize(30),
                marginTop: this.scaleSize(4)
            }
        },

        subTitleStyle() {
            return {
                fontSize: this.scaleSize(26),
                marginTop: this.scaleSize(32)
            }
        },

        buttonGroupStyle() {
            return {
                marginTop: this.scaleSize(64)
            }
        },

        buttonBGStyle() {
            return {
                marginRight: this.scaleSize(64)
            }
        },

        confirmButtonStyle() {
            return {
                paddingLeft: this.scaleSize(32),
                paddingRight: this.scaleSize(32),
                paddingTop: this.scaleSize(12),
                paddingBottom: this.scaleSize(12)
            }
        },

        buttonTextStyle() {
            return {
                fontSize: this.scaleSize(26)
            }
        },
    },

    mounted() {
        this.show = false;
    },

    methods: {
        scaleSize(current) {
            return this.miniRate * current + 'px';
        },

        hide() {
            this.show = false;
        },

        cancelClick() {
            this.hide();

        },

        confirmClick() {
            this.hide();
            this.$emit('exitConfirm');
        },

        showWithParam(param) {
            this.title = param.title;
            this.message = param.message;
            this.cancel = param.cancel;
            this.confirm = param.confirm;
            this.show = true;
        }
    }
}
</script>

<style scoped>
.g-cover {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
}

.container {
    background-color: white;
    border-radius: 16px;
    align-self: center;
}

.confirmTitle {
    padding: 16px 32px;
    background-color: #84c56a;
    border-radius: 8px;
}

.flex-d-r{
    flex-direction: row;
}

.flex{
    flex: 1;
}

.justify-content-sb{
    justify-content: space-between;
}

.justify-content-c{
    justify-content: center;
}

.font-weight-300{
    font-weight: 300;
}

.color-black{
    color: black;
}

.color-white{
    color: white;
}

.font-size-26{
    font-size: 26px;
}
</style>
