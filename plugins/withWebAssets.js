/**
 * withWebAssets —— DooTask 移动端离线包注入 config plugin（WS1）。
 *
 * 作用：在 `expo prebuild` 时，把前端构建产物（默认源目录 `assets/web/`）注入到原生工程，
 * 使其能被本地 lighttpd 静态服务（@dr.pogodin/react-native-static-server）serve：
 *
 *  - Android：复制到 `android/app/src/main/assets/web/`
 *      运行时由 src/server/staticServer.ts 用 copyFileAssets 从 APK assets 提取到可写目录再 serve。
 *  - iOS：把 `web/` 目录拷进 iOS 工程目录，并以「folder reference」形式加入 main bundle target
 *      运行时 resolveAssetsPath('web') 解析到 <MainBundle>/web，可直接 serve。
 *
 * 离线包源目录（assets/web/）在版本库中被 .gitignore 忽略，真正的产物由
 * electron/build.js 同步进来；缺失时本插件会跳过对应平台的注入（不报错），
 * 仅在源目录存在时复制，便于在前端产物尚未就绪时也能完成 prebuild。
 *
 * 用法（在 app.config.ts 的 plugins 数组加）：
 *   './plugins/withWebAssets'                       // 使用默认源目录 assets/web、bundle 子目录 web
 *   ['./plugins/withWebAssets', { source: 'assets/web', bundleDir: 'web' }]  // 自定义
 */

const fs = require('fs');
const path = require('path');
const {
  withDangerousMod,
  withXcodeProject,
  IOSConfig,
} = require('@expo/config-plugins');

/** 递归复制目录（含子目录）。Node 16.7+ 提供 fs.cpSync recursive。 */
function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  fs.cpSync(src, dest, { recursive: true });
}

/** 删除目录（若存在）。 */
function removeDir(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

/**
 * Android：把 source 目录内容复制到 android/app/src/main/assets/<bundleDir>/。
 */
function withAndroidWebAssets(config, { source, bundleDir }) {
  return withDangerousMod(config, [
    'android',
    (cfg) => {
      const projectRoot = cfg.modRequest.projectRoot;
      const srcDir = path.resolve(projectRoot, source);

      if (!fs.existsSync(srcDir)) {
        console.warn(
          `[withWebAssets] 离线包源目录不存在，跳过 Android 注入: ${srcDir}`,
        );
        return cfg;
      }

      const destDir = path.join(
        cfg.modRequest.platformProjectRoot, // android/
        'app',
        'src',
        'main',
        'assets',
        bundleDir,
      );

      // 幂等：先清理旧内容再复制，避免 prebuild 残留过期文件。
      removeDir(destDir);
      copyDir(srcDir, destDir);

      return cfg;
    },
  ]);
}

/**
 * iOS（dangerous mod）：把 source 目录复制到 ios 工程目录下的 <bundleDir>/，
 * 供后续 withXcodeProject 以 folder reference 形式加入 bundle。
 */
function withIosWebAssetsCopy(config, { source, bundleDir }) {
  return withDangerousMod(config, [
    'ios',
    (cfg) => {
      const projectRoot = cfg.modRequest.projectRoot;
      const srcDir = path.resolve(projectRoot, source);

      if (!fs.existsSync(srcDir)) {
        console.warn(
          `[withWebAssets] 离线包源目录不存在，跳过 iOS 复制: ${srcDir}`,
        );
        return cfg;
      }

      // 放到 ios/<bundleDir>，与 .xcodeproj 同级，folder reference 用相对该处的路径。
      const destDir = path.join(cfg.modRequest.platformProjectRoot, bundleDir);
      removeDir(destDir);
      copyDir(srcDir, destDir);

      return cfg;
    },
  ]);
}

/**
 * iOS（xcode mod）：把已复制到 ios/<bundleDir> 的目录以 folder reference
 * 形式加入 app target 的 Resources。folder reference 会把整个目录树原样打进
 * main bundle（保留子目录结构），从而被静态服务按目录 serve。
 */
function withIosWebAssetsXcode(config, { bundleDir }) {
  return withXcodeProject(config, (cfg) => {
    const project = cfg.modResults;

    // 源目录不存在时 withIosWebAssetsCopy 已跳过复制，这里也无需登记。
    const iosRoot = path.join(cfg.modRequest.projectRoot, 'ios');
    const folderOnDisk = path.join(iosRoot, bundleDir);
    if (!fs.existsSync(folderOnDisk)) {
      return cfg;
    }

    const targetUuid =
      IOSConfig.XcodeUtils.getApplicationNativeTarget({
        project,
        projectName: cfg.modRequest.projectName,
      }).uuid;

    // 已登记则跳过（prebuild 可能重复执行）。
    if (project.hasFile(bundleDir)) {
      return cfg;
    }

    // lastKnownFileType: 'folder' => folder reference（蓝色目录），整目录进 bundle。
    project.addResourceFile(
      bundleDir,
      { lastKnownFileType: 'folder', target: targetUuid },
      // 加入主 group（传 undefined 时进 Resources group）。
      project.getFirstProject().firstProject.mainGroup,
    );

    return cfg;
  });
}

/**
 * @param {import('@expo/config-plugins').ExpoConfig} config
 * @param {{ source?: string, bundleDir?: string }} [props]
 */
function withWebAssets(config, props = {}) {
  const source = props.source || 'assets/web';
  const bundleDir = props.bundleDir || 'web';

  config = withAndroidWebAssets(config, { source, bundleDir });
  config = withIosWebAssetsCopy(config, { source, bundleDir });
  config = withIosWebAssetsXcode(config, { bundleDir });
  return config;
}

module.exports = withWebAssets;
