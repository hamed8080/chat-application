import Foundation
import ChatModels
import Chat
import Combine
import ChatDTO
import ChatCore

public final class GalleryViewModel: ObservableObject {
    @Published public var starter: Message
    @Published public var pictures: [Message] = []
    @Published public var isLoading: Bool = false
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id }
    public var currentImageMessage: Message?
    public var downloadedImages: [String: Data] = [:]
    @Published public var percent: Int64 = 0
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
        pictures.append(contentsOf: response.result ?? [])
    }

    private func onImage(_ response: ChatResponse<Data>, _ fileURL: URL?) {
        if let data = response.result, let uniqueId = response.uniqueId, let request = requests[uniqueId] as? ImageRequest {
            downloadedImages[request.hashCode] = data
        }

        if response.cache == false, let uniqueId = response.uniqueId {
            requests.removeValue(forKey: uniqueId)
        }
        isLoading = false
    }

    private func onProgress(_ uniqueId: String, _ progress: DownloadFileProgress?) {
        if let progress = progress, requests[uniqueId] != nil {
            percent = progress.percent
            print("percent download \(percent)")
        }
    }

    private func getPictureMessages(count: Int = 20, offset: Int = 0) {
        guard let threadId else { return }
        let req = GetHistoryRequest(threadId: threadId, messageType: ChatCore.MessageType.podSpacePicture.rawValue)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.message.history(req)
    }

    public func fetch(message: Message? = nil) {
        currentImageMessage = message ?? starter
        isLoading = true
        guard let hashCode = currentImageMessage?.fileMetaData?.file?.hashCode else { return }
        let forceDownload = downloadedImages[hashCode] == nil
        let req = ImageRequest(hashCode: hashCode, forceToDownloadFromServer: forceDownload, size: .ACTUAL)
        requests[req.uniqueId] = req
        ChatManager.activeInstance?.file.get(req)
    }

    public func fecthNext() {

    }

    public func fecthPrevious() {

    }

}
