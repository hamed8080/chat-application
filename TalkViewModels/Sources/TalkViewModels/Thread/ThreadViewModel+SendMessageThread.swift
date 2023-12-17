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
        if AppState.shared.appStateNavigationModel.forwardMessageRequest?.threadId == threadId {
            sendForwardMessages()
        } else if AppState.shared.appStateNavigationModel.replyPrivately != nil {
            sendReplyPrivaetlyMessage(textMessage)
        } else if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
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
        } else if type == .contact {
            // TODO: It should be implemented whenever the server side is ready.
        } else if type == .map, let item = attchments.first(where: {$0.type == .map})?.request as? LocationItem {
            sendLoaction(textMessage, item)
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
        focusOnTextInput = false
    }

    public func sendSingleReplyAttachment(_ attachmentFile: AttachmentFile?, _ replyMessageId: Int, _ textMessage: String) {
        var req = ReplyMessageRequest(threadId: threadId,
                                      repliedTo: replyMessageId,
                                      textMessage: textMessage,
                                      messageType: .text)
        if let imageItem = attachmentFile?.request as? ImageItem {
            let imageReq = UploadImageRequest(data: imageItem.data,
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

    public func sendReplyPrivaetlyMessage(_ textMessage: String) {
        guard
            let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately,
            let replyMessageId = replyMessage.id,
            let fromConversationId = replyMessage.conversation?.id
        else { return }
        canScrollToBottomOfTheList = true
        if attachmentsViewModel.attachments.count == 1 {
            sendSingleReplyPrivatelyAttachment(attachmentsViewModel.attachments.first, fromConversationId, replyMessageId, textMessage)
        } else {
            if attachmentsViewModel.attachments.count > 1 {
                let lastItem = attachmentsViewModel.attachments.last
                if let lastItem {
                    attachmentsViewModel.remove(lastItem)
                }
                sendAttachmentsMessage()
                sendSingleReplyPrivatelyAttachment(lastItem, fromConversationId, replyMessageId, textMessage)
            } else {
                let req = ReplyPrivatelyRequest(repliedTo: replyMessageId,
                                                messageType: .text,
                                                content: .init(text: textMessage, targetConversationId: threadId, fromConversationId: fromConversationId))
                ChatManager.activeInstance?.message.replyPrivately(req)
            }
        }
        attachmentsViewModel.clear()
        AppState.shared.appStateNavigationModel = .init()
    }

    public func sendSingleReplyPrivatelyAttachment(_ attachmentFile: AttachmentFile?, _ fromConversationId: Int, _ replyMessageId: Int, _ textMessage: String) {
        var req = ReplyPrivatelyRequest(repliedTo: replyMessageId,
                                                     messageType: .text,
                                                     content: .init(text: textMessage, targetConversationId: threadId, fromConversationId: fromConversationId))
        if let imageItem = attachmentFile?.request as? ImageItem {
            let imageReq = UploadImageRequest(data: imageItem.data,
                                              fileName: imageItem.fileName ?? "",
                                              mimeType: "image/jpeg",
                                              userGroupHash: self.thread.userGroupHash,
                                              hC: imageItem.height,
                                              wC: imageItem.width
            )
            req.messageType = .podSpacePicture
            ChatManager.activeInstance?.message.replyPrivately(req, imageReq)
        } else if let url = attachmentFile?.request as? URL, let data = try? Data(contentsOf: url) {
            let fileReq = UploadFileRequest(data: data,
                                            fileExtension: ".\(url.fileExtension)",
                                            fileName: url.fileName,
                                            mimeType: url.mimeType,
                                            userGroupHash: self.thread.userGroupHash)
            req.messageType = .podSpaceFile
            ChatManager.activeInstance?.message.replyPrivately(req, fileReq)
        }
    }

    public func sendAudiorecording() {
        send { [weak self] in
            guard let self = self, let audioFileURL = audioRecoderVM.recordingOutputPath else { return }
            guard let data = try? Data(contentsOf: audioFileURL) else { return }
            self.canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: data,
                                                  fileExtension: ".\(audioFileURL.fileExtension)",
                                                  fileName: audioFileURL.fileName,
                                                  mimeType: audioFileURL.mimeType,
                                                  userGroupHash: self.thread.userGroupHash)
            let textRequest = SendTextMessageRequest(threadId: self.threadId, textMessage: "", messageType: .podSpaceVoice)
            let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
            uploadMessagesViewModel.append(contentsOf: [request])
            audioRecoderVM.cancel()
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

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?) {
        isInEditMode = false /// Close edit mode in ui
        sheetType = nil
        animateObjectWillChange()
        let messages = selectedMessagesViewModel.selectedMessages.compactMap{$0.message}
        AppState.shared.openThread(from: threadId, conversation: destinationConversation, contact: contact, messages: messages)
        selectedMessagesViewModel.clearSelection()
    }

    public func sendForwardMessages() {
        if let req = AppState.shared.appStateNavigationModel.forwardMessageRequest {
            if let textMessage = textMessage, !textMessage.isEmpty {
                let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: textMessage, messageType: .text)
                ChatManager.activeInstance?.message.send(messageReq)
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    ChatManager.activeInstance?.message.send(req)
                    AppState.shared.appStateNavigationModel = .init()
                }
            } else {
                ChatManager.activeInstance?.message.send(req)
                AppState.shared.appStateNavigationModel = .init()
            }
            sendAttachmentsMessage()
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ textMessage: String = "", _ imageItems: [ImageItem]) {
        send { [weak self] in
            guard let self = self else {return}
            imageItems.filter({!$0.isVideo}).forEach { imageItem in
                let index = imageItems.firstIndex(where: { $0 == imageItem })!
                self.canScrollToBottomOfTheList = true
                let imageRequest = UploadImageRequest(data: imageItem.data,
                                                      fileExtension: "png",
                                                      fileName: "\(imageItem.fileName ?? "").png",
                                                      mimeType: "image/png",
                                                      userGroupHash: self.thread.userGroupHash,
                                                      hC: imageItem.height,
                                                      wC: imageItem.width
                )
                let textRequest = SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .podSpacePicture)
                let request = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.uploadMessagesViewModel.append(contentsOf: ([request]))
            }
            sendVideos(textMessage, imageItems.filter({$0.isVideo}))
            attachmentsViewModel.clear()
        }
    }

    public func sendVideos(_ textMessage: String = "", _ imageItems: [ImageItem]) {
        imageItems.filter({$0.isVideo}).forEach { imageItem in
            let index = imageItems.firstIndex(where: { $0 == imageItem })!
            self.canScrollToBottomOfTheList = true
            self.canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: imageItem.data,
                                                  fileExtension: "mp4",
                                                  fileName: imageItem.fileName,
                                                  mimeType: "video/mp4",
                                                  userGroupHash: self.thread.userGroupHash)
            let textRequest = SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .podSpaceVideo)
            let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
            request.id = -index
            self.uploadMessagesViewModel.append(contentsOf: ([request]))
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ textMessage: String = "", _ urls: [URL], messageType: ChatModels.MessageType = .podSpaceFile) {
        send { [weak self] in
            guard let self = self else {return}
            urls.forEach { url in
                let index = urls.firstIndex(where: { $0 == url })!
                guard let data = try? Data(contentsOf: url) else { return }
                self.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: data,
                                                      fileExtension: "\(url.fileExtension)",
                                                      fileName: "\(url.fileName).\(url.fileExtension)", // it should have file name and extension
                                                      mimeType: url.mimeType,
                                                      originalName: "\(url.fileName).\(url.fileExtension)",
                                                      userGroupHash: self.thread.userGroupHash)
                let textRequest = self.textMessage == nil || self.textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: messageType)
                let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.uploadMessagesViewModel.append(contentsOf: [request])
            }
            attachmentsViewModel.clear()
        }
    }

    public func sendDropFiles(_ textMessage: String = "", _ items: [DropItem]) {
        send { [weak self] in
            guard let self = self else {return}
            items.forEach { item in
                let index = items.firstIndex(where: { $0.id == item.id })!
                self.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: item.data ?? Data(),
                                                      fileExtension: "\(item.ext ?? "")",
                                                      fileName: "\(item.name ?? "").\(item.ext ?? "")", // it should have file name and extension
                                                      mimeType: nil,
                                                      userGroupHash: self.thread.userGroupHash)
                let textRequest = self.textMessage == nil || self.textMessage?.isEmpty == true ? nil : SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .podSpaceFile)
                let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.uploadMessagesViewModel.append(contentsOf: ([request]))
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
                                             mapZoom: 17,
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
                self.uploadMessagesViewModel.append(contentsOf: ([imageMessage]))
                self.animateObjectWillChange()
            } else if let fileRequest = req.uploadFileRequest {
                let fileMessage = UploadFileWithTextMessage(uploadFileRequest: fileRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                self.uploadMessagesViewModel.append(contentsOf: ([fileMessage]))
                self.animateObjectWillChange()
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
