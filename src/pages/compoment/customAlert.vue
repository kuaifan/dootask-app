<template>
    <!--    <div class="g-cover" :style="gStyle" v-if="show" @click="backClick()">-->
    <div class="g-cover" v-if="show" @overlay="cancelClick">
        <div class="container flex-d-c" :style="posStyle">
            <div style="flex-direction: row;">
                <image style="width: 50px; height: 50px;" src="root://pages/assets/images/alert-icon.png"></image>
                <div style=" justify-content: left; margin-left: 32px; ">
                    <text style="font-size: 30px; font-weight: 300; color: black; margin-top: 4px;">{{title}}</text>
                    <text style="font-size: 26px; font-weight: 300; color: black; margin-top: 32px;">{{message}}</text>
                </div>
            </div>

            <div style="flex-direction: row;">
                <div style="flex: 1"></div>
                <div style="flex-direction: row; justify-content: space-between; margin-top: 64px;">
                    <div class="cancelTitle" @click="cancelClick" style="justify-content: center;">
                        <text style="font-size: 26px; font-weight: 300; color: black;" >{{cancel}}</text>
                    </div>
                    <div class="confirmTitle" @click="confirmClick">
                        <text style="font-size: 26px; font-weight: 300; color: white;" >{{confirm}}</text>
                    </div>
                </div>
            </div>

        </div>
    </div>
</template>

<script>
export default {
    props: {
        pos:{
            type: String,
            default: "center"
        },
        offset:{
            type: Number,
            default:0
        },
        canOverlayClick: {
            type: Boolean,
            default: true,
        },

    },
    data() {
        return {
            back: false,
            show: false,
            title:"",
            message:"",
            cancel:"",
            confirm:"",
        }
    },
    computed: {
        posStyle(){
            const style = {};

            const pos  = this.pos ? this.pos:"center";
            style.position = "absolute";

            switch (pos) {
                case "center":
                    style.alignSelf = "center";

                    break;
                case "bottom":
                    style.bottom = this.offset+"px";

                case "top":
                    style.top = this.offset+"px";

                default:
                    break;
            }
            return style
        },
        gStyle(){
            const style = {};
            const pos  = this.pos ? this.pos : "center";
            //style.justifyContent = "center"
            switch (pos) {
                case "center":
                    style.justifyContent = "center"

                    break;

                default:
                    break;
            }
            return style
        }
    },
    mounted(){
        this.show = false;
    },
    methods:{

        hide(){
            this.show = false;
        },
        cancelClick(){
            this.hide();

        },
        confirmClick() {
            this.hide();
            this.$emit('exitConfirm');
        },
        showWithParam(param){
            this.title = param.title;
            this.message = param.message;
            this.cancel = param.cancel;
            this.confirm = param.confirm;

            this.show= true;
        }
    }
}
</script>

<style>
.g-cover{
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);

    /* justify-content:center; */
}
.container{
    width: 718px;
    background-color: white;
    border-radius: 16px;
    padding: 48px;
    margin-left: 16px;
}

.cancelTitle{
    margin-right: 64px;
}

.confirmTitle{
    padding: 16px 32px;
    background-color: #84c56a;
    border-radius: 8px;
}

</style>
