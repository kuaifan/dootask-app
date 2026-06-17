/**
 * withAndroidShareIntent —— Android 跨 App 分享接收 config plugin（WS9）。
 *
 * Android 没有独立的 "Share Extension" 概念，ACTION_SEND / ACTION_SEND_MULTIPLE
 * intent 会直接命中主 Activity。本插件做三件事：
 *
 *  (A) AndroidManifest.xml：在 MainActivity 的 <activity> 下追加 ACTION_SEND 与
 *      ACTION_SEND_MULTIPLE 的 intent-filter，让 DooTask 出现在系统分享面板中。
 *      不破坏既有的 deep link / launcher intent-filter，并通过比对避免重复注入。
 *
 *  (B) MainActivity.kt：注入 `handleShareIntent(intent)` 方法，把分享进来的
 *      文件流（EXTRA_STREAM）复制到 `filesDir/share/<token>/files/`，写出
 *      payload.json（含 text / url），随后把当前 intent 替换为
 *      `dootask://share?token=<token>` 的 ACTION_VIEW，调用 setIntent(...)，
 *      让 expo-linking 的 URL 监听照常收到 deep link 事件。
 *      onCreate 末尾 + onNewIntent 开头各调一次；如缺 onNewIntent override，
 *      则一并补上。注入块用 marker 注释包住，保证多次 prebuild 幂等。
 *
 *  (C) imports：按需补 `import android.content.Intent` / `import android.net.Uri`。
 *
 * payload.json 形状（与 RN 侧 src/native/share.ts 约定）：
 *   {
 *     "token": "<uuid>",
 *     "createdAt": 1718600000,
 *     "items": [ { "name": "...", "mime": "...", "size": 12345, "relPath": "files/0.jpg" } ],
 *     "text": "可选纯文本",
 *     "url":  "可选 URL"
 *   }
 *
 * 用法（在 app.config.ts 的 plugins 数组追加）：
 *   './plugins/withAndroidShareIntent'
 */

const {
  withAndroidManifest,
  withMainActivity,
} = require('@expo/config-plugins');

// ---------- (A) AndroidManifest ----------

const SHARE_MIME_TYPES = ['image/*', 'video/*', 'application/*', 'text/*'];

/**
 * 构造一个 ACTION_SEND 的 intent-filter JSON 节点（manifest AST 形态）。
 */
function buildSendFilter() {
  return {
    action: [{ $: { 'android:name': 'android.intent.action.SEND' } }],
    category: [{ $: { 'android:name': 'android.intent.category.DEFAULT' } }],
    data: SHARE_MIME_TYPES.map((m) => ({ $: { 'android:mimeType': m } })),
  };
}

/**
 * 构造一个 ACTION_SEND_MULTIPLE 的 intent-filter JSON 节点。
 */
function buildSendMultipleFilter() {
  return {
    action: [{ $: { 'android:name': 'android.intent.action.SEND_MULTIPLE' } }],
    category: [{ $: { 'android:name': 'android.intent.category.DEFAULT' } }],
    data: [{ $: { 'android:mimeType': '*/*' } }],
  };
}

/**
 * 判断 intent-filter 是否已有指定 action（用于幂等检测）。
 */
function filterHasAction(filter, actionName) {
  if (!filter || !Array.isArray(filter.action)) return false;
  return filter.action.some(
    (a) => a && a.$ && a.$['android:name'] === actionName,
  );
}

