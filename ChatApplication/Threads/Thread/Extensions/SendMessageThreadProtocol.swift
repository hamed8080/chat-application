//
//  SendMessageThreadProtocol.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import FanapPodChatSDK
import Foundation
import UIKit

protocol SendMessageThreadProtocol {
    var textMessage: String? { get set }
    var editMessage: Message? { get set }
    var replyMessage: Message? { get set }
    var selectedMessages: [Message] { get set }
    var forwardMessage: Message? { get set }
    func onEditedMessage(_ editedMessage: Message?)
    func sendEditMessage(_ textMessage: String)
    func sendTextMessage(_ textMessage: String)
    func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String)
    func sendNormalMessage(_ textMessage: String)
    func sendForwardMessage(_ destinationThread: Conversation)
    func sendPhotos(uiImage: UIImage?, info: [AnyHashable: Any]?, item: ImageItem)
    func sendFile(_ url: URL)
    func toggleSelectedMessage(_ message: Message, _ isSelected: Bool)
    func appendSelectedMessage(_ message: Message)
    func removeSelectedMessage(_ message: Message)

    func resendUnsetMessage(_ message: Message)
    func onUnSentEditCompletionResult(_ message: Message?, _ uniqueId: String?, _ error: ChatError?)
    func onUnSentResult(_ message: SentMessageResponse?, _ uniqueId: String?, _ error: ChatError?)
    func cancelUnsentMessage(_ uniqueId: String)
}

extension ThreadViewModel: SendMessageThreadProtocol {
    /// It triggers when send button tapped
    func sendTextMessage(_ textMessage: String) {
        if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId, textMessage)
        } else if editMessage != nil {
            sendEditMessage(textMessage)
        } else {
            sendNormalMessage(textMessage)
        }
        isInEditMode = false // close edit mode in ui
    }

    func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String) {
        canScrollToBottomOfTheList = true
        let req = ReplyMessageRequest(threadId: threadId,
                                      repliedTo: replyMessageId,
                                      textMessage: textMessage,
                                      messageType: .text)
        Chat.sharedInstance.replyMessage(req) { _ in

        } onSent: { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in
        }
    }

    func sendNormalMessage(_ textMessage: String) {
        canScrollToBottomOfTheList = true
        let req = SendTextMessageRequest(threadId: threadId,
                                         textMessage: textMessage,
                                         messageType: .text)
        Chat.sharedInstance.sendTextMessage(req) { _ in

        } onSent: { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in
        }
    }

    func sendForwardMessage(_ destinationThread: Conversation) {
        guard let destinationThreadId = destinationThread.id else { return }
        canScrollToBottomOfTheList = true
        let messageIds = selectedMessages.compactMap { $0.id }
        let req = ForwardMessageRequest(fromThreadId: threadId, threadId: destinationThreadId, messageIds: messageIds)
        Chat.sharedInstance.forwardMessages(req) { _, _, _ in

        } onSeen: { _, _, _ in

        } onDeliver: { _, _, _ in

        } uniqueIdsResult: { _ in
        }
        isInEditMode = false // close edit mode in ui
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    func sendPhotos(uiImage: UIImage?, info: [AnyHashable: Any]?, item: ImageItem) {
        guard let image = uiImage else { return }
        canScrollToBottomOfTheList = true
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let fileName = item.phAsset.originalFilename
        let imageRequest = UploadImageRequest(data: image.jpegData(compressionQuality: 1.0) ?? Data(),
                                              hC: height,
                                              wC: width,
                                              fileName: fileName,
                                              mimeType: "image/jpg",
                                              userGroupHash: thread.userGroupHash)
        let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .picture)
        appendMessages(messages: [UploadFileWithTextMessage(uploadFileRequest: imageRequest, sendTextMessageRequest: textRequest)])
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    func sendFile(_ url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        canScrollToBottomOfTheList = true
        let uploadRequest = UploadFileRequest(data: data,
                                              fileExtension: ".\(url.fileExtension)",
                                              fileName: url.fileName,
                                              mimeType: url.mimeType,
                                              userGroupHash: thread.userGroupHash)
        let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .file)
        appendMessages(messages: [UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest)])
    }

    func sendEditMessage(_ textMessage: String) {
        guard let editMessage = editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(threadId: threadId,
                                     messageType: .text,
                                     messageId: messageId,
                                     textMessage: textMessage)
        self.editMessage = nil
        isInEditMode = false
        Chat.sharedInstance.editMessage(req) { [weak self] editedMessage, _, _ in
            self?.onEditedMessage(editedMessage)
        }
    }

    func onEditedMessage(_ editedMessage: Message?) {
        if let editedMessage = editedMessage, let oldMessage = messages.first(where: { $0.id == editedMessage.id }) {
            oldMessage.updateMessage(message: editedMessage)
        }
    }

    func resendUnsetMessage(_ message: Message) {
        switch message {
        case let req as SendTextMessage:
            Chat.sharedInstance.sendTextMessage(req.sendTextMessageRequest, onSent: onUnSentResult)
        case let req as EditTextMessage:
            Chat.sharedInstance.editMessage(req.editMessageRequest, completion: onUnSentEditCompletionResult)
        case let req as ForwardMessage:
            Chat.sharedInstance.forwardMessages(req.forwardMessageRequest, onSent: onUnSentResult)
        case let req as UploadFileWithTextMessage:
            appendMessage(UploadFileWithTextMessage(uploadFileRequest: req.uploadFileRequest))
        default:
            print("Type not detected!")
        }
    }

    func onUnSentEditCompletionResult(_ message: Message?, _ uniqueId: String?, _ error: ChatError?) {
        if let message = message, threadId == message.conversation?.id {
            onDeleteMessage(message: nil, uniqueId: uniqueId, error: nil)
            appendMessages(messages: [message])
        }
    }

    func onUnSentResult(_ message: SentMessageResponse?, _ uniqueId: String?, _ error: ChatError?) {
        if let uniqueId = uniqueId, message != nil {
            onDeleteMessage(message: nil, uniqueId: uniqueId, error: nil)
        }
    }

    func cancelUnsentMessage(_ uniqueId: String) {
        CacheFactory.write(cacheType: .deleteQueue(uniqueId))
        CacheFactory.save()
        onDeleteMessage(message: nil, uniqueId: uniqueId, error: nil)
    }

    func toggleSelectedMessage(_ message: Message, _ isSelected: Bool) {
        if isSelected {
            appendSelectedMessage(message)
        } else {
            removeSelectedMessage(message)
        }
    }

    func appendSelectedMessage(_ message: Message) {
        selectedMessages.append(message)
        objectWillChange.send()
    }

    func removeSelectedMessage(_ message: Message) {
        guard let index = selectedMessages.firstIndex(of: message) else { return }
        selectedMessages.remove(at: index)
    }
}
