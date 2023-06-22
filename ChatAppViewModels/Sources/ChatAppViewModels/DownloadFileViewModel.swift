import Chat
import ChatModels
import ChatDTO
import ChatAppModels
import Combine
import Foundation
import ChatCore
import ChatTransceiver

public protocol DownloadFileViewModelProtocol {
    var message: Message? { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
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

    public var requests: [String: Any] = [:]
    public var thumbRequests: [String: Any] = [:]
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
        case .resumed(let uniqueId):
            onResumed(uniqueId)
        case .file(let chatResponse, _):
            onResponse(chatResponse)
        case .image(let chatResponse, _):
            onResponse(chatResponse)
        case .suspended(let uniqueId):
            onSuspend(uniqueId)
        case .progress(let uniqueId, let progress):
            onProgress(uniqueId, progress)
        default:
            break
        }
    }

    public var isInCache: Bool {
        guard let url = url else { return false }
        return chat?.file.isFileExist(url) ?? false || chat?.file.isFileExistInGroup(url) ?? false
    }

    public func startDownload() {
        if isInCache { return }
        if message?.isImage == true {
            downloadImage()
        } else {
            downloadFile()
        }
    }

    private func downloadFile() {
        state = .DOWNLOADING
        let req = FileRequest(hashCode: fileHashCode)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)
    }

    private func downloadImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, size: .ACTUAL)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)
    }

    public func downloadBlurImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, quality: 0.1, size: .SMALL, thumbnail: true)
        thumbRequests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)
    }

    private func onResponse(_ response: ChatResponse<Data>) {
        if let uniqueId = response.uniqueId, thumbRequests[uniqueId] != nil, let data = response.result {
            //State is not completed and blur view can show the thumbnail
            state = .THUMBNAIL
            self.data = data
            thumbRequests.removeValue(forKey: uniqueId)
            return
        }
        if let data = response.result, let uniqueId = response.uniqueId, requests[uniqueId] != nil {
            requests.removeValue(forKey: uniqueId)
            state = .COMPLETED
            downloadPercent = 100
            self.data = data
        }
    }

    private func onSuspend(_ uniqueId: String) {
        if requests[uniqueId] != nil {
            state = .PAUSED
        }
    }

    private func onResumed(_ uniqueId: String) {
        if requests[uniqueId] != nil {
            state = .DOWNLOADING
        }
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if requests[uniqueId] != nil {
            self.downloadPercent = progress?.percent ?? 0
        }
    }

    public func pauseDownload() {
        guard let uniaueId = requests.first?.key else { return }
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniaueId, action: .suspend)
    }

    public func resumeDownload() {
        guard let uniaueId = requests.first?.key else { return }
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniaueId, action: .resume)
    }
}