function withAndroidShareManifest(config) {
  return withAndroidManifest(config, (cfg) => {
    const application = cfg.modResults.manifest.application?.[0];
    if (!application || !Array.isArray(application.activity)) {
      return cfg;
    }

    // 定位 MainActivity（Expo 模板默认就是 .MainActivity）
    const mainActivity = application.activity.find(
      (a) => a && a.$ && a.$['android:name'] === '.MainActivity',
    );
    if (!mainActivity) {
      return cfg;
    }

    if (!Array.isArray(mainActivity['intent-filter'])) {
      mainActivity['intent-filter'] = [];
    }
    const filters = mainActivity['intent-filter'];

    const hasSend = filters.some((f) =>
      filterHasAction(f, 'android.intent.action.SEND'),
    );
    if (!hasSend) {
      filters.push(buildSendFilter());
    }

    const hasSendMultiple = filters.some((f) =>
      filterHasAction(f, 'android.intent.action.SEND_MULTIPLE'),
    );
    if (!hasSendMultiple) {
      filters.push(buildSendMultipleFilter());
    }

    return cfg;
  });
}

// ---------- (B) MainActivity.kt ----------

const MARKER_BEGIN = '// DOOTASK_SHARE_INTENT_BEGIN';
const MARKER_END = '// DOOTASK_SHARE_INTENT_END';

/**
 * 注入的 Kotlin 方法体。整段被 marker 注释包住，便于幂等检测与未来移除。
 *
 * 注意：用普通 JS 模板字符串而非 dollar-brace 字符串拼接，Kotlin 自带 `$` 变量
 * 引用会与 JS 模板冲突——这里通过把 Kotlin 源码写成普通字符串拼接，避免 JS 端解析 `${...}`。
 */
const SHARE_HANDLER_KT = [
  MARKER_BEGIN,
  'private fun handleShareIntent(intent: android.content.Intent?): Boolean {',
  '    if (intent == null) return false',
  '    val action = intent.action ?: return false',
  '    if (action != android.content.Intent.ACTION_SEND && action != android.content.Intent.ACTION_SEND_MULTIPLE) return false',
  '',
  '    val token = java.util.UUID.randomUUID().toString().replace("-", "")',
  '    val shareDir = java.io.File(filesDir, "share/" + token)',
  '    val filesOut = java.io.File(shareDir, "files")',
  '    if (!filesOut.mkdirs()) {',
  '        if (!filesOut.exists()) return false',
  '    }',
  '',
  '    val items = org.json.JSONArray()',
  '    var text: String? = null',
  '    var url: String? = null',
  '',
  '    val extraText = intent.getStringExtra(android.content.Intent.EXTRA_TEXT)',
  '    if (!extraText.isNullOrBlank()) {',
  '        if (extraText.startsWith("http://") || extraText.startsWith("https://")) {',
  '            url = extraText',
  '        } else {',
  '            text = extraText',
  '        }',
  '    }',
  '',
  '    val uris = mutableListOf<android.net.Uri>()',
  '    if (action == android.content.Intent.ACTION_SEND) {',
  '        val u = intent.getParcelableExtra<android.net.Uri>(android.content.Intent.EXTRA_STREAM)',
  '        if (u != null) uris.add(u)',
  '    } else {',
  '        val list = intent.getParcelableArrayListExtra<android.net.Uri>(android.content.Intent.EXTRA_STREAM)',
  '        if (list != null) uris.addAll(list)',
  '    }',
  '',
  '    uris.forEachIndexed { index, uri ->',
  '        try {',
  '            val cr = contentResolver',
  '            val mime = cr.getType(uri) ?: intent.type ?: "application/octet-stream"',
  '            var displayName: String? = null',
  '            var size: Long = -1',
  '            cr.query(uri, null, null, null, null)?.use { cursor ->',
  '                if (cursor.moveToFirst()) {',
  '                    val nameIdx = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)',
  '                    val sizeIdx = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)',
  '                    if (nameIdx >= 0) displayName = cursor.getString(nameIdx)',
  '                    if (sizeIdx >= 0) size = cursor.getLong(sizeIdx)',
  '                }',
  '            }',
  '            val ext = displayName?.substringAfterLast(\'.\', "")?.takeIf { it.isNotBlank() }',
  '                ?: mime.substringAfterLast(\'/\', "bin")',
  '            val safeName = displayName ?: ("file_" + index + "." + ext)',
  '            val relPath = "files/" + index + "." + ext',
  '            val outFile = java.io.File(shareDir, relPath)',
  '            cr.openInputStream(uri)?.use { input ->',
  '                outFile.outputStream().use { output ->',
  '                    input.copyTo(output)',
  '                }',
  '            }',
  '            if (size < 0) size = outFile.length()',
  '',
  '            val item = org.json.JSONObject()',
  '            item.put("name", safeName)',
  '            item.put("mime", mime)',
  '            item.put("size", size)',
  '            item.put("relPath", relPath)',
  '            items.put(item)',
  '        } catch (e: Exception) {',
  '            android.util.Log.w("DooTaskShare", "copy uri failed", e)',
  '        }',
  '    }',
  '',
  '    val payload = org.json.JSONObject()',
  '    payload.put("token", token)',
  '    payload.put("createdAt", System.currentTimeMillis() / 1000)',
  '    payload.put("items", items)',
  '    if (text != null) payload.put("text", text)',
  '    if (url != null) payload.put("url", url)',
  '',
  '    java.io.File(shareDir, "payload.json").writeText(payload.toString())',
  '',
  '    val newIntent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse("dootask://share?token=" + token))',
  '    newIntent.flags = intent.flags',
  '    setIntent(newIntent)',
  '    return true',
  '}',
  MARKER_END,
].join('\n');

