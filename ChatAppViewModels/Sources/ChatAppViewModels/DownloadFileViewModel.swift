import Chat
import ChatModels
import ChatDTO
import ChatAppModels
import Combine
import Foundation
import ChatCore

public protocol DownloadFileViewModelProtocol {
    var message: Message? { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
    var downloadUniqueId: String? { get }
    var downloadPercent: Int64 { get }
    var url: URL? { get }
    var fileURL: URL? { get }
    func setMessage(message: Message)
    func startDownload()
    func pauseDownload()
    func resumeDownload()
}

public final class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    @Published public var downloadPercent: Int64 = 0
    @Published public var state: DownloadFileState = .UNDEFINED
    @Published public var data: Data?
    public var fileHashCode: String { message?.fileMetaData?.fileHash ?? message?.fileMetaData?.file?.hashCode ?? "" }
    let chat = ChatManager.activeInstance

    public var fileURL: URL? {
        guard let url = url else { return nil }
        return chat?.filePath(url) ?? chat?.filePathInGroup(url)
    }

    public var url: URL? {
        let path = message?.isImage == true ? Routes.images.rawValue : Routes.files.rawValue
        let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
        return URL(string: url)
    }

    public var downloadUniqueId: String?
    public private(set) var message: Message?
    private var cancelable: Set<AnyCancellable> = []

    public init() {}

    public func setMessage(message: Message) {
        self.message = message
        if isInCache {
            state = .COMPLETED
        }
        NotificationCenter.default.publisher(for: .fileDeletedFromCacheName)
            .compactMap { $0.object as? Message }
            .filter { $0.id == message.id }
            .sink { [weak self] _ in
                self?.state = .UNDEFINED
            }
            .store(in: &cancelable)
    }

    public var isInCache: Bool {
        guard let url = url else { return false }
        return chat?.isFileExist(url) ?? false || chat?.isFileExistInGroup(url) ?? false
    }

    public func startDownload() {
        if !isInCache, message?.isImage == true {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    private func downloadFile() {
        state = .DOWNLOADING
        let req = FileRequest(hashCode: fileHashCode, forceToDownloadFromServer: true)
        ChatManager.activeInstance?.getFile(req) { downloadProgress in
            self.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] _, url, _, _ in
            if let url = url, let data = self?.chat?.getData(url) {
                self?.onResponse(data: data)
            }
        } uniqueIdResult: { uniqueId in
            self.downloadUniqueId = uniqueId
        }
    }

    private func downloadImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: true, size: .ACTUAL)
        ChatManager.activeInstance?.getImage(req) { [weak self] downloadProgress in
            self?.downloadPercent = downloadProgress.percent
        } completion: { [weak self] data, _, _, _ in
            self?.onResponse(data: data)
        } cacheResponse: { [weak self] _, url, _, _ in
            if let url = url, let data = self?.chat?.getData(url) {
                self?.onResponse(data: data)
            }
        } uniqueIdResult: { [weak self] uniqueId in
            self?.downloadUniqueId = uniqueId
        }
    }

    private func onResponse(data: Data?) {
        if let data = data {
            state = .COMPLETED
            downloadPercent = 100
            self.data = data
        }
    }

    public func pauseDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        ChatManager.activeInstance?.manageDownload(uniqueId: downloadUniqueId, action: .suspend) { [weak self] _, _ in
            self?.state = .PAUSED
        }
    }

    public func resumeDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        ChatManager.activeInstance?.manageDownload(uniqueId: downloadUniqueId, action: .resume) { [weak self] _, _ in
            self?.state = .DOWNLOADING
        }
    }
}
