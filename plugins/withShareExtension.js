/**
 * withShareExtension —— DooTask 移动端 iOS Share Extension 注入 config plugin（WS8）。
 *
 * 在 `expo prebuild` 时：
 *  1. 拷贝 `plugins/share-extension-template/` 三个模板文件到 `ios/ShareExtension/`；
 *  2. 在 .pbxproj 中创建 `ShareExtension` 应用扩展 target（app_extension）：
 *      - Sources phase 含 ShareViewController.swift
 *      - Frameworks phase 链接 UIKit、MobileCoreServices
 *      - 设置 INFOPLIST_FILE / PRODUCT_BUNDLE_IDENTIFIER / SWIFT_VERSION /
 *        IPHONEOS_DEPLOYMENT_TARGET / CODE_SIGN_ENTITLEMENTS / SWIFT_VERSION
 *      - 自动作为主 App 的 PBXTargetDependency + Embed App Extensions phase
 *        （xcode 库的 addTarget('app_extension') 会处理 CopyFiles 嵌入）；
 *  3. 主 App entitlements 增加 com.apple.security.application-groups = [group.im.dootask]；
 *  4. 在主 App 的 AppDelegate.swift 末尾注入 `migrateSharedSharePayloads` C 函数，并在
 *     didFinishLaunchingWithOptions / applicationDidBecomeActive 末尾调用，把
 *     App Group container 下的 share/<token>/ 搬到 documentDirectory，
 *     RN 端 expo-file-system 即可读到。
 *
 * 用法（在 app.config.ts 的 plugins 数组加）：
 *   './plugins/withShareExtension'
 *
 * 不写真机签名相关字段（DEVELOPMENT_TEAM、CODE_SIGN_STYLE 等），交给 EAS / Xcode 处理。
 */

const fs = require('fs');
const path = require('path');
const {
  withXcodeProject,
  withEntitlementsPlist,
  withDangerousMod,
  withAppDelegate,
} = require('@expo/config-plugins');

const EXT_NAME = 'ShareExtension';
const EXT_BUNDLE_SUFFIX = '.shareExtension'; // 旧 EEUI 同名后缀
const APP_GROUP_ID = 'group.im.dootask';
const SWIFT_VERSION = '5.0';
const DEPLOYMENT_TARGET = '15.1'; // Expo SDK 54 默认 iOS 15.1，与主 App 对齐

const TEMPLATE_DIR = path.join(__dirname, 'share-extension-template');
const TEMPLATE_FILES = [
  'ShareViewController.swift',
  'Info.plist',
  'ShareExtension.entitlements',
];

// 注入 AppDelegate 用的标记串，幂等判定
const MIGRATE_MARKER = '// DooTaskShareExtensionMigrate-Marker';
const MIGRATE_CALL = 'DooTaskShareExtensionMigrate.migrate()';

// ---------------------------------------------------------------------------
// 1. 复制模板文件 + 准备 ios/ShareExtension 目录
// ---------------------------------------------------------------------------

function withCopyShareExtensionTemplate(config) {
  return withDangerousMod(config, [
    'ios',
    (cfg) => {
      const destDir = path.join(
        cfg.modRequest.platformProjectRoot,
        EXT_NAME,
      );
      fs.mkdirSync(destDir, { recursive: true });
      for (const name of TEMPLATE_FILES) {
        const src = path.join(TEMPLATE_DIR, name);
        const dst = path.join(destDir, name);
        if (!fs.existsSync(src)) {
          throw new Error(
            `[withShareExtension] 缺少模板文件: ${src}`,
          );
        }
        fs.copyFileSync(src, dst);
      }
      return cfg;
    },
  ]);
}

// ---------------------------------------------------------------------------
// 2. 主 App entitlements 增加 App Group
// ---------------------------------------------------------------------------

function withAppGroupEntitlement(config) {
  return withEntitlementsPlist(config, (cfg) => {
    const key = 'com.apple.security.application-groups';
    const existing = cfg.modResults[key];
    const list = Array.isArray(existing) ? existing.slice() : [];
    if (!list.includes(APP_GROUP_ID)) {
      list.push(APP_GROUP_ID);
    }
    cfg.modResults[key] = list;
    return cfg;
  });
}

// ---------------------------------------------------------------------------
// 3. .pbxproj：创建 Extension target 与各个 build phase
// ---------------------------------------------------------------------------

