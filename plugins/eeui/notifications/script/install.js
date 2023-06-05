// 安装插件时会node运行此文件
const fs = require('fs');
const path = require('path');

let androidPath = path.resolve(process.cwd(), 'platforms/android/eeuiApp');
let gradPath = path.resolve(androidPath, 'build.gradle');
let result = fs.readFileSync(gradPath, 'utf8');
let values = result.split('\n');

let packageName = "";
for (let i = 0; i < values.length; i++) {
    let item = values[i];
    if (item.indexOf('applicationId') !== -1) {
        packageName = (item.split('=')[1] + "").trim();
        packageName = packageName.replace(/\"/g, "");
        break
    }
}

let to = path.resolve(process.cwd(), 'plugins/eeui/notifications/android/src/main/res/drawable');
_mkdirsSync(to);

function _mkdirsSync(dirname)  {
    if (fs.existsSync(dirname)) {
        return true;
    } else {
        if (_mkdirsSync(path.dirname(dirname))) {
            fs.mkdirSync(dirname);
            return true;
        }
    }
}

function _copyFile() {
    ['xhdpi', 'xxhdpi', 'xxxhdpi', 'hdpi', 'mdpi'].some((dName) => {
        let dPath = path.resolve(androidPath, 'app/src/main/res/mipmap-' + dName + '/ic_launcher.png');
        let tPath;
        if (fs.existsSync(dPath)) {
            tPath = path.resolve(to, 'notify_icon.png');
            !fs.existsSync(tPath) && fs.copyFileSync(dPath, tPath);
            return true;
        }
    });
}


_copyFile();