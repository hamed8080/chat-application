//
//  ThreadViewModel+SendMessageThread.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import UIKit
import ChatModels
import ChatAppExtensions
import ChatAppModels
import ChatDTO
import ChatCore

public protocol SendMessageThreadProtocol {
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
    func sendPhotos(_ imageItems: [ImageItem])
    func sendFiles(_ urls: [URL])
    func sendDropFiles(_ items: [DropItem])
    func onSent(_ response: ChatResponse<MessageResponse>?)
    func onDeliver(_ response: ChatResponse<MessageResponse>?)
    func onSeen(_ response: ChatResponse<MessageResponse>?)
    func toggleSelectedMessage(_ message: Message, _ isSelected: Bool)
    func appendSelectedMessage(_ message: Message)
    func removeSelectedMessage(_ message: Message)
    func resendUnsetMessage(_ message: Message)
    func onUnSentEditCompletionResult(_ response: ChatResponse<Message>)
    func cancelUnsentMessage(_ uniqueId: String)
}

extension ThreadViewModel: SendMessageThreadProtocol {
    /// It triggers when send button tapped
    public func sendTextMessage(_ textMessage: String) {
        if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId, textMessage)
        } else if editMessage != nil {
            sendEditMessage(textMessage)
        } else {
            sendNormalMessage(textMessage)
        }
        isInEditMode = false // close edit mode in ui
    }

    public func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String) {
        canScrollToBottomOfTheList = true
        let req = ReplyMessageRequest(threadId: threadId,
                                      repliedTo: replyMessageId,
                                      textMessage: textMessage,
                                      messageType: .text)
        ChatManager.activeInstance?.replyMessage(req, onSent: onSent, onSeen: onSeen, onDeliver: onDeliver)
    }

    public func sendNormalMessage(_ textMessage: String) {
        canScrollToBottomOfTheList = true
        let req = SendTextMessageRequest(threadId: threadId,
                                         textMessage: textMessage,
                                         messageType: .text)
        let isMeId = (ChatManager.activeInstance?.userInfo ?? AppState.shared.user)?.id
        let message = Message(threadId: threadId, message: textMessage, messageType: .text, ownerId: isMeId, uniqueId: req.uniqueId, conversation: thread)
        appendMessages([message])
        ChatManager.activeInstance?.sendTextMessage(req, onSent: onSent, onSeen: onSeen, onDeliver: onDeliver)
    }

    public func sendForwardMessage(_ destinationThread: Conversation) {
        guard let destinationThreadId = destinationThread.id else { return }
        canScrollToBottomOfTheList = true
        let messageIds = selectedMessages.compactMap(\.id)
        let req = ForwardMessageRequest(fromThreadId: threadId, threadId: destinationThreadId, messageIds: messageIds)
        ChatManager.activeInstance?.forwardMessages(req, onSent: onSent, onSeen: onSeen, onDeliver: onDeliver)
        isInEditMode = false // close edit mode in ui
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        imageItems.forEach { imageItem in
            let index = imageItems.firstIndex(where: { $0 == imageItem })!
            canScrollToBottomOfTheList = true
            let image = UIImage(data: imageItem.imageData)
            let width = Int(image?.size.width ?? 0)
            let height = Int(image?.size.height ?? 0)
            let imageRequest = UploadImageRequest(data: image?.jpegData(compressionQuality: 1.0) ?? Data(),
                                                  fileName: imageItem.fileName ?? "",
                                                  mimeType: "image/jpg",
                                                  userGroupHash: thread?.userGroupHash,
                                                  hC: height,
                                                  wC: width
            )
            let textRequest = SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .picture)
            let request = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: textRequest, thread: thread)
            request.id = -index
            appendMessages([request])
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        urls.forEach { url in
            let index = urls.firstIndex(where: { $0 == url })!
            guard let data = try? Data(contentsOf: url) else { return }
            canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: data,
                                                  fileExtension: ".\(url.fileExtension)",
                                                  fileName: url.fileName,
                                                  mimeType: url.mimeType,
                                                  userGroupHash: thread?.userGroupHash)
            let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .file)
            let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: thread)
            request.id = -index
            appendMessages([request])
        }
    }

    public func sendDropFiles(_ items: [DropItem]) {
        items.forEach { item in
            let index = items.firstIndex(where: { $0.id == item.id })!
            canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: item.data ?? Data(),
                                                  fileExtension: ".\(item.ext ?? "")",
                                                  fileName: item.name,
                                                  mimeType: nil,
                                                  userGroupHash: thread?.userGroupHash)
            let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .file)
            let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: thread)
            request.id = -index
            appendMessages([request])
        }
    }

    public func sendEditMessage(_ textMessage: String) {
        guard let editMessage = editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(threadId: threadId,
                                     messageType: .text,
                                     messageId: messageId,
                                     textMessage: textMessage)
        self.editMessage = nil
        isInEditMode = false
        ChatManager.activeInstance?.editMessage(req) { [weak self] response in
            self?.onEditedMessage(response.result)
        }
    }

    public func onEditedMessage(_ editedMessage: Message?) {
        if let editedMessage = editedMessage, let oldMessage = messages.first(where: { $0.id == editedMessage.id }) {
            oldMessage.updateMessage(message: editedMessage)
        }
    }

    public func onSent(_ response: ChatResponse<MessageResponse>?) {
        if let index = messages.firstIndex(where: { $0.uniqueId == response?.uniqueId }) {
            messages[index].id = response?.result?.messageId
            messages[index].delivered = true
            objectWillChange.send()
        }
    }

    internal func playSentAudio() {
        if let fileURL = Bundle.main.url(forResource: "sent_message", withExtension: "mp3") {
            audioPlayer = AVAudioPlayerViewModel()
            audioPlayer?.setup(fileURL: fileURL , ext: "mp3", category: .ambient)
            audioPlayer?.toggle()
        }
    }

    public func onDeliver(_ response: ChatResponse<MessageResponse>?) {
        if let index = messages.firstIndex(where: { $0.id == response?.result?.messageId || $0.uniqueId == response?.uniqueId }) {
            messages[index].delivered = true
            objectWillChange.send()
        }
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>?) {
        if let index = messages.firstIndex(where: { ($0.id ?? 0 <= response?.result?.messageId ?? 0 && $0.seen == nil) || $0.uniqueId == response?.uniqueId }) {
            messages[index].delivered = true
            messages[index].seen = true
            objectWillChange.send()
        }
    }

    public func resendUnsetMessage(_ message: Message) {
        switch message {
        case let req as SendTextMessage:
            ChatManager.activeInstance?.sendTextMessage(req.sendTextMessageRequest, onSent: onSent, onSeen: onSeen, onDeliver: onDeliver)
        case let req as EditTextMessage:
            ChatManager.activeInstance?.editMessage(req.editMessageRequest, completion: onUnSentEditCompletionResult)
        case let req as ForwardMessage:
            ChatManager.activeInstance?.forwardMessages(req.forwardMessageRequest, onSent: onSent, onSeen: onSeen, onDeliver: onDeliver)
        case let req as UploadFileMessage:
            // remove unset message type to start upload again the new one.
            messages.removeAll(where: { $0.uniqueId == req.uniqueId })
            if message.isImage {
                let imageMessage = UploadFileWithTextMessage(imageFileRequest: req.uploadImageRequest!, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                appendMessages([imageMessage])
            } else {
                let fileMessage = UploadFileWithTextMessage(uploadFileRequest: req.uploadFileRequest!, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                appendMessages([fileMessage])
            }
        default:
            print("Type not detected!")
        }
    }

    public func onUnSentEditCompletionResult(_ response: ChatResponse<Message>) {
        if let message = response.result, threadId == message.conversation?.id {
            onDeleteMessage(response)
            appendMessages([message])
        }
    }

    public func cancelUnsentMessage(_ uniqueId: String) {
        ChatManager.activeInstance?.cancelMessage(uniqueId: uniqueId) { _ in }
        onDeleteMessage(ChatResponse(uniqueId: uniqueId))
    }

    public func toggleSelectedMessage(_ message: Message, _ isSelected: Bool) {
        if isSelected {
            appendSelectedMessage(message)
        } else {
            removeSelectedMessage(message)
        }
    }

    public func appendSelectedMessage(_ message: Message) {
        selectedMessages.append(message)
        objectWillChange.send()
    }

    public func removeSelectedMessage(_ message: Message) {
        guard let index = selectedMessages.firstIndex(of: message) else { return }
        selectedMessages.remove(at: index)
    }
}
