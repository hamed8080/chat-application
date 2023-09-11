import Chat
import ChatDTO
import ChatModels

public class SendTextMessage: Message, UnSentMessageProtocol {
    public var sendTextMessageRequest: SendTextMessageRequest

    public init(from sendTextMessageRequest: SendTextMessageRequest, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        super.init(threadId: sendTextMessageRequest.threadId,
                   message: sendTextMessageRequest.textMessage,
                   uniqueId: sendTextMessageRequest.uniqueId)
        conversation = thread
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
