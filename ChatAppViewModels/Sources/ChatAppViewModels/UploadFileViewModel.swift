import Chat
import ChatModels
import Combine
import ChatAppModels
import ChatDTO
import ChatCore
import Foundation
import ChatTransceiver

public final class UploadFileViewModel: ObservableObject {
    @Published public private(set) var uploadPercent: Int64 = 0
    @Published public var state: UploadFileState = .STARTED
    public var message: Message?
    public var uploadFileWithTextMessage: UploadWithTextMessageProtocol { message as! UploadWithTextMessageProtocol }
    public var thread: Conversation?
    public var uploadUniqueId: String?
    public private(set) var cancelable: Set<AnyCancellable> = []

    public init() {
        NotificationCenter.default.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink(receiveValue: onUploadEvent)
            .store(in: &cancelable)
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .suspended(let uniqueId):
            onPause(uniqueId)
        case .resumed(let uniqueId):
            onResume(uniqueId)
        case .progress(let uniqueId, let uploadFileProgress):
            onUploadProgress(uniqueId, uploadFileProgress)
        case .completed(let uniqueId, _, let data, let error):
            onCompeletedUpload(uniqueId, data, error)
        default:
            break
        }
    }

    public func startUploadFile(message: Message, thread: Conversation?) {
        if state == .COMPLETED { return }
        self.message = message
        self.thread = thread
        state = .STARTED
        guard let threadId = thread?.id else { return }
        let isImage: Bool = message.isImage
        let textMessageType: ChatModels.MessageType = isImage ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        if let fileRequest = uploadFileWithTextMessage.uploadFileRequest {
            uploadFile(message, fileRequest)
        }
    }

    public func startUploadImage(message: Message, thread: Conversation?) {
        if state == .COMPLETED { return }
        self.message = message
        self.thread = thread
        state = .STARTED
        guard let threadId = thread?.id else { return }
        let isImage: Bool = message.isImage
        let textMessageType: ChatModels.MessageType = isImage ? .podSpacePicture : .podSpaceFile
        let message = SendTextMessageRequest(threadId: threadId, textMessage: message.message ?? "", messageType: textMessageType)
        if let imageRequest = uploadFileWithTextMessage.uploadImageRequest {
            uploadImage(message, imageRequest)
        }
    }

    public func uploadFile(_ message: SendTextMessageRequest, _ uploadFileRequest: UploadFileRequest) {
        uploadUniqueId = uploadFileRequest.uniqueId
        ChatManager.activeInstance?.message.send(message, uploadFileRequest)
    }

    public func uploadImage(_ message: SendTextMessageRequest, _ uploadImageRequest: UploadImageRequest) {
        uploadUniqueId = uploadImageRequest.uniqueId
        ChatManager.activeInstance?.message.send(message, uploadImageRequest)
    }

    private func onUploadProgress(_ uniqueId: String, _ uploadFileProgress: UploadFileProgress?) {
        if uniqueId == uploadUniqueId {
            uploadPercent = uploadFileProgress?.percent ?? 0
        }
    }

    private func onCompeletedUpload(_ uniqueId: String, _ data: Data?, _ error: Error?) {
        if uniqueId == uploadUniqueId {
            state = .COMPLETED
        }
    }

    public func pauseUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: .suspend)
    }

    private func onPause(_ uniqueId: String) {
        if uniqueId == uploadUniqueId {
            state = .PAUSED
        }
    }

    public func resumeUpload() {
        guard let uploadUniqueId = uploadUniqueId else { return }
        ChatManager.activeInstance?.file.manageUpload(uniqueId: uploadUniqueId, action: .resume)
    }

    private func onResume(_ uniqueId: String) {
        if uniqueId == uploadUniqueId {
            state = .UPLOADING
        }
    }
}
