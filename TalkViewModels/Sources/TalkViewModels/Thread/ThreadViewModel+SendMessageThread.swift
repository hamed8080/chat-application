//
//  ThreadViewModel+SendMessageThread.swift
//  TalkViewModels
//
//  Created by hamed on 11/24/22.
//

import Chat
import Foundation
import UIKit
import ChatModels
import TalkExtensions
import TalkModels
import ChatDTO
import ChatCore
import OSLog

extension ThreadViewModel {
    /// It triggers when send button tapped
    public func sendTextMessage(_ textMessage: String) {
        if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId, textMessage)
        } else if editMessage != nil {
            sendEditMessage(textMessage)
        } else if attachmentsViewModel.attachments.count > 0 {
            sendAttachmentsMessage(textMessage)
        } else {
            sendNormalMessage(textMessage)
        }
        isInEditMode = false // close edit mode in ui
    }

    public func sendAttachmentsMessage(_ textMessage: String = "") {
        let attchments = attachmentsViewModel.attachments
        let type = attchments.map{$0.type}.first
        if type == .gallery {
            let images = attchments.compactMap({$0.request as? ImageItem})
            sendPhotos(textMessage, images)
        } else if type == .file {
            let urls = attchments.compactMap({$0.request as? URL})
            sendFiles(textMessage, urls)
        } else if type == .voice {
            let urls = attchments.compactMap({$0.request as? URL})
            sendFiles(textMessage, urls)
        } else if type == .contact {
            // TODO: It should be implemented whenever the server side is ready.
        } else if type == .map {
            // TODO: It should be implemented whenever the server side is ready.
        } else if type == .drop {
            let dropItems = attchments.compactMap({$0.request as? DropItem})
            sendDropFiles(textMessage, dropItems)
        }
    }

    public func sendReplyMessage(_ replyMessageId: Int, _ textMessage: String) {
        canScrollToBottomOfTheList = true
        if attachmentsViewModel.attachments.count == 1 {
            sendSingleReplyAttachment(attachmentsViewModel.attachments.first, replyMessageId, textMessage)
        } else {
            if attachmentsViewModel.attachments.count > 1 {
                let lastItem = attachmentsViewModel.attachments.last
                if let lastItem {
                    attachmentsViewModel.remove(lastItem)
                }
                sendAttachmentsMessage()
                sendSingleReplyAttachment(lastItem, replyMessageId, textMessage)
            } else {
                let req = ReplyMessageRequest(threadId: threadId,
                                              repliedTo: replyMessageId,
                                              textMessage: textMessage,
                                              messageType: .text)
                ChatManager.activeInstance?.message.reply(req)
            }
        }
        attachmentsViewModel.clear()
        replyMessage = nil
    }

    public func sendSingleReplyAttachment(_ attachmentFile: AttachmentFile?, _ replyMessageId: Int, _ textMessage: String) {
        var req = ReplyMessageRequest(threadId: threadId,
                                      repliedTo: replyMessageId,
                                      textMessage: textMessage,
                                      messageType: .text)
        if let imageItem = attachmentFile?.request as? ImageItem {
            let imageReq = UploadImageRequest(data: imageItem.imageData,
                                              fileName: imageItem.fileName ?? "",
                                              mimeType: "image/jpeg",
                                              userGroupHash: self.thread.userGroupHash,
                                              hC: imageItem.height,
                                              wC: imageItem.width
            )
            req.messageType = .podSpacePicture
            ChatManager.activeInstance?.message.reply(req, imageReq)
        } else if let url = attachmentFile?.request as? URL, let data = try? Data(contentsOf: url) {
            let fileReq = UploadFileRequest(data: data,
                                            fileExtension: ".\(url.fileExtension)",
                                            fileName: url.fileName,
                                            mimeType: url.mimeType,
                                            userGroupHash: self.thread.userGroupHash)
            req.messageType = .podSpaceFile
            ChatManager.activeInstance?.message.reply(req, fileReq)
        }
    }

    public func sendNormalMessage(_ textMessage: String) {
        send { [weak self] in
            guard let self = self else {return}
            canScrollToBottomOfTheList = true
            let req = SendTextMessageRequest(threadId: threadId,
                                             textMessage: textMessage,
                                             messageType: .text)
            let isMeId = (ChatManager.activeInstance?.userInfo ?? AppState.shared.user)?.id
            let message = Message(threadId: threadId, message: textMessage, messageType: .text, ownerId: isMeId, time: UInt(Date().millisecondsSince1970), uniqueId: req.uniqueId, conversation: thread)
            appendMessagesAndSort([message])
            ChatManager.activeInstance?.message.send(req)
        }
    }

    public func sendForwardMessage(_ destinationConversation: Conversation?, _ contact: Contact?) {
        isInEditMode = false /// Close edit mode in ui
        sheetType = nil
        animateObjectWillChange()
        let messageIds = selectedMessages.compactMap{$0.message.id}
        AppState.shared.openThread(from: threadId, conversation: destinationConversation, contact: contact, messageIds: messageIds)
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ textMessage: String = "", _ imageItems: [ImageItem]) {
        send { [weak self] in
            guard let self = self else {return}
            imageItems.forEach { imageItem in
                let index = imageItems.firstIndex(where: { $0 == imageItem })!
                self.canScrollToBottomOfTheList = true
                let imageRequest = UploadImageRequest(data: imageItem.imageData,
                                                      fileName: imageItem.fileName ?? "",
                                                      mimeType: "image/jpeg",
                                                      userGroupHash: self.thread.userGroupHash,
                                                      hC: imageItem.height,
                                                      wC: imageItem.width
                )
                let textRequest = SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .picture)
                let request = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.appendMessagesAndSort([request])
            }
            attachmentsViewModel.clear()
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ textMessage: String = "", _ urls: [URL], messageType: ChatModels.MessageType = .file) {
        send { [weak self] in
            guard let self = self else {return}
            urls.forEach { url in
                let index = urls.firstIndex(where: { $0 == url })!
                guard let data = try? Data(contentsOf: url) else { return }
                self.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: data,
                                                      fileExtension: ".\(url.fileExtension)",
                                                      fileName: url.fileName,
                                                      mimeType: url.mimeType,
                                                      userGroupHash: self.thread.userGroupHash)
                let textRequest = self.textMessage == nil || self.textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: messageType)
                let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.appendMessagesAndSort([request])
            }
            attachmentsViewModel.clear()
            audioRecoderVM?.deleteFile()
        }
    }

    public func sendDropFiles(_ textMessage: String = "", _ items: [DropItem]) {
        send { [weak self] in
            guard let self = self else {return}
            items.forEach { item in
                let index = items.firstIndex(where: { $0.id == item.id })!
                self.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: item.data ?? Data(),
                                                      fileExtension: ".\(item.ext ?? "")",
                                                      fileName: item.name,
                                                      mimeType: nil,
                                                      userGroupHash: self.thread.userGroupHash)
                let textRequest = self.textMessage == nil || self.textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .file)
                let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.appendMessagesAndSort([request])
            }
            attachmentsViewModel.clear()
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

    public func sendLoaction(_ textMessage: String = "", _ location: LocationItem) {
        send { [weak self] in
            guard let self = self else {return}
            let coordinate = Coordinate(lat: location.location.latitude, lng: location.location.longitude)
            let req = LocationMessageRequest(mapCenter: coordinate,
                                             threadId: threadId,
                                             userGroupHash: thread.userGroupHash ?? "",
                                             mapImageName: location.name,
                                             textMessage: textMessage)
            ChatManager.activeInstance?.message.send(req)
            attachmentsViewModel.clear()
        }
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
            if message.isImage, let imageRequest = req.uploadImageRequest {
                let imageMessage = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                appendMessagesAndSort([imageMessage])
            } else if let fileRequest = req.uploadFileRequest {
                let fileMessage = UploadFileWithTextMessage(uploadFileRequest: fileRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                appendMessagesAndSort([fileMessage])
            }
        default:
            log("Type not detected!")
        }
    }

    public func onUnSentEditCompletionResult(_ response: ChatResponse<Message>) {
        if let message = response.result, threadId == message.conversation?.id {
            onDeleteMessage(response)
            appendMessagesAndSort([message])
        }
    }

    public func cancelUnsentMessage(_ uniqueId: String) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId)
        onDeleteMessage(ChatResponse(uniqueId: uniqueId, subjectId: threadId))
    }

    public func send(completion: @escaping ()-> Void) {
        if isEmptyThared {
            self.createThreadCompletion = completion
            createP2PThread()
        } else {
            completion()
        }
    }

    public var isEmptyThared: Bool {
        AppState.shared.userToCreateThread != nil && thread.id == LocalId.emptyThread.rawValue
    }

    public func createP2PThread() {
        guard let coreuserId = AppState.shared.userToCreateThread?.id else { return }
        let req = CreateThreadRequest(invitees: [.init(id: "\(coreuserId)", idType: .coreUserId)], title: "")
        RequestsManager.shared.append(prepend: "CREATE-P2P", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateP2PThread(_ response: ChatResponse<Conversation>) {
        guard response.value(prepend: "CREATE-P2P") != nil, let thread = response.result else { return }
        self.thread = thread
        AppState.shared.userToCreateThread = nil
        animateObjectWillChange()
        createThreadCompletion?()
        createThreadCompletion = nil
    }
}
