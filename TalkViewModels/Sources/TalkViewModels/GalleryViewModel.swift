import Foundation
import ChatModels
import Chat
import Combine
import ChatDTO
import ChatCore
import TalkModels
import ChatTransceiver
import SwiftUI

public final class GalleryViewModel: ObservableObject {
    public var starter: Message
    public var pictures: [Message] = []
    public var isLoading: Bool = false
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id }
    public var currentImageMessage: Message?
    public var downloadedImages: [String: Data] = [:]
    public var percent: Int64 = 0
    public var state: DownloadFileState = .UNDEFINED
    private var cancelable: Set<AnyCancellable> = []
    private var requests: [String: Any] = [:]
    public var currentData: Data? {
        guard let hashCode = currentImageMessage?.fileMetaData?.fileHash else { return nil }
        return downloadedImages[hashCode]
    }

    public init(message: Message) {
        self.starter = message
        getPictureMessages()
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink { [weak self] value in
                self?.onChatEvent(value)
            }
            .store(in: &cancelable)
    }

    private func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        case .download(let downloadEventTypes):
            onDownloadEvent(downloadEventTypes)
        default:
            break
        }
    }

    private func onMessageEvent(_ event: MessageEventTypes){
        switch event {
        case .history(let chatResponse):
            onMessages(chatResponse)
        default:
            break
        }
    }

    private func onDownloadEvent(_ event: DownloadEventTypes){
        switch event {
        case .progress(let uniqueId, let progress):
            onProgress(uniqueId, progress)
        case .image(let response, let fileURL):
            onImage(response, fileURL)
        default:
            break
        }
    }

    private func onMessages(_ response: ChatResponse<[Message]>) {
        if self.pictures.count == 0 {
            fecthMoreLeadingMessages()
            fecthMoreTrailingMessages()
        }
        pictures.append(contentsOf: response.result ?? [])
    }

    private func onImage(_ response: ChatResponse<Data>, _ fileURL: URL?) {
        if let data = response.result, let uniqueId = response.uniqueId, let request = requests[uniqueId] as? ImageRequest {
            state = .COMPLETED
            downloadedImages[request.hashCode] = data
        }

        if response.cache == false, let uniqueId = response.uniqueId {
            requests.removeValue(forKey: uniqueId)
        }
        isLoading = false
        animateObjectWillChange()
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if let progress = progress, requests[uniqueId] != nil {
            state = .DOWNLOADING
            percent = progress.percent
            animateObjectWillChange()
        }
    }

    private func getPictureMessages(count: Int = 5, fromTime: UInt? = nil, toTime: UInt? = nil) {
        guard let threadId else { return }
        let req = GetHistoryRequest(threadId: threadId,
                                    count: count,
                                    fromTime: fromTime,
                                    messageType: ChatCore.MessageType.podSpacePicture.rawValue,
                                    toTime: toTime
        )
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.message.history(req)
    }

    public func fetchImage(message: Message? = nil) {
        currentImageMessage = message ?? starter
        isLoading = true
        animateObjectWillChange()
        guard let hashCode = currentImageMessage?.fileMetaData?.file?.hashCode else { return }
        let req = ImageRequest(hashCode: hashCode, size: .ACTUAL)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)

    }

    public func fecthMoreLeadingMessages() {
        getPictureMessages(toTime: currentImageMessage?.time)
    }

    public func fecthMoreTrailingMessages() {
        getPictureMessages(fromTime: currentImageMessage?.time)
    }

    public enum Swipe {
        case next
        case previous
    }

    public func swipeTo(_ swipe: Swipe) {
        guard let currentImageMessage = currentImageMessage,
              let currentIndex = pictures.firstIndex(of: currentImageMessage)
        else { return }
            let index = currentIndex.advanced(by: swipe == .next ? 1 : -1)
        if pictures.indices.contains(index) {
            self.currentImageMessage = pictures[index]
            fetchImage()
        }
    }
}
