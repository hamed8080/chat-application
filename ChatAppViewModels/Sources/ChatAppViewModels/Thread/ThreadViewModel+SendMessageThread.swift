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

extension ThreadViewModel {
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
        ChatManager.activeInstance?.message.reply(req)
        replyMessage = nil
    }

    public func sendNormalMessage(_ textMessage: String) {
        canScrollToBottomOfTheList = true
        let req = SendTextMessageRequest(threadId: threadId,
                                         textMessage: textMessage,
                                         messageType: .text)
        let isMeId = (ChatManager.activeInstance?.userInfo ?? AppState.shared.user)?.id
        let message = Message(threadId: threadId, message: textMessage, messageType: .text, ownerId: isMeId, time: UInt(Date().millisecondsSince1970), uniqueId: req.uniqueId, conversation: thread)
        appendMessages([message])
        ChatManager.activeInstance?.message.send(req)
    }

    public func sendForwardMessage(_ destinationThread: Conversation) {
        guard let destinationThreadId = destinationThread.id else { return }
        canScrollToBottomOfTheList = true
        let messageIds = selectedMessages.compactMap(\.id)
        let req = ForwardMessageRequest(fromThreadId: threadId, threadId: destinationThreadId, messageIds: messageIds)
        ChatManager.activeInstance?.message.send(req)
        isInEditMode = false /// Close edit mode in ui
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        imageItems.forEach { imageItem in
            let index = imageItems.firstIndex(where: { $0 == imageItem })!
            canScrollToBottomOfTheList = true
            let imageRequest = UploadImageRequest(data: imageItem.imageData,
                                                  fileName: imageItem.fileName ?? "",
                                                  mimeType: "image/jpeg",
                                                  userGroupHash: thread.userGroupHash,
                                                  hC: imageItem.height,
                                                  wC: imageItem.width
            )
            let textRequest = SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: .picture)
            let request = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: textRequest, thread: thread)
            request.id = -index
            appendMessages([request])
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL], messageType: ChatModels.MessageType = .file) {
        urls.forEach { url in
            let index = urls.firstIndex(where: { $0 == url })!
            guard let data = try? Data(contentsOf: url) else { return }
            canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: data,
                                                  fileExtension: ".\(url.fileExtension)",
                                                  fileName: url.fileName,
                                                  mimeType: url.mimeType,
                                                  userGroupHash: thread.userGroupHash)
            let textRequest = textMessage == nil || textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: threadId, textMessage: textMessage ?? "", messageType: messageType)
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
                                                  userGroupHash: thread.userGroupHash)
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
        ChatManager.activeInstance?.message.edit(req)
    }

    public func sendLoaction(_ location: LocationItem) {
        let coordinate = Coordinate(lat: location.location.latitude, lng: location.location.longitude)
        let req = LocationMessageRequest(mapCenter: coordinate,
                                         threadId: threadId,
                                         userGroupHash: thread.userGroupHash ?? "",
                                         mapImageName: location.name,
                                         textMessage: textMessage)
        ChatManager.activeInstance?.message.send(req)
    }

    public func onSent(_ response: ChatResponse<MessageResponse>) {
        guard
            threadId == response.result?.threadId,
            let indices = indicesByMessageUniqueId(response.uniqueId ?? "")
        else { return }
        if !replaceUploadMessage(response) {
            sections[indices.sectionIndex].messages[indices.messageIndex].id = response.result?.messageId
            sections[indices.sectionIndex].messages[indices.messageIndex].time = response.result?.messageTime
        }
    }

    func replaceUploadMessage(_ response: ChatResponse<MessageResponse>) -> Bool {
        let lasSectionIndex = sections.firstIndex(where: {$0.id == sections.last?.id})
        if let lasSectionIndex,
           sections.indices.contains(lasSectionIndex),
           let oldUploadFileIndex = sections[lasSectionIndex].messages.firstIndex(where: { $0.isUploadMessage && $0.uniqueId == response.uniqueId }) {
            sections[lasSectionIndex].messages.remove(at: oldUploadFileIndex) /// Remove because it was of type UploadWithTextMessageProtocol
            sections[lasSectionIndex].messages.append(.init(threadId: response.subjectId, id: response.result?.messageId, time: response.result?.messageTime, uniqueId: response.uniqueId))
            return true
        }
        return false
    }

    public func onDeliver(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId ?? "", response.result?.messageId ?? 0)
        else { return }
        sections[indices.sectionIndex].messages[indices.messageIndex].delivered = true
    }

    public func onSeen(_ response: ChatResponse<MessageResponse>) {
        guard threadId == response.result?.threadId,
              let indices = findIncicesBy(uniqueId: response.uniqueId ?? "", response.result?.messageId ?? 0),
              sections[indices.sectionIndex].messages[indices.messageIndex].seen == nil
        else { return }
        sections[indices.sectionIndex].messages[indices.messageIndex].delivered = true
        sections[indices.sectionIndex].messages[indices.messageIndex].seen = true
        setSeenForOlderMessages(messageId: response.result?.messageId)
    }

    private func setSeenForOlderMessages(messageId: Int?) {
        if let messageId = messageId {
            sections.indices.forEach { sectionIndex in
                sections[sectionIndex].messages.indices.forEach { messageIndex in
                    let message = sections[sectionIndex].messages[messageIndex]
                    if (message.id ?? 0 < messageId) &&
                        (message.seen ?? false == false || message.delivered ?? false == false)
                        && message.ownerId == ChatManager.activeInstance?.userInfo?.id {
                        sections[sectionIndex].messages[messageIndex].delivered = true
                        sections[sectionIndex].messages[messageIndex].seen = true
                        let result = MessageResponse(messageState: .seen, threadId: threadId, messageId: message.id)
                        NotificationCenter.default.post(name: Notification.Name("UPDATE_OLDER_SEENS_LOCALLY"), object: result)
                    }
                }
            }
        }
    }

    public func resendUnsetMessage(_ message: Message) {
        switch message {
        case let req as SendTextMessage:
            ChatManager.activeInstance?.message.send(req.sendTextMessageRequest)
        case let req as EditTextMessage:
            ChatManager.activeInstance?.message.edit(req.editMessageRequest)
        case let req as ForwardMessage:
            ChatManager.activeInstance?.message.send(req.forwardMessageRequest)
        case let req as UploadFileMessage:
            // remove unset message type to start upload again the new one.
            removeByUniqueId(req.uniqueId)
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
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId)
        onDeleteMessage(ChatResponse(uniqueId: uniqueId, subjectId: threadId))
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