function withShareExtensionXcodeTarget(config) {
  return withXcodeProject(config, (cfg) => {
    const project = cfg.modResults;
    const mainBundleId =
      (cfg.ios && cfg.ios.bundleIdentifier) || 'com.dootask.task';
    const extBundleId = mainBundleId + EXT_BUNDLE_SUFFIX;

    // ---- 幂等：已存在则跳过 ----
    const existing = findNativeTargetByName(project, EXT_NAME);
    if (existing) {
      return cfg;
    }

    // ---- 创建 PBXGroup（ios/ShareExtension）----
    // 用 path-relative-to-ios 加入主 group，便于 Xcode 中可见
    const pbxGroup = project.addPbxGroup(
      [], // children 后面单独加，避免 addTarget 重复添加
      EXT_NAME,
      EXT_NAME,
      '"<group>"',
    );
    // 挂到主 group
    const mainGroupUuid =
      project.getFirstProject().firstProject.mainGroup;
    project.addToPbxGroup(pbxGroup.uuid, mainGroupUuid);

    // ---- 创建 app_extension target（xcode 库会自动建 CopyFiles 嵌入 phase + dependency）----
    // 注意：addTarget 的 INFOPLIST_FILE 默认是 "<subfolder>/<subfolder>-Info.plist"，
    // 而我们的模板文件叫 Info.plist；下面手改 build settings 修正。
    const target = project.addTarget(
      EXT_NAME,
      'app_extension',
      EXT_NAME, // subfolder = ShareExtension
      extBundleId,
    );

    // ---- Sources phase：含 ShareViewController.swift ----
    project.addBuildPhase(
      ['ShareViewController.swift'],
      'PBXSourcesBuildPhase',
      'Sources',
      target.uuid,
    );

    // ---- Resources phase（占位，模板暂无 xib/storyboard，但保留以便扩展）----
    project.addBuildPhase(
      [],
      'PBXResourcesBuildPhase',
      'Resources',
      target.uuid,
    );

    // ---- Frameworks phase + 框架 ----
    project.addBuildPhase(
      [],
      'PBXFrameworksBuildPhase',
      'Frameworks',
      target.uuid,
    );
    project.addFramework('UIKit.framework', { target: target.uuid });
    project.addFramework('MobileCoreServices.framework', {
      target: target.uuid,
    });

    // ---- 把模板源文件登记到 ShareExtension 组里（让 Xcode 工程显示）----
    // 仅添加 PBXFileReference（addSourceFile 会重复登记到 build phase，这里用 addFile）
    addFileReferenceToGroup(
      project,
      'ShareViewController.swift',
      EXT_NAME,
      pbxGroup.uuid,
    );
    addFileReferenceToGroup(
      project,
      'Info.plist',
      EXT_NAME,
      pbxGroup.uuid,
    );
    addFileReferenceToGroup(
      project,
      'ShareExtension.entitlements',
      EXT_NAME,
      pbxGroup.uuid,
    );

    // ---- 调整 build settings：Info.plist 路径、Swift 版本、部署目标、Entitlements 等 ----
    const cfgList = project.pbxXCBuildConfigurationSection();
    for (const key of Object.keys(cfgList)) {
      if (/_comment$/.test(key)) continue;
      const item = cfgList[key];
      if (!item || typeof item !== 'object') continue;
      const settings = item.buildSettings;
      if (!settings) continue;
      // 仅修改属于本 target 的 configuration（通过 PRODUCT_NAME 识别）
      if (
        settings.PRODUCT_NAME === `"${EXT_NAME}"` ||
        settings.PRODUCT_NAME === EXT_NAME
      ) {
        settings.INFOPLIST_FILE = `"${EXT_NAME}/Info.plist"`;
        settings.CODE_SIGN_ENTITLEMENTS = `"${EXT_NAME}/ShareExtension.entitlements"`;
        settings.PRODUCT_BUNDLE_IDENTIFIER = `"${extBundleId}"`;
        settings.SWIFT_VERSION = SWIFT_VERSION;
        settings.IPHONEOS_DEPLOYMENT_TARGET = DEPLOYMENT_TARGET;
        settings.TARGETED_DEVICE_FAMILY = '"1,2"';
        settings.CLANG_ENABLE_MODULES = 'YES';
        settings.SWIFT_OPTIMIZATION_LEVEL =
          item.name === 'Debug' ? '"-Onone"' : '"-O"';
        // 让 EAS / Xcode 自动管理签名；CI 上由凭证覆盖
        settings.CODE_SIGN_STYLE = 'Automatic';
        // 启用 App Sandbox 不需要在 iOS Extension 中显式声明，留空
      }
    }

    return cfg;
  });
}

