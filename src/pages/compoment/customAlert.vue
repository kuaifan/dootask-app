<template>
    <div class="g-cover" v-if="show" @overlay="cancelClick">
        <div class="container flex-d-c" :style="posStyle">
            <div class="flex-d-r">
                <image :style="iconStyle" src="root://pages/assets/images/alert-icon.png"></image>
                <div :style="hStyle">
                    <text :style="titleStyle" class="font-weight-300">{{ title }}</text>
                    <text :style="subTitleStyle" class="font-size-26 font-weight-300">{{ message }}</text>
                </div>
            </div>

            <div class="flex-d-r">
                <div class="flex"></div>
                <div class="flex-d-r justify-content-sb" :style="buttonGroupStyle">
                    <div @click="cancelClick" class="justify-content-c" :style="buttonBGStyle">
                        <text :style="buttonTextStyle" class="font-weight-300">{{ cancel }}</text>
                    </div>
                    <div class="confirmTitle" :style="confirmButtonStyle" @click="confirmClick">
                        <text :style="confirmTextStyle" class="font-weight-300 color-white">{{ confirm }}</text>
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
        themeName: {
            type: String,
            default: "",
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
            style.width = this.scaleSize(700)
            style.padding = this.scaleSize(48)
            style.borderRadius = this.scaleSize(24)
            style.backgroundColor = this.themeName == "dark" ? "#2c2c32" : "#f8f8f8";
            switch (pos) {
                case "center":
                    style.alignSelf = "center";
                    break;
                case "bottom":
                    style.bottom = this.scaleSize(this.offset);
                    break;
                case "top":
                    style.top = this.scaleSize(this.offset);
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
                marginTop: this.scaleSize(4),
                color: this.themeName == "dark" ? "white" : "black"
            }
        },

        subTitleStyle() {
            return {
                fontSize: this.scaleSize(26),
                marginTop: this.scaleSize(32),
                color: this.themeName == "dark" ? "rgba(255, 255, 255, 0.8)" : "rgba(0, 0, 0, 0.8)"
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
                paddingBottom: this.scaleSize(12),
                borderRadius: this.scaleSize(8)
            }
        },

        buttonTextStyle() {
            return {
                fontSize: this.scaleSize(26),
                color: this.themeName == "dark" ? "rgba(255, 255, 255, 0.8)" : "rgba(0, 0, 0, 0.8)"
            }
        },

        confirmTextStyle() {
            return {
                fontSize: this.scaleSize(26),
            }
        },
    },

    mounted() {
        this.show = false;
    },

    methods: {
        scaleSize(current) {
            return (current / this.miniRate) + 'px';
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
    align-self: center;
}

.confirmTitle {
    background-color: #84c56a;
}

.flex-d-r {
    flex-direction: row;
}

.flex {
    flex: 1;
}

.justify-content-sb {
    justify-content: space-between;
}

.justify-content-c {
    justify-content: center;
}

.font-weight-300 {
    font-weight: 300;
}

.color-black {
    color: black;
}

.color-white {
    color: white;
}

.font-size-26 {
    font-size: 26px;
}
</style>
