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
    public func sendTextMessage() {
        if AppState.shared.appStateNavigationModel.forwardMessageRequest?.threadId == threadId {
            sendForwardMessages()
        } else if AppState.shared.appStateNavigationModel.replyPrivately != nil {
            sendReplyPrivatelyMessage()
        } else if let replyMessage = replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId)
        } else if sendContainerViewModel.editMessage != nil {
            sendEditMessage()
        } else if attachmentsViewModel.attachments.count > 0 {
            sendAttachmentsMessage()
        } else {
            sendNormalMessage()
        }

        /// A delay is essential for creating a conversation with a person for the person if we are in simulated mode.
        /// It prevents to delete textMessage inside the SendContainerViewModel with the clear method.
        Timer.scheduledTimer(withTimeInterval: isSimulatedThared ? 0.5 : 0, repeats: false) { [weak self] _ in
            self?.sendContainerViewModel.clear() // close ui
        }
        historyVM.seenVM.sendSeenForAllUnreadMessages()
    }

    public func sendAttachmentsMessage() {
        let attchments = attachmentsViewModel.attachments
        let type = attchments.map{$0.type}.first
        let images = attchments.compactMap({$0.request as? ImageItem})
        let urls = attchments.compactMap({$0.request as? URL})
        let location = attchments.first(where: {$0.type == .map})?.request as? LocationItem
        let dropItems = attchments.compactMap({$0.request as? DropItem})
        if type == .gallery {
            sendPhotos(images)
        } else if type == .file {
            sendFiles(urls)
        } else if type == .contact {
            // TODO: It should be implemented whenever the server side is ready.
        } else if type == .map, let item = location {
            sendLocation(item)
        } else if type == .drop {
            sendDropFiles(dropItems)
        }
    }

    public func sendReplyMessage(_ replyMessageId: Int) {
        if attachmentsViewModel.attachments.count == 1 {
            sendSingleReplyAttachment(attachmentsViewModel.attachments.first, replyMessageId)
        } else {
            if attachmentsViewModel.attachments.count > 1 {
                let lastItem = attachmentsViewModel.attachments.last
                if let lastItem {
                    attachmentsViewModel.remove(lastItem)
                }
                sendAttachmentsMessage()
                sendSingleReplyAttachment(lastItem, replyMessageId)
            } else {
                let req = ReplyMessageRequest(model: makeModel())
                ChatManager.activeInstance?.message.reply(req)
            }
        }
        attachmentsViewModel.clear()
        replyMessage = nil
        sendContainerViewModel.focusOnTextInput = false
    }

    public func sendSingleReplyAttachment(_ attachmentFile: AttachmentFile?, _ replyMessageId: Int) {
        var req = ReplyMessageRequest(model: makeModel())
        if let imageItem = attachmentFile?.request as? ImageItem {
            let imageReq = UploadImageRequest(imageItem: imageItem, thread.userGroupHash)
            req.messageType = .podSpacePicture
            ChatManager.activeInstance?.message.reply(req, imageReq)
        } else if let url = attachmentFile?.request as? URL, let fileReq = UploadFileRequest(url: url, thread.userGroupHash) {
            req.messageType = .podSpaceFile
            ChatManager.activeInstance?.message.reply(req, fileReq)
        }
    }

    public func sendReplyPrivatelyMessage() {
        if attachmentsViewModel.attachments.count == 1, let first = attachmentsViewModel.attachments.first {
            sendSingleReplyPrivatelyAttachment(first)
        } else if attachmentsViewModel.attachments.count > 1 {
            sendMultipleAttachemntWithReplyPrivately()
        } else {
            sendTextOnlyReplyPrivately()
        }
        attachmentsViewModel.clear()
        AppState.shared.appStateNavigationModel = .init()
    }

    private func sendMultipleAttachemntWithReplyPrivately() {
        if let lastItem = attachmentsViewModel.attachments.last {
            attachmentsViewModel.remove(lastItem)
            sendAttachmentsMessage()
            sendSingleReplyPrivatelyAttachment(lastItem)
        }
    }

    private func sendTextOnlyReplyPrivately() {
        if let req = ReplyPrivatelyRequest(model: makeModel()) {
            ChatManager.activeInstance?.message.replyPrivately(req)
        }
    }

    private func sendSingleReplyPrivatelyAttachment(_ attachmentFile: AttachmentFile) {
        if let imageItem = attachmentFile.request as? ImageItem, let message = UploadFileWithReplyPrivatelyMessage(imageItem: imageItem, model: makeModel()) {
            uploadMessagesViewModel.append(contentsOf: [message])
        } else if let message = UploadFileWithReplyPrivatelyMessage(attachmentFile: attachmentFile, model: makeModel()) {
            uploadMessagesViewModel.append(contentsOf: [message])
        }
    }

    public func sendAudiorecording() {
        send { [weak self] in
            guard let self = self,
                  let request = UploadFileWithTextMessage(audioFileURL: audioRecoderVM.recordingOutputPath, model: makeModel())
            else { return }
            uploadMessagesViewModel.append(contentsOf: [request])
            audioRecoderVM.cancel()
        }
    }

    public func sendNormalMessage() {
        send {
            Task { [weak self] in
                guard let self = self else { return }
                let tuple = Message.makeRequest(model: makeModel())
                await self.historyVM.appendMessagesAndSort([tuple.message])
                ChatManager.activeInstance?.message.send(tuple.req)
            }
        }
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?) {
        sendContainerViewModel.clear() /// Close edit mode in ui
        sheetType = nil
        animateObjectWillChange()
        let messages = selectedMessagesViewModel.selectedMessages.compactMap{$0.message}
        AppState.shared.openThread(from: threadId, conversation: destinationConversation, contact: contact, messages: messages)
        selectedMessagesViewModel.clearSelection()
    }

    public func sendForwardMessages() {
        if let req = AppState.shared.appStateNavigationModel.forwardMessageRequest {
            let model = makeModel()
            if !model.textMessage.isEmpty {
                let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: model.textMessage, messageType: .text)
                ChatManager.activeInstance?.message.send(messageReq)
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                ChatManager.activeInstance?.message.send(req)
                AppState.shared.appStateNavigationModel = .init()
            }
            sendAttachmentsMessage()
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        send { [weak self] in
            guard let self = self else {return}
            for(index, imageItem) in imageItems.filter({!$0.isVideo}).enumerated() {
                let imageMessage = UploadFileWithTextMessage(imageItem: imageItem, imageModel: makeModel(index))
                uploadMessagesViewModel.append(contentsOf: ([imageMessage]))
            }
            sendVideos(imageItems.filter({$0.isVideo}))
            attachmentsViewModel.clear()
        }
    }

    public func sendVideos(_ imageItems: [ImageItem]) {
        for (index, item) in imageItems.filter({$0.isVideo}).enumerated() {
            let videoMessage = UploadFileWithTextMessage(videoItem: item, videoModel: makeModel(index))
            self.uploadMessagesViewModel.append(contentsOf: ([videoMessage]))
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        send { [weak self] in
            guard let self = self else {return}
            for (index, url) in urls.enumerated() {
                let isLastItem = url == urls.last || urls.count == 1
                let fileMessage = UploadFileWithTextMessage(urlItem: url, isLastItem: isLastItem, urlModel: makeModel(index))
                self.uploadMessagesViewModel.append(contentsOf: [fileMessage])
            }
            attachmentsViewModel.clear()
        }
    }

    public func sendDropFiles(_ items: [DropItem]) {
        send { [weak self] in
            guard let self = self else {return}
            for (index, item) in items.enumerated() {
                let fileMessage = UploadFileWithTextMessage(dropItem: item, dropModel: makeModel(index))
                self.uploadMessagesViewModel.append(contentsOf: ([fileMessage]))
            }
            attachmentsViewModel.clear()
        }
    }

    public func sendEditMessage() {
        guard let editMessage = sendContainerViewModel.editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(messageId: messageId, model: makeModel())
        ChatManager.activeInstance?.message.edit(req)
    }

    public func sendLocation(_ location: LocationItem) {
        send { [weak self] in
            guard let self = self else {return}
            let message = UploadFileWithLocationMessage(location: location, model: makeModel())
            uploadMessagesViewModel.append(request: message)
            attachmentsViewModel.clear()
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

    func makeModel(_ uploadFileIndex: Int? = nil) -> SendMessageModel {
        let textMessage = sendContainerViewModel.getText()
        return SendMessageModel(textMessage: textMessage,
                                replyMessage: replyMessage,
                                meId: AppState.shared.user?.id,
                                conversation: thread,
                                threadId: threadId,
                                userGroupHash: thread.userGroupHash,
                                uploadFileIndex: uploadFileIndex,
                                replyPrivatelyMessage: AppState.shared.appStateNavigationModel.replyPrivately
        )
    }
}
