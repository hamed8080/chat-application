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
        let textMessage = textMessage.replacingOccurrences(of: "\u{200f}", with: "")
        if AppState.shared.appStateNavigationModel.forwardMessageRequest?.threadId == threadId {
            sendForwardMessages(textMessage)
        } else if AppState.shared.appStateNavigationModel.replyPrivately != nil {
            sendReplyPrivatelyMessage(textMessage)
        } else if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId, textMessage)
        } else if sendContainerViewModel.editMessage != nil {
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
        scrollVM.canScrollToBottomOfTheList = true
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
        sendContainerViewModel.focusOnTextInput = false
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

    public func sendReplyPrivatelyMessage(_ textMessage: String) {
        guard
            let replyMessage = AppState.shared.appStateNavigationModel.replyPrivately,
            let replyMessageId = replyMessage.id,
            let fromConversationId = replyMessage.conversation?.id
        else { return }
        scrollVM.canScrollToBottomOfTheList = true
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
            self.scrollVM.canScrollToBottomOfTheList = true
            let uploadRequest = UploadFileRequest(data: data,
                                                  fileExtension: ".\(audioFileURL.fileExtension)",
                                                  fileName: "\(audioFileURL.fileName).\(audioFileURL.fileExtension)",
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
            scrollVM.canScrollToBottomOfTheList = true
            let req = SendTextMessageRequest(threadId: threadId,
                                             textMessage: textMessage,
                                             messageType: .text)
            let isMeId = (ChatManager.activeInstance?.userInfo ?? AppState.shared.user)?.id
            let message = Message(threadId: threadId, message: textMessage, messageType: .text, ownerId: isMeId, time: UInt(Date().millisecondsSince1970), uniqueId: req.uniqueId, conversation: thread)
            Task { [weak self] in
                guard let self = self else { return }
                await self.historyVM.appendMessagesAndSort([message])
                ChatManager.activeInstance?.message.send(req)
            }
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

    public func sendForwardMessages(_ textMessage: String) {
        if let req = AppState.shared.appStateNavigationModel.forwardMessageRequest {
            if !textMessage.isEmpty {
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
                self.scrollVM.canScrollToBottomOfTheList = true
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
            self.scrollVM.canScrollToBottomOfTheList = true
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
            for (index, url) in urls.enumerated() {
                guard let data = try? Data(contentsOf: url) else { return }
                self.scrollVM.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: data,
                                                      fileExtension: "\(url.fileExtension)",
                                                      fileName: "\(url.fileName).\(url.fileExtension)", // it should have file name and extension
                                                      mimeType: url.mimeType,
                                                      originalName: "\(url.fileName).\(url.fileExtension)",
                                                      userGroupHash: self.thread.userGroupHash)
                let isMusic = url.isMusicMimetype
                let newMessageType = isMusic ? ChatModels.MessageType.podSpaceSound : messageType
                var textRequest: SendTextMessageRequest? = nil
                if url == urls.last || urls.count == 1 {
                    textRequest = SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: newMessageType)
                }
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
                self.scrollVM.canScrollToBottomOfTheList = true
                let uploadRequest = UploadFileRequest(data: item.data ?? Data(),
                                                      fileExtension: "\(item.ext ?? "")",
                                                      fileName: "\(item.name ?? "").\(item.ext ?? "")", // it should have file name and extension
                                                      mimeType: nil,
                                                      userGroupHash: self.thread.userGroupHash)
                let textRequest = textMessage.isEmpty == true ? nil : SendTextMessageRequest(threadId: self.threadId, textMessage: textMessage, messageType: .podSpaceFile)
                let request = UploadFileWithTextMessage(uploadFileRequest: uploadRequest, sendTextMessageRequest: textRequest, thread: self.thread)
                request.id = -index
                self.uploadMessagesViewModel.append(contentsOf: ([request]))
            }
            attachmentsViewModel.clear()
        }
    }

    public func sendEditMessage(_ textMessage: String) {
        guard let editMessage = sendContainerViewModel.editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(threadId: threadId,
                                     messageType: .text,
                                     messageId: messageId,
                                     textMessage: textMessage)
        sendContainerViewModel.editMessage = nil
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
            historyVM.removeByUniqueId(req.uniqueId)
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
            Task { [weak self] in
                guard let self = self else { return }
                historyVM.onDeleteMessage(response)
                await historyVM.appendMessagesAndSort([message])
            }
        }
    }

    public func send(completion: @escaping ()-> Void) {
        if isSimulatedThared {
            self.createThreadCompletion = completion
            createP2PThread()
        } else {
            completion()
        }
    }

    public func createP2PThread() {
        guard let coreuserId = AppState.shared.appStateNavigationModel.userToCreateThread?.id else { return }
        let req = CreateThreadRequest(invitees: [.init(id: "\(coreuserId)", idType: .coreUserId)], title: "")
        RequestsManager.shared.append(prepend: "CREATE-P2P", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateP2PThread(_ response: ChatResponse<Conversation>) {
        guard response.pop(prepend: "CREATE-P2P") != nil, let thread = response.result else { return }
        self.thread = thread
        AppState.shared.appStateNavigationModel.userToCreateThread = nil
        animateObjectWillChange()
        createThreadCompletion?()
        createThreadCompletion = nil
    }
}
