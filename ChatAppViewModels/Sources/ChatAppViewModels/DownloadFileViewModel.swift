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
        return chat?.file.filePath(url) ?? chat?.file.filePathInGroup(url)
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
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? Message }
            .filter { $0.id == message.id }
            .sink { [weak self] _ in
                self?.state = .UNDEFINED
            }
            .store(in: &cancelable)
        NotificationCenter.default.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.onDownloadEvent(value)
            }
            .store(in: &cancelable)
    }

    private func onDownloadEvent(_ event: DownloadEventTypes){
        switch event {
        case .resumed(_):
            state = .DOWNLOADING
        case .file(let chatResponse, _):
            onResponse(data: chatResponse.result)
        case .image(let chatResponse, _):
            onResponse(data: chatResponse.result)
        case .suspended(_):
            state = .PAUSED
        case .progress(_, let progress):
            self.downloadPercent = progress?.percent ?? 0
        default:
            break
        }
    }

    public var isInCache: Bool {
        guard let url = url else { return false }
        return chat?.file.isFileExist(url) ?? false || chat?.file.isFileExistInGroup(url) ?? false
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
        downloadUniqueId = req.uniqueId
        ChatManager.activeInstance?.file.get(req)
    }

    private func downloadImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, forceToDownloadFromServer: true, size: .ACTUAL)
        downloadUniqueId = req.uniqueId
        ChatManager.activeInstance?.file.get(req)
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
        ChatManager.activeInstance?.file.manageDownload(uniqueId: downloadUniqueId, action: .suspend)
    }

    public func resumeDownload() {
        guard let downloadUniqueId = downloadUniqueId else { return }
        ChatManager.activeInstance?.file.manageDownload(uniqueId: downloadUniqueId, action: .resume)
    }
}
