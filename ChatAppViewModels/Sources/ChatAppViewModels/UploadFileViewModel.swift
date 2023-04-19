import Chat
import ChatModels
import Combine
import ChatAppModels
import ChatDTO
import ChatCore

public final class UploadFileViewModel: ObservableObject {
    @Published public private(set) var uploadPercent: Int64 = 0
    @Published public var state: UploadFileState = .STARTED
    public var message: Message?
    public var uploadFileWithTextMessage: UploadWithTextMessageProtocol { message as! UploadWithTextMessageProtocol }
    public var thread: Conversation?
    public var uploadUniqueId: String?

    public init() {}

    public func startUpload(message: Message, thread: Conversation?) {
        if state == .COMPLETED { return }
        self.message = message
        self.thread = thread
        state = .STARTED
        guard let threadId = thread?.id else { return }
        let textMessageType: MessageType = uploadFileWithTextMessage.uploadFileRequest is UploadImageRequest ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        uploadFile(message, uploadFileWithTextMessage.uploadFileRequest)
    }

    public func uploadFile(_ message: SendTextMessageRequest, _ uploadFileRequest: UploadFileRequest) {
        ChatManager.activeInstance?.sendFileMessage(textMessage: message, uploadFile: uploadFileRequest) { uploadFileProgress, _ in
            self.uploadPercent = uploadFileProgress?.percent ?? 0
        } onSent: { response in
            print(response.result ?? "")
            if response.error == nil {
                self.state = .COMPLETED
            }
        } onSeen: { response in
            print(response.result ?? "")
        } onDeliver: { response in
            print(response.result ?? "")
        } uploadUniqueIdResult: { uploadUniqueId in
            self.uploadUniqueId = uploadUniqueId
        } messageUniqueIdResult: { messageUniqueId in
            print(messageUniqueId)
        }
    }

    public func pauseUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.manageUpload(uniqueId: uploadUniqueId, action: .suspend) { _, _ in
            self.state = .PAUSED
        }
    }

    public func resumeUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.manageUpload(uniqueId: uploadUniqueId, action: .resume) { _, _ in
            self.state = .UPLOADING
        }
    }
}
