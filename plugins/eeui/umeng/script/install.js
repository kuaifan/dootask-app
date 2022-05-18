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

let to = path.resolve(androidPath, 'app/src/main/res/drawable');
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

function _ksort(src) {
    var keys = Object.keys(src),
        target = {};
    keys.sort();
    keys.forEach(function (key) {
        target[key] = src[key];
    });
    return target;
}

function _copyFile() {
    ['xhdpi', 'xxhdpi', 'xxxhdpi', 'hdpi', 'mdpi'].some((dName) => {
        let dPath = path.resolve(androidPath, 'app/src/main/res/mipmap-' + dName + '/ic_launcher.png');
        let tPath;
        if (fs.existsSync(dPath)) {
            tPath = path.resolve(to, 'umeng_push_notification_default_large_icon.png');
            !fs.existsSync(tPath) && fs.copyFileSync(dPath, tPath);
            tPath = path.resolve(to, 'umeng_push_notification_default_small_icon.png');
            !fs.existsSync(tPath) && fs.copyFileSync(dPath, tPath);
            return true;
        }
    });
}

function _androidMaven() {
    let gradlePath = path.resolve(androidPath, 'build.gradle');
    if (fs.existsSync(gradlePath)) {
        let gradleContent = fs.readFileSync(gradlePath, 'utf8');
        let mavenUrl = `https://dl.bintray.com/umsdk/release`;
        let gradleReg = new RegExp(`maven[\\s()]*\\{[\\s\\S][^}]*url\\s*('|")${mavenUrl}\\1[\\s\\S][^}]*\\}`);
        if (!gradleReg.test(gradleContent)) {
            gradleContent = gradleContent.replace(new RegExp("repositories\\s*\\{\\n*", "g"), `repositories {\n\t\tmaven { url "${mavenUrl}" }\n`);
            fs.writeFileSync(gradlePath, gradleContent, 'utf8');
        }
    }
}

function _androidGradle() {
    let gradlePath = path.resolve(androidPath, 'app/build.gradle');
    if (fs.existsSync(gradlePath)) {
        let gradleContent = fs.readFileSync(gradlePath, 'utf8');
        let gradleReg = new RegExp(`manifestPlaceholders\\s*=\\s*\\[([\\s\\S][^\\]]*)\\]\\n*`);
        //
        let jsonData = require(path.resolve(process.cwd(), 'eeui.config'));
        if (!jsonData['umeng'] || typeof jsonData['umeng'] != "object") {
            jsonData['umeng'] = {}
        }
        jsonData = jsonData['umeng'];
        if (!jsonData['android'] || typeof jsonData['android'] != "object") {
            jsonData['android'] = {};
        }
        jsonData = jsonData['android'];
        //
        if (!gradleReg.test(gradleContent)) {
            gradleContent = gradleContent.replace(new RegExp("defaultConfig\\s*\\{"), `defaultConfig {\n\t\tmanifestPlaceholders = [\n]\n`);
        }
        //
        let match = gradleContent.match(gradleReg);
        if (match) {
            try {
                let tempContent = match[1],
                    tempRes = /\s*([a-zA-Z][a-zA-Z0-9_]*)\s*:\s*('|")(.*?)\2\s*[,\n]/g,
                    tempObject = {},
                    tempValue = "";
                while (tempValue = tempRes.exec(tempContent)) {
                    tempObject[tempValue[1]] = tempValue[3];
                }
                tempObject = _ksort(Object.assign(tempObject, {
                    vivoAppKey  : jsonData['vivoAppKey'] || "",
                    vivoAppId   : jsonData['vivoAppId'] || "",
                    huaweiAppId : jsonData['huaweiAppId'] || ""
                }));
                //
                let newContent = "";
                for (let key in tempObject) {
                    if (newContent) {
                        newContent+= `,\n`
                    }
                    newContent+= `\t\t\t${key}:"${tempObject[key]}"`;
                }
                //
                gradleContent = gradleContent.replace(match[0], `manifestPlaceholders = [\n${newContent}\n\t\t]\n`);
                fs.writeFileSync(gradlePath, gradleContent, 'utf8');
            } catch (e) {

            }
        }
    }
}

_copyFile();
// _androidMaven(); // 现在已经不需要
_androidGradle();