/**
 * 在 MainActivity.kt 中按 marker 注释幂等注入：
 *  1) 类体内追加 handleShareIntent 方法（用 marker 包住，避免重复注入）
 *  2) onCreate(...) 末尾调用 handleShareIntent(intent)
 *  3) onNewIntent(...) 存在则在开头调用；不存在则补一个 override
 *  4) 必要的 import
 */
function injectMainActivityKotlin(contents) {
  let next = contents;

  // ---- 4) imports ----
  // 用 fully-qualified 名引用 Intent/Uri，import 不强制要；但补上更友好。
  const ensureImport = (line) => {
    if (next.includes(line)) return;
    // 在第一个 import 行后插入；如没有 import 行，则在 package 行后插入。
    const importIdx = next.search(/^import\s+/m);
    if (importIdx >= 0) {
      const lineEnd = next.indexOf('\n', importIdx);
      const at = lineEnd >= 0 ? lineEnd + 1 : next.length;
      next = next.slice(0, at) + line + '\n' + next.slice(at);
    } else {
      const pkgMatch = next.match(/^package\s+[^\n]+\n/m);
      if (pkgMatch) {
        const at = pkgMatch.index + pkgMatch[0].length;
        next = next.slice(0, at) + '\n' + line + '\n' + next.slice(at);
      }
    }
  };
  ensureImport('import android.content.Intent');
  ensureImport('import android.net.Uri');

  // ---- 1) 类体内追加 handleShareIntent ----
  if (!next.includes(MARKER_BEGIN)) {
    // 定位 `class MainActivity ... {` 类声明后的匹配右花括号，把代码插入到类体末尾。
    const classMatch = next.match(/class\s+MainActivity[\s\S]*?\{/);
    if (classMatch) {
      const openIdx = classMatch.index + classMatch[0].length;
      // 简化处理：找最后一个 `}` 作为类结束括号（Kotlin 文件中 MainActivity 通常是最外层最后一个类）。
      const closeIdx = next.lastIndexOf('}');
      if (closeIdx > openIdx) {
        const block = '\n    ' + SHARE_HANDLER_KT.replace(/\n/g, '\n    ') + '\n';
        next = next.slice(0, closeIdx) + block + next.slice(closeIdx);
      }
    }
  }

  // ---- 2) onCreate 末尾调用 ----
  const onCreateCallMarker = '// DOOTASK_SHARE_INTENT_CALL_ONCREATE';
  if (!next.includes(onCreateCallMarker)) {
    // 匹配 onCreate(savedInstanceState: Bundle?) { ... super.onCreate(...) ... }
    // 在 super.onCreate(...) 调用语句之后插入 handleShareIntent(intent)
    const re =
      /(override\s+fun\s+onCreate\s*\([^)]*\)\s*\{[\s\S]*?super\.onCreate\([^)]*\)\s*\n)/;
    if (re.test(next)) {
      next = next.replace(
        re,
        (m) =>
          m +
          `        handleShareIntent(intent) ${onCreateCallMarker}\n`,
      );
    }
  }

  // ---- 3) onNewIntent ----
  const onNewIntentCallMarker = '// DOOTASK_SHARE_INTENT_CALL_ONNEWINTENT';
  const hasOnNewIntent =
    /override\s+fun\s+onNewIntent\s*\(/.test(next);

  if (hasOnNewIntent) {
    // 在已有 onNewIntent 中的 super.onNewIntent(...) 之后加调用
    if (!next.includes(onNewIntentCallMarker)) {
      const re =
        /(override\s+fun\s+onNewIntent\s*\([^)]*\)\s*\{[\s\S]*?super\.onNewIntent\([^)]*\)\s*\n)/;
      if (re.test(next)) {
        next = next.replace(
          re,
          (m) =>
            m +
            `        handleShareIntent(intent) ${onNewIntentCallMarker}\n`,
        );
      }
    }
  } else {
    // 在类体内补一个 onNewIntent override。放在 onCreate 之后；若没有 onCreate，则插入到 MARKER_BEGIN 前。
    if (!next.includes(onNewIntentCallMarker)) {
      const insertion =
        '\n' +
        '    override fun onNewIntent(intent: android.content.Intent) {\n' +
        '        super.onNewIntent(intent)\n' +
        `        handleShareIntent(intent) ${onNewIntentCallMarker}\n` +
        '    }\n';

      // 优先插在 onCreate 函数右花括号之后
      const onCreateMatch = next.match(
        /override\s+fun\s+onCreate\s*\([^)]*\)\s*\{/,
      );
      if (onCreateMatch) {
        // 从 onCreate 开始括号位置，做花括号配对找到匹配右括号
        const start = onCreateMatch.index + onCreateMatch[0].length;
        let depth = 1;
        let i = start;
        while (i < next.length && depth > 0) {
          const ch = next[i];
          if (ch === '{') depth++;
          else if (ch === '}') depth--;
          i++;
        }
        if (depth === 0) {
          next = next.slice(0, i) + insertion + next.slice(i);
        }
      } else {
        // 退化方案：插在 MARKER_BEGIN（handleShareIntent 注入块）前
        const idx = next.indexOf(MARKER_BEGIN);
        if (idx >= 0) {
          // 退回到行首
          const lineStart = next.lastIndexOf('\n', idx) + 1;
          next = next.slice(0, lineStart) + insertion + next.slice(lineStart);
        }
      }
    }
  }

  return next;
}

function withAndroidShareMainActivity(config) {
  return withMainActivity(config, (cfg) => {
    if (cfg.modResults.language !== 'kt') {
      // 仅支持 Kotlin 模板（Expo SDK 50+ 默认）
      console.warn(
        '[withAndroidShareIntent] MainActivity 非 Kotlin，跳过注入：' +
          cfg.modResults.language,
      );
      return cfg;
    }
    cfg.modResults.contents = injectMainActivityKotlin(cfg.modResults.contents);
    return cfg;
  });
}

// ---------- 组合 ----------

/**
 * @param {import('@expo/config-plugins').ExpoConfig} config
 */
function withAndroidShareIntent(config) {
  config = withAndroidShareManifest(config);
  config = withAndroidShareMainActivity(config);
  return config;
}

module.exports = withAndroidShareIntent;
// 内部函数仅用于自检测试（node --check 之外的本地烟测），运行时不调用。
module.exports.__internals = { injectMainActivityKotlin };
