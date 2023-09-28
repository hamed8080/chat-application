import Chat
import ChatModels
import ChatDTO
import TalkModels
import Combine
import Foundation
import ChatCore
import ChatTransceiver
import SwiftUI

public protocol DownloadFileViewModelProtocol {
    var message: Message? { get }
    var fileHashCode: String { get }
    var data: Data? { get }
    var state: DownloadFileState { get }
    var downloadPercent: Int64 { get }
    var url: URL? { get }
    var fileURL: URL? { get }
    func setObservers()
    func startDownload()
    func pauseDownload()
    func resumeDownload()
}

public final class DownloadFileViewModel: ObservableObject, DownloadFileViewModelProtocol {
    public var downloadPercent: Int64 = 0
    public var state: DownloadFileState = .UNDEFINED
    public var tumbnailData: Data?
    public var data: Data?
    public var fileHashCode: String { message?.fileMetaData?.fileHash ?? message?.fileMetaData?.file?.hashCode ?? "" }
    var chat: Chat? { ChatManager.activeInstance }
    var uniqueId: String = ""

    public var fileURL: URL? {
        guard let url = url else { return nil }
        return chat?.file.filePath(url) ?? chat?.file.filePathInGroup(url)
    }

    public var url: URL? {
        let path = message?.isImage == true ? Routes.images.rawValue : Routes.files.rawValue
        let url = "\(ChatManager.activeInstance?.config.fileServer ?? "")\(path)/\(fileHashCode)"
        return URL(string: url)
    }

    public weak var message: Message?
    private var messageCancelable: AnyCancellable?
    private var downloadCancelable: AnyCancellable?

    public init(message: Message) {
        self.message = message
        if isInCache {
            state = .COMPLETED
            animateObjectWillChange()
        }
        setObservers()
    }

    public func setObservers() {
       downloadCancelable = NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? Message }
            .filter { $0.id == self.message?.id }
            .sink { [weak self] _ in
                self?.state = .UNDEFINED
                self?.animateObjectWillChange()
            }
       messageCancelable = NotificationCenter.default.publisher(for: .download)
            .compactMap { $0.object as? DownloadEventTypes }
            .sink { [weak self] value in
                self?.onDownloadEvent(value)
            }
    }

    private func onDownloadEvent(_ event: DownloadEventTypes){
        switch event {
        case .resumed(let uniqueId):
            onResumed(uniqueId)
        case .file(let chatResponse, let url):
            onResponse(chatResponse, url)
        case .image(let chatResponse, let url):
            onResponse(chatResponse, url)
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
        uniqueId = req.uniqueId
        RequestsManager.shared.append(value: req, autoCancel: false)
        ChatManager.activeInstance?.file.get(req)
        animateObjectWillChange()
    }

    private func downloadImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, size: .ACTUAL)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(value: req, autoCancel: false)
        ChatManager.activeInstance?.file.get(req)
        animateObjectWillChange()
    }

    public func downloadBlurImage() {
        state = .DOWNLOADING
        let req = ImageRequest(hashCode: fileHashCode, quality: 0.1, size: .SMALL, thumbnail: true)
        uniqueId = req.uniqueId
        RequestsManager.shared.append(prepend: "THUMBNAIL", value: req, autoCancel: false)
        ChatManager.activeInstance?.file.get(req)
        animateObjectWillChange()
    }

    private func onResponse(_ response: ChatResponse<Data>, _ url: URL?) {
        if response.uniqueId != uniqueId { return }
        if RequestsManager.shared.value(prepend: "THUMBNAIL", for: uniqueId) != nil, let data = response.result {
            //State is not completed and blur view can show the thumbnail
            state = .THUMBNAIL
            RequestsManager.shared.remove(prepend: "THUMBNAIL", for: uniqueId)
            autoreleasepool {
                self.tumbnailData = data
                animateObjectWillChange()
            }
            return
        }
        if RequestsManager.shared.value(for: uniqueId) != nil, let data = response.result {
            autoreleasepool {
                state = .COMPLETED
                downloadPercent = 100
                self.data = data
                animateObjectWillChange()
            }
        }

        /// When the user clicks on the side of an image not directly hit the download button, it triggers gallery view, and therefore after the user is back to the view the image and file should update properly.
        if RequestsManager.shared.value(for: uniqueId) != nil, url?.absoluteString == fileURL?.absoluteString, !response.cache {
            autoreleasepool {
                RequestsManager.shared.remove(key: uniqueId)
                state = .COMPLETED
                downloadPercent = 100
                self.data = response.result
                animateObjectWillChange()
            }
        }
    }

    private func onSuspend(_ uniqueId: String) {
        if RequestsManager.shared.value(for: self.uniqueId) != nil {
            state = .PAUSED
            animateObjectWillChange()
        }
    }

    private func onResumed(_ uniqueId: String) {
        if RequestsManager.shared.value(for: self.uniqueId) != nil {
            state = .DOWNLOADING
            animateObjectWillChange()
        }
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if RequestsManager.shared.value(for: self.uniqueId) != nil {
            self.downloadPercent = progress?.percent ?? 0
            animateObjectWillChange()
        }
    }

    public func pauseDownload() {
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniqueId, action: .suspend)
    }

    public func resumeDownload() {
        ChatManager.activeInstance?.file.manageDownload(uniqueId: uniqueId, action: .resume)
    }

    public func cancelObservers(){
        messageCancelable?.cancel()
        downloadCancelable?.cancel()

        messageCancelable = nil
        downloadCancelable = nil
    }

    deinit {
        messageCancelable?.cancel()
        downloadCancelable?.cancel()
    }
}
