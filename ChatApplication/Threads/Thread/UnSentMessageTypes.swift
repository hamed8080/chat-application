//
//  UnSentMessageTypes.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/27/21.
//

import FanapPodChatSDK
import Foundation
protocol UnSentMessageProtocol {}
class SendTextMessage: Message, UnSentMessageProtocol {
    var sendTextMessageRequest: SendTextMessageRequest

    init(from sendTextMessageRequest: SendTextMessageRequest) {
        self.sendTextMessageRequest = sendTextMessageRequest
        super.init(threadId: sendTextMessageRequest.threadId,
                   message: sendTextMessageRequest.textMessage,
                   uniqueId: sendTextMessageRequest.uniqueId)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class EditTextMessage: Message, UnSentMessageProtocol {
    var editMessageRequest: EditMessageRequest

    init(from editMessageRequest: EditMessageRequest) {
        self.editMessageRequest = editMessageRequest
        super.init(threadId: editMessageRequest.threadId,
                   message: editMessageRequest.textMessage,
                   uniqueId: editMessageRequest.uniqueId)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class ForwardMessage: Message, UnSentMessageProtocol {
    var forwardMessageRequest: ForwardMessageRequest
    var destinationThread: Conversation

    init(from forwardMessageRequest: ForwardMessageRequest, destinationThread: Conversation) {
        self.forwardMessageRequest = forwardMessageRequest
        self.destinationThread = destinationThread
        super.init(uniqueId: forwardMessageRequest.uniqueId)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

protocol UploadWithTextMessageProtocol {
    var sendTextMessageRequest: SendTextMessageRequest? { get set }
    var uploadFileRequest: UploadFileRequest { get set }
}

class UploadFileMessage: Message, UploadWithTextMessageProtocol {
    var sendTextMessageRequest: SendTextMessageRequest?
    var uploadFileRequest: UploadFileRequest

    init(uploadFileRequest: UploadFileRequest, sendTextMessageRequest: SendTextMessageRequest? = nil) {
        self.sendTextMessageRequest = sendTextMessageRequest
        self.uploadFileRequest = uploadFileRequest
        super.init(uniqueId: uploadFileRequest.uniqueId)
        if let sendTextMessageRequest = sendTextMessageRequest {
            self.sendTextMessageRequest = sendTextMessageRequest
            self.uploadFileRequest = uploadFileRequest
            self.message = sendTextMessageRequest.textMessage
            self.messageType = sendTextMessageRequest.messageType
            self.metadata = sendTextMessageRequest.metadata
            self.systemMetadata = sendTextMessageRequest.systemMetadata
            self.threadId = sendTextMessageRequest.threadId
        }
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class UploadFileWithTextMessage: UploadFileMessage {}

class UnsentUploadFileWithTextMessage: UploadFileMessage, UnSentMessageProtocol {}
