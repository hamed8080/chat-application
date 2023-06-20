import Combine
import Chat
import ChatModels
import ChatCore
import ChatAppModels
import ChatDTO
import Foundation

public final class AttachmentsViewModel: ObservableObject {
    public var thread: Conversation?
    @Published public var isLoading = false
    @Published public var model = AttachmentModel()
    private var cancelable: Set<AnyCancellable> = []
    private var requests: [String: Any] = [:]
    public init() {
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] value in
                self?.onMessageEvent(value)
            }
            .store(in: &cancelable)
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case .history(let response):
            onGetHistory(response)
        default:
            break
        }
    }

    public func getPictures() {
        guard let threadId = thread?.id else { return }
        let request = GetHistoryRequest(threadId: threadId, count: model.count, messageType: ChatModels.MessageType.podSpacePicture.rawValue, offset: model.offset)
        requests[request.uniqueId] = request
        ChatManager.activeInstance?.message.history(request)
    }

    private func onGetHistory(_ response: ChatResponse<[Message]>) {
        if let uniqueId = response.uniqueId, requests[uniqueId] != nil, let messages = response.result, !response.cache {
            model.appendMessages(messages: messages)
            model.setHasNext(response.hasNext)
            requests.removeValue(forKey: uniqueId)
            isLoading = false
        } else if response.cache, let messages = response.result {
            model.setMessages(messages: messages)
        }
    }

    public func loadMore() {
        if !model.hasNext || isLoading { return }
        isLoading = true
        model.preparePaginiation()
        getPictures()
    }
}
