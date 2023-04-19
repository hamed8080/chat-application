import Combine
import Chat
import ChatModels
import ChatCore
import ChatAppModels

public final class AttachmentsViewModel: ObservableObject {
    public var thread: Conversation?
    @Published public var isLoading = false
    @Published public var model = AttachmentModel()
    public init() {}

    public func getPictures() {
        guard let threadId = thread?.id else { return }

        ChatManager.activeInstance?.getHistory(.init(threadId: threadId, count: model.count, messageType: MessageType.podSpacePicture.rawValue, offset: model.offset)) { [weak self] response in
            if let messages = response.result {
                self?.model.appendMessages(messages: messages)
                self?.model.setHasNext(response.pagination?.hasNext ?? false)
            }
            self?.isLoading = false
        } cacheResponse: { [weak self] response in
            if let messages = response.result {
                self?.model.setMessages(messages: messages)
            }
        }
    }

    public func loadMore() {
        if !model.hasNext || isLoading { return }
        isLoading = true
        model.preparePaginiation()
        getPictures()
    }
}
