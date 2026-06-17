//
//  ShareViewController.swift
//  DooTask Share Extension
//
//  极简 Share Extension：
//   1. 显示 loading；
//   2. 把别的 App 分享过来的图片/视频/文件/网页 URL/文本写到 App Group container 下
//      <AppGroup>/share/<token>/ 目录（payload.json + files/）；
//   3. 用 responder chain 打开 dootask://share?token=<token> 拉起主 App；
//   4. 主 App 启动时会把 App Group 下 share/* 搬运到 documentDirectory 供 RN 读取。
//
//  本控制器不调用任何后端 API，不做会话选择 UI。
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    // MARK: - Constants

    private static let appGroupId = "group.im.dootask"
    private static let deepLinkScheme = "dootask"
    private static let payloadVersion = 1

    // MARK: - UI

    private let activityIndicator: UIActivityIndicatorView = {
        let v: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            v = UIActivityIndicatorView(style: .large)
        } else {
            v = UIActivityIndicatorView(style: .whiteLarge)
        }
        v.hidesWhenStopped = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var statusLabel: UILabel = {
        let l = UILabel()
        l.text = "正在分享…"
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("取消", for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        b.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - State

    private let token = UUID().uuidString
    private var collectedItems: [[String: Any]] = []
    private var collectedText: String?
    private var collectedURL: String?
    private var fileIndex = 0
    private let collectQueue = DispatchQueue(label: "im.dootask.share.collect", qos: .userInitiated)
    private var didFinish = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])

        activityIndicator.startAnimating()

        collectQueue.async { [weak self] in
            self?.processAttachments()
        }
    }

    // MARK: - Cancel

    @objc private func handleCancel() {
        guard !didFinish else { return }
        didFinish = true
        let err = NSError(domain: "im.dootask.share", code: -1, userInfo: nil)
        extensionContext?.cancelRequest(withError: err)
    }

    private func finishWithError(_ message: String) {
        guard !didFinish else { return }
        didFinish = true
        let err = NSError(domain: "im.dootask.share", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: message])
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.cancelRequest(withError: err)
        }
    }

    private func finishSuccess() {
        guard !didFinish else { return }
        didFinish = true
        DispatchQueue.main.async { [weak self] in
            self?.openMainAppAndComplete()
        }
    }

    // MARK: - Attachment processing

    private func processAttachments() {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem],
              !inputItems.isEmpty else {
            finishWithError("没有分享内容")
            return
        }

        // App Group container 下的 token 目录
        guard let baseDir = ensureShareDirectory() else {
            finishWithError("无法访问共享存储")
            return
        }

        let group = DispatchGroup()

        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    group.enter()
                    loadImage(provider: provider, baseDir: baseDir) { group.leave() }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    group.enter()
                    loadFile(provider: provider, typeId: UTType.movie.identifier,
                             baseDir: baseDir) { group.leave() }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    group.enter()
                    loadFile(provider: provider, typeId: UTType.fileURL.identifier,
                             baseDir: baseDir) { group.leave() }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    loadURL(provider: provider) { group.leave() }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    loadText(provider: provider) { group.leave() }
                }
            }
        }

        group.notify(queue: collectQueue) { [weak self] in
            self?.writePayloadAndFinish(baseDir: baseDir)
        }
    }

    // MARK: - Loaders

    private func loadImage(provider: NSItemProvider, baseDir: URL, done: @escaping () -> Void) {
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, _ in
            guard let self = self else { done(); return }
            self.collectQueue.async {
                defer { done() }
                if let url = item as? URL {
                    self.copyFile(from: url, baseDir: baseDir, suggestedExt: url.pathExtension)
                } else if let data = item as? Data {
                    self.writeData(data, baseDir: baseDir, ext: "jpg", mime: "image/jpeg")
                } else if let image = item as? UIImage,
                          let data = image.jpegData(compressionQuality: 0.9) {
                    self.writeData(data, baseDir: baseDir, ext: "jpg", mime: "image/jpeg")
                }
            }
        }
    }

    private func loadFile(provider: NSItemProvider, typeId: String, baseDir: URL,
                          done: @escaping () -> Void) {
        provider.loadItem(forTypeIdentifier: typeId, options: nil) { [weak self] item, _ in
            guard let self = self else { done(); return }
            self.collectQueue.async {
                defer { done() }
                guard let url = item as? URL else { return }
                self.copyFile(from: url, baseDir: baseDir, suggestedExt: url.pathExtension)
            }
        }
    }

    private func loadURL(provider: NSItemProvider, done: @escaping () -> Void) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
            guard let self = self else { done(); return }
            self.collectQueue.async {
                defer { done() }
                if let url = item as? URL {
                    self.collectedURL = url.absoluteString
                } else if let s = item as? String {
                    self.collectedURL = s
                }
            }
        }
    }

    private func loadText(provider: NSItemProvider, done: @escaping () -> Void) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
            guard let self = self else { done(); return }
            self.collectQueue.async {
                defer { done() }
                if let s = item as? String {
                    self.collectedText = s
                }
            }
        }
    }

    // MARK: - File IO

    private func ensureShareDirectory() -> URL? {
        let fm = FileManager.default
        guard let container = fm.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupId
        ) else {
            return nil
        }
        let tokenDir = container
            .appendingPathComponent("share", isDirectory: true)
            .appendingPathComponent(token, isDirectory: true)
        let filesDir = tokenDir.appendingPathComponent("files", isDirectory: true)
        do {
            try fm.createDirectory(at: filesDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return nil
        }
        return tokenDir
    }

    private func copyFile(from src: URL, baseDir: URL, suggestedExt: String) {
        let fm = FileManager.default
        let ext = suggestedExt.isEmpty ? "dat" : suggestedExt.lowercased()
        let index = fileIndex; fileIndex += 1
        let relPath = "files/\(index).\(ext)"
        let dst = baseDir.appendingPathComponent(relPath)
        do {
            if fm.fileExists(atPath: dst.path) {
                try fm.removeItem(at: dst)
            }
            try fm.copyItem(at: src, to: dst)
            let size = (try? fm.attributesOfItem(atPath: dst.path)[.size] as? NSNumber)?.intValue ?? 0
            collectedItems.append([
                "name": src.lastPathComponent,
                "mime": mimeType(forExtension: ext),
                "size": size,
                "relPath": relPath,
            ])
        } catch {
            // 单个文件失败不阻断整批，跳过
        }
    }

    private func writeData(_ data: Data, baseDir: URL, ext: String, mime: String) {
        let index = fileIndex; fileIndex += 1
        let relPath = "files/\(index).\(ext)"
        let dst = baseDir.appendingPathComponent(relPath)
        do {
            try data.write(to: dst, options: .atomic)
            collectedItems.append([
                "name": "image_\(index).\(ext)",
                "mime": mime,
                "size": data.count,
                "relPath": relPath,
            ])
        } catch {
            // 跳过失败项
        }
    }

    private func mimeType(forExtension ext: String) -> String {
        if #available(iOS 14.0, *) {
            if let t = UTType(filenameExtension: ext)?.preferredMIMEType { return t }
        } else {
            let tag = ext as CFString
            if let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension, tag, nil)?.takeRetainedValue(),
               let mime = UTTypeCopyPreferredTagWithClass(
                uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mime as String
            }
        }
        return "application/octet-stream"
    }

    // MARK: - Payload + finish

    private func writePayloadAndFinish(baseDir: URL) {
        let hasContent = !collectedItems.isEmpty
            || (collectedText?.isEmpty == false)
            || (collectedURL?.isEmpty == false)
        guard hasContent else {
            finishWithError("没有可分享内容")
            return
        }

        var payload: [String: Any] = [
            "token": token,
            "version": Self.payloadVersion,
            "createdAt": Int(Date().timeIntervalSince1970),
            "items": collectedItems,
        ]
        if let t = collectedText, !t.isEmpty { payload["text"] = t }
        if let u = collectedURL, !u.isEmpty { payload["url"] = u }

        let payloadURL = baseDir.appendingPathComponent("payload.json")
        do {
            let data = try JSONSerialization.data(
                withJSONObject: payload, options: [.prettyPrinted])
            try data.write(to: payloadURL, options: .atomic)
        } catch {
            finishWithError("写入失败")
            return
        }

        finishSuccess()
    }

    private func openMainAppAndComplete() {
        let urlString = "\(Self.deepLinkScheme)://share?token=\(token)"
        if let url = URL(string: urlString) {
            // Responder chain hack：UIViewController.extensionContext.open 在 share-services
            // 上不可用，需要向上找能响应 UIApplication.open(_:options:completionHandler:) 的 responder。
            var responder: UIResponder? = self
            let selector = NSSelectorFromString("openURL:")
            while let r = responder {
                if r.responds(to: selector) {
                    _ = r.perform(selector, with: url)
                    break
                }
                responder = r.next
            }
        }
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
