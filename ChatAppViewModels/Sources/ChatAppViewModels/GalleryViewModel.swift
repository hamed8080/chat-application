import Foundation
import ChatModels
import Chat
import Combine

public final class GalleryViewModel: ObservableObject {
    @Published public var starter: Message
    @Published public var pictures: [Message] = []
    @Published public var isLoading: Bool = false
    var thread: Conversation? { starter.conversation }
    var threadId: Int? { thread?.id }
    public var currentImageMessage: Message?
    public var downloadedImages: [String: Data] = [:]
    @Published public var percent: Int64 = 0
    public var currentData: Data? {
        guard let hashCode = currentImageMessage?.fileMetaData?.fileHash else { return nil }
        return downloadedImages[hashCode]
    }
    
    private var cancelable: Set<AnyCancellable> = []

    public init(message: Message) {
        self.starter = message
        getPictureMessages()
    }

    private func getPictureMessages(count: Int = 20, offset: Int = 0) {
        guard let threadId else { return }
        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, messageType: MessageType.podSpacePicture.rawValue)) { [weak self] response in
            self?.pictures.append(contentsOf: response.result ?? [])
        } cacheResponse: { _ in }

        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, messageType: MessageType.podSpacePicture.rawValue)) { [weak self] response in
            self?.pictures.append(contentsOf: response.result ?? [])
        } cacheResponse: { _ in }
    }

    public func fetch(message: Message? = nil) {
        currentImageMessage = message ?? starter
        isLoading = true
        guard let hashCode = currentImageMessage?.fileMetaData?.file?.hashCode else { return }
        let forceDownload = downloadedImages[hashCode] == nil
        ChatManager.activeInstance?.getImage(.init(hashCode: hashCode, forceToDownloadFromServer: forceDownload, size: .ACTUAL)) { [weak self] progress in
            self?.percent = progress.percent
            print("percent download \(self?.percent ?? 0)")
        } completion: { [weak self] data, url, image, error in
            if let data = data {
                self?.downloadedImages[hashCode] = data
            }
            self?.isLoading = false
        } cacheResponse: { [weak self] data, url, image, error in
            if let data = data {
                self?.downloadedImages[hashCode] = data
            }
            self?.isLoading = false
        }
    }

    public func fecthNext() {

    }

    public func fecthPrevious() {

    }

}
