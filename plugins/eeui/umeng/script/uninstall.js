// 卸载插件时会node运行此文件
const fs = require('fs');
const path = require('path');

let androidPath = path.resolve(process.cwd(), 'platforms/android/eeuiApp');
let to = path.resolve(androidPath, 'app/src/main/res/drawable');

let f1 = path.resolve(to, 'umeng_push_notification_default_large_icon.png');
let f2 = path.resolve(to, 'umeng_push_notification_default_small_icon.png');
if (fs.existsSync(f1)) {
    fs.unlinkSync(f1);
}
if (fs.existsSync(f2)) {
    fs.unlinkSync(f2);
}