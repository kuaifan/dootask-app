<template>
    <!--    <div class="g-cover" :style="gStyle" v-if="show" @click="backClick()">-->
    <div class="g-cover" v-if="show" @overlay="cancelClick">
        <div class="container flex-d-c" :style="posStyle">
            <div style="flex-direction: row;">
                <image :style="iconStyle" src="root://pages/assets/images/alert-icon.png"></image>
                <div :style="HStyle" >
                    <text :style="titleStyle" style="font-weight: 300; color: black; ">{{title}}</text>
                    <text :style="subTitleStyle" style="font-size: 26px; font-weight: 300; color: black; ">{{message}}</text>
                </div>
            </div>

            <div style="flex-direction: row;">
                <div style="flex: 1"></div>
                <div style="flex-direction: row; justify-content: space-between; " :style="buttonGroupStyle">
                    <div class="cancelTitle" @click="cancelClick" style="justify-content: center;" :style="buttonBGStyle">
                        <text :style="buttonTextStyle" style="font-weight: 300; color: black;" >{{cancel}}</text>
                    </div>
                    <div class="confirmTitle" :style="confirmButtonStyle" @click="confirmClick">
                        <text :style="buttonTextStyle" style="font-weight: 300; color: white;" >{{confirm}}</text>
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
        miniRate:{
            default:1.0
        }

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

            style.width = this.scaleSize(718)
            style.padding = this.scaleSize(48)
            style.marginLeft = this.scaleSize(16)
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
            style.width = this.scaleSize(718)
            //style.justifyContent = "center"
            switch (pos) {
                case "center":
                    style.justifyContent = "center"

                    break;

                default:
                    break;
            }
            return style
        },
        iconStyle(){
            return {
                width:this.scaleSize(50),
                height:this.scaleSize(50)
            };
        },
        HStyle(){
            return {
                justifyContent:'left',
                marginLeft:this.scaleSize(32)
            }
        },
        titleStyle() {
            return {
                fontSize:this.scaleSize(30),
                marginTop:this.scaleSize(4)
            }
        },
        subTitleStyle() {
            return {
                fontSize:this.scaleSize(26),
                marginTop:this.scaleSize(32)
            }
        },
        buttonGroupStyle() {
            return {
                marginTop:this.scaleSize(64)
            }
        },
        buttonBGStyle() {
            return {
                marginRight:this.scaleSize(64)
            }
        },
        confirmButtonStyle() {
            return {
                paddingLeft:this.scaleSize(32),
                paddingRight:this.scaleSize(32),
                paddingTop:this.scaleSize(12),
                paddingBottom:this.scaleSize(12)
            }
        },
        buttonTextStyle() {
            return {
                fontSize:this.scaleSize(26)
            }
        },
    },
    mounted(){
        this.show = false;
    },
    methods:{
        scaleSize(current){
            return this.miniRate*current+'px';
        },

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
    background-color: white;
    border-radius: 16px;
    align-self: center;
}

.cancelTitle{
}

.confirmTitle{
    padding: 16px 32px;
    background-color: #84c56a;
    border-radius: 8px;
}

</style>
