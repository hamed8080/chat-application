import Chat
import ChatModels
import ChatDTO

public final class EditTextMessage: Message, UnSentMessageProtocol {
    public var editMessageRequest: EditMessageRequest

    public init(from editMessageRequest: EditMessageRequest, thread: Conversation?) {
        self.editMessageRequest = editMessageRequest
        super.init(threadId: editMessageRequest.threadId,
                   message: editMessageRequest.textMessage,
                   uniqueId: editMessageRequest.uniqueId)
        conversation = thread
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
