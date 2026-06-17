// Metro 配置：将 assets/web 下的离线包静态资源（前端构建产物）纳入打包
const { getDefaultConfig } = require('expo/metro-config');

const config = getDefaultConfig(__dirname);

// 离线包内含任意扩展名的前端构建产物，统一以 asset 形式打进 App bundle，
// 运行时由本地静态服务（src/server）serve。这里把常见前端资源扩展登记为 assetExts。
const webAssetExts = ['html', 'json', 'txt', 'map', 'woff', 'woff2', 'ttf', 'eot'];
for (const ext of webAssetExts) {
  if (!config.resolver.assetExts.includes(ext)) {
    config.resolver.assetExts.push(ext);
  }
}

module.exports = config;