/** 在 PBXFileReference 段登记一个文件并挂到指定 group。 */
function addFileReferenceToGroup(project, filename, subfolder, groupUuid) {
  // 用 xcode 提供的 pbxFile 构造，再手工塞进 reference section + group
  const pbxFile = require('xcode/lib/pbxFile');
  const file = new pbxFile(path.join(subfolder, filename));
  // 若已登记则跳过
  const refSection = project.pbxFileReferenceSection();
  for (const key of Object.keys(refSection)) {
    if (/_comment$/.test(key)) continue;
    const v = refSection[key];
    if (
      v &&
      typeof v === 'object' &&
      v.path &&
      v.path.replace(/"/g, '') === file.path
    ) {
      return;
    }
  }
  file.fileRef = project.generateUuid();
  project.addToPbxFileReferenceSection(file);
  project.addToPbxGroup(file, groupUuid);
}

/** 按 name 查 PBXNativeTarget；用来做幂等判断。 */
function findNativeTargetByName(project, name) {
  const targets = project.pbxNativeTargetSection();
  for (const key of Object.keys(targets)) {
    if (/_comment$/.test(key)) continue;
    const t = targets[key];
    if (!t || typeof t !== 'object') continue;
    const tName = (t.name || '').replace(/"/g, '');
    if (tName === name) return { uuid: key, target: t };
  }
  return null;
}

// ---------------------------------------------------------------------------
// 4. 注入 AppDelegate.swift —— share payload 跨沙箱迁移
// ---------------------------------------------------------------------------

const MIGRATE_HELPER_SWIFT = `

${MIGRATE_MARKER}
// DooTask Share Extension —— 把 App Group container 下 share/<token>/ 搬到
// 主 App documentDirectory，让 RN expo-file-system 能直接读到。
// 由 plugins/withShareExtension.js 注入，请勿手改。
import Foundation
enum DooTaskShareExtensionMigrate {
    static let appGroupId = "${APP_GROUP_ID}"
    static func migrate() {
        let fm = FileManager.default
        guard let container = fm.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId
        ) else { return }
        let srcRoot = container.appendingPathComponent("share", isDirectory: true)
        guard fm.fileExists(atPath: srcRoot.path) else { return }
        guard let docs = fm.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first else { return }
        let dstRoot = docs.appendingPathComponent("share", isDirectory: true)
        try? fm.createDirectory(at: dstRoot, withIntermediateDirectories: true)
        let tokenDirs = (try? fm.contentsOfDirectory(
            at: srcRoot, includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles])) ?? []
        for src in tokenDirs {
            let dst = dstRoot.appendingPathComponent(src.lastPathComponent)
            if fm.fileExists(atPath: dst.path) {
                try? fm.removeItem(at: dst)
            }
            do {
                try fm.moveItem(at: src, to: dst)
            } catch {
                // 跨卷无法 move 时退化为 copy + remove
                if (try? fm.copyItem(at: src, to: dst)) != nil {
                    try? fm.removeItem(at: src)
                }
            }
        }
    }
}
`;

function withAppDelegateMigration(config) {
  return withAppDelegate(config, (cfg) => {
    let contents = cfg.modResults.contents;
    const language = cfg.modResults.language;

    if (language !== 'swift') {
      console.warn(
        '[withShareExtension] AppDelegate 不是 Swift（lang=' +
          language +
          '），跳过 share payload 迁移注入。',
      );
      return cfg;
    }

    // ---- 4a. 在文件末尾追加 helper enum（幂等：检查 marker） ----
    if (!contents.includes(MIGRATE_MARKER)) {
      contents = contents.replace(/\s*$/, '\n') + MIGRATE_HELPER_SWIFT;
    }

    // ---- 4b. 在 didFinishLaunchingWithOptions / applicationDidBecomeActive 注入调用 ----
    // 优先在 didFinishLaunchingWithOptions 的 return 前插。
    if (!contents.includes(MIGRATE_CALL)) {
      const didFinishRe =
        /(func\s+application\s*\([^)]*didFinishLaunchingWithOptions[^{]*\{)/;
      if (didFinishRe.test(contents)) {
        contents = contents.replace(
          didFinishRe,
          `$1\n    ${MIGRATE_CALL}`,
        );
      } else {
        // 退化方案：找不到 didFinishLaunchingWithOptions 时，把调用塞进
        // applicationDidBecomeActive。仍找不到则警告并放弃。
        const didBecomeActiveRe =
          /(func\s+applicationDidBecomeActive\s*\([^)]*\)[^{]*\{)/;
        if (didBecomeActiveRe.test(contents)) {
          contents = contents.replace(
            didBecomeActiveRe,
            `$1\n    ${MIGRATE_CALL}`,
          );
        } else {
          console.warn(
            '[withShareExtension] 未在 AppDelegate.swift 找到 didFinishLaunchingWithOptions / applicationDidBecomeActive，跳过迁移调用注入。',
          );
        }
      }
    }

    cfg.modResults.contents = contents;
    return cfg;
  });
}

// ---------------------------------------------------------------------------
// 顶层入口
// ---------------------------------------------------------------------------

function withShareExtension(config) {
  config = withCopyShareExtensionTemplate(config);
  config = withAppGroupEntitlement(config);
  config = withShareExtensionXcodeTarget(config);
  config = withAppDelegateMigration(config);
  return config;
}

module.exports = withShareExtension;
