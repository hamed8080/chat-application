import Chat
import ChatDTO
import ChatModels

public class UploadFileMessage: Message, UploadWithTextMessageProtocol {
    public var sendTextMessageRequest: SendTextMessageRequest?
    public var uploadFileRequest: UploadFileRequest?
    public var uploadImageRequest: UploadImageRequest?


    public init(uploadFileRequest: UploadFileRequest, sendTextMessageRequest: SendTextMessageRequest? = nil, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadFileRequest = uploadFileRequest
        super.init(uniqueId: uploadFileRequest.uniqueId)
        if let sendTextMessageRequest = sendTextMessageRequest {
            self.sendTextMessageRequest = sendTextMessageRequest
            self.uploadFileRequest = uploadFileRequest
            message = sendTextMessageRequest.textMessage
            messageType = sendTextMessageRequest.messageType
            metadata = sendTextMessageRequest.metadata
            systemMetadata = sendTextMessageRequest.systemMetadata
            threadId = sendTextMessageRequest.threadId
        }
        conversation = thread
    }

    public init(imageFileRequest: UploadImageRequest, sendTextMessageRequest: SendTextMessageRequest? = nil, thread: Conversation?) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadImageRequest = imageFileRequest
        super.init(uniqueId: imageFileRequest.uniqueId)
        if let sendTextMessageRequest = sendTextMessageRequest {
            self.sendTextMessageRequest = sendTextMessageRequest
            message = sendTextMessageRequest.textMessage
            messageType = sendTextMessageRequest.messageType
            metadata = sendTextMessageRequest.metadata
            systemMetadata = sendTextMessageRequest.systemMetadata
            threadId = sendTextMessageRequest.threadId
        }
        conversation = thread
    }

    public required init(from _: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
