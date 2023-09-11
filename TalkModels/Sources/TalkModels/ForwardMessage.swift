import Chat
import ChatDTO
import ChatModels

public class ForwardMessage: Message, UnSentMessageProtocol {
    public var forwardMessageRequest: ForwardMessageRequest
    public var destinationThread: Conversation

    public init(from forwardMessageRequest: ForwardMessageRequest, destinationThread: Conversation, thread: Conversation?) {
        self.forwardMessageRequest = forwardMessageRequest
        self.destinationThread = destinationThread
        super.init(uniqueId: forwardMessageRequest.uniqueId)
        conversation = thread
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
