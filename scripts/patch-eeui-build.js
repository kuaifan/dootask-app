const fs = require('fs');
const path = require('path');

const file = '/usr/local/lib/node_modules/eeui-cli/lib/builder/buildApp.js';
let source = fs.readFileSync(file, 'utf8');

const from = `        let mainPath = path.resolve('platforms/android/eeuiApp/app/src/main/assets/eeui');
        let bundlejsPath = path.resolve('platforms/ios/eeuiApp/bundlejs/eeui');`;

const to = `        let mainPath = path.resolve('platforms/android/eeuiApp/app/src/main/assets/eeui');
        let bundlejsPath = path.resolve('platforms/ios/eeuiApp/bundlejs/eeui');
        if (!isSocket) {
            if (removeBundlejs) {
                fse.removeSync(mainPath);
                fse.removeSync(bundlejsPath);
            }
            fse.copySync(path.resolve(config.distDir), mainPath);
            fse.copySync(path.resolve(config.distDir), bundlejsPath);
            fse.outputFileSync(path.resolve(mainPath, 'config.json'), JSON.stringify(jsonData, null, '\\t'));
            fse.outputFileSync(path.resolve(bundlejsPath, 'config.json'), JSON.stringify(jsonData, null, '\\t'));
            return;
        }`;

if (!source.includes(to)) {
    if (!source.includes(from)) {
        throw new Error('eeui patch anchor not found');
    }
    source = source.replace(from, to);
    fs.writeFileSync(file, source, 'utf8');
}
