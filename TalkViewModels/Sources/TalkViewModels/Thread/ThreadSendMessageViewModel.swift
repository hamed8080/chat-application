//
//  ThreadSendMessageViewModel.swift
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
import OSLog

public final class ThreadSendMessageViewModel: ObservableObject {
    private weak var viewModel: ThreadViewModel?
    private var creator: P2PConversationBuilder?

    private var thread: Conversation { viewModel?.thread ?? .init() }
    private var threadId: Int { thread.id ?? 0 }
    private var attVM: AttachmentsViewModel { viewModel?.attachmentsViewModel ?? .init() }
    private var uplVM: ThreadUploadMessagesViewModel { viewModel?.uploadMessagesViewModel ?? .init() }
    private var sendVM: SendContainerViewModel { viewModel?.sendContainerViewModel ?? .init() }
    private var selectVM: ThreadSelectedMessagesViewModel { viewModel?.selectedMessagesViewModel ?? .init() }
    private var navModel: AppStateNavigationModel {
        get {
            return AppState.shared.appStateNavigationModel
        } set {
            AppState.shared.appStateNavigationModel = newValue
        }
    }
    private var historyVM: ThreadHistoryViewModel? { viewModel?.historyVM }
    private var seenVM: HistorySeenViewModel? { historyVM?.seenVM }
    private var recorderVM: AudioRecordingViewModel { viewModel?.audioRecoderVM ?? .init() }

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
    }

    /// It triggers when send button tapped
    @MainActor
    public func sendTextMessage() async {
        if isOriginForwardThread() { return }
        if navModel.forwardMessageRequest?.threadId == threadId {
            sendForwardMessages()
        } else if navModel.replyPrivately != nil {
            sendReplyPrivatelyMessage()
        } else if let replyMessage = viewModel?.replyMessage, let replyMessageId = replyMessage.id {
            sendReplyMessage(replyMessageId)
        } else if sendVM.editMessage != nil {
            sendEditMessage()
        } else if attVM.attachments.count > 0 {
            sendAttachmentsMessage()
        } else if recorderVM.recordingOutputPath != nil {
            sendAudiorecording()
        } else {
            sendNormalMessage()
        }

        seenVM?.sendSeenForAllUnreadMessages()
        viewModel?.mentionListPickerViewModel.text = ""
        viewModel?.sheetType = nil
        viewModel?.animateObjectWillChange()
        /// A delay is essential for creating a conversation with a person for the person if we are in simulated mode.
        /// It prevents to delete textMessage inside the SendContainerViewModel with the clear method.
        if viewModel?.isSimulatedThared == true {
            try? await Task.sleep(for: .milliseconds(500))
        }
        sendVM.clear() // close ui
    }

    private func isOriginForwardThread() -> Bool {
        navModel.forwardMessageRequest != nil && (threadId != navModel.forwardMessageRequest?.threadId)
    }

    public func sendAttachmentsMessage() {
        let attchments = attVM.attachments
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
        if attVM.attachments.count == 1 {
            sendSingleReplyAttachment(attVM.attachments.first, replyMessageId)
        } else {
            if attVM.attachments.count > 1 {
                let lastItem = attVM.attachments.last
                if let lastItem {
                    attVM.remove(lastItem)
                }
                sendAttachmentsMessage()
                sendSingleReplyAttachment(lastItem, replyMessageId)
            } else {
                let req = ReplyMessageRequest(model: makeModel())
                ChatManager.activeInstance?.message.reply(req)
            }
        }
        attVM.clear()
        viewModel?.replyMessage = nil
        sendVM.focusOnTextInput = false
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
        send { [weak self] in
            guard let self = self else { return }
            if attVM.attachments.count == 1, let first = attVM.attachments.first {
                sendSingleReplyPrivatelyAttachment(first)
            } else if attVM.attachments.count > 1 {
                sendMultipleAttachemntWithReplyPrivately()
            } else if recorderVM.recordingOutputPath != nil {
                sendReplyPrivatelyWithVoice()
            } else {
                sendTextOnlyReplyPrivately()
            }
            attVM.clear()
            navModel = .init()
        }
    }

    private func sendMultipleAttachemntWithReplyPrivately() {
        if let lastItem = attVM.attachments.last {
            attVM.remove(lastItem)
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
            uplVM.append(contentsOf: [message])
        } else if let message = UploadFileWithReplyPrivatelyMessage(attachmentFile: attachmentFile, model: makeModel()) {
            uplVM.append(contentsOf: [message])
        }
    }

    private func sendReplyPrivatelyWithVoice() {
        if let message = UploadFileWithReplyPrivatelyMessage(voiceURL: recorderVM.recordingOutputPath, model: makeModel()) {
            uplVM.append(contentsOf: [message])
            recorderVM.cancel()
        }
    }

    private func sendAudiorecording() {
        send { [weak self] in
            guard let self = self,
                  let request = UploadFileWithTextMessage(audioFileURL: recorderVM.recordingOutputPath, model: makeModel())
            else { return }
            uplVM.append(contentsOf: [request])
            recorderVM.cancel()
        }
    }

    public func sendNormalMessage() {
        send { [weak self] in
            guard let self = self else { return }
            let tuple = Message.makeRequest(model: makeModel(), checkLink: true)
            ChatManager.activeInstance?.message.send(tuple.req)
        }
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?) {
        sendVM.clear() /// Close edit mode in ui
        seenVM?.animateObjectWillChange()
        viewModel?.sheetType = nil
        viewModel?.animateObjectWillChange()
        animateObjectWillChange()
        let messages = selectVM.selectedMessages.compactMap{$0.message}
        if let contact = contact {
            AppState.shared.openForwardThread(from: threadId, contact: contact, messages: messages)
        } else if let destinationConversation = destinationConversation {
            AppState.shared.openForwardThread(from: threadId, conversation: destinationConversation, messages: messages)
        }
        selectVM.clearSelection()
    }

    private func sendForwardMessages() {
        guard let req = navModel.forwardMessageRequest else { return }
        if viewModel?.isSimulatedThared == true {
            createAndSend(req)
        } else {
            sendForwardMessages(req)
        }
    }

    private func createAndSend(_ req: ForwardMessageRequest) {
        send { [weak self] in
            guard let self = self else {return}
            let req = ForwardMessageRequest(fromThreadId: req.fromThreadId, threadId: threadId, messageIds: req.messageIds)
            sendForwardMessages(req)
        }
    }

    private func sendForwardMessages(_ req: ForwardMessageRequest) {
        let model = makeModel()
        if !model.textMessage.isEmpty {
            let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: model.textMessage, messageType: .text)
            ChatManager.activeInstance?.message.send(messageReq)
        }
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            ChatManager.activeInstance?.message.send(req)
            self?.navModel = .init()
            self?.viewModel?.animateObjectWillChange()
        }
        sendAttachmentsMessage()
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload image
    public func sendPhotos(_ imageItems: [ImageItem]) {
        send { [weak self] in
            guard let self = self else {return}
            for(index, imageItem) in imageItems.filter({!$0.isVideo}).enumerated() {
                let imageMessage = UploadFileWithTextMessage(imageItem: imageItem, imageModel: makeModel(index))
                uplVM.append(contentsOf: ([imageMessage]))
            }
            sendVideos(imageItems.filter({$0.isVideo}))
            attVM.clear()
        }
    }

    public func sendVideos(_ imageItems: [ImageItem]) {
        for (index, item) in imageItems.enumerated() {
            let videoMessage = UploadFileWithTextMessage(videoItem: item, videoModel: makeModel(index))
            self.uplVM.append(contentsOf: ([videoMessage]))
        }
    }

    /// add a upload messge entity to bottom of the messages in the thread and then the view start sending upload file
    public func sendFiles(_ urls: [URL]) {
        send { [weak self] in
            guard let self = self else {return}
            for (index, url) in urls.enumerated() {
                let isLastItem = url == urls.last || urls.count == 1
                if let fileMessage = UploadFileWithTextMessage(urlItem: url, isLastItem: isLastItem, urlModel: makeModel(index)) {
                    self.uplVM.append(contentsOf: [fileMessage])
                }
            }
            attVM.clear()
        }
    }

    public func sendDropFiles(_ items: [DropItem]) {
        send { [weak self] in
            guard let self = self else {return}
            for (index, item) in items.enumerated() {
                let fileMessage = UploadFileWithTextMessage(dropItem: item, dropModel: makeModel(index))
                self.uplVM.append(contentsOf: ([fileMessage]))
            }
            attVM.clear()
        }
    }

    public func sendEditMessage() {
        guard let editMessage = sendVM.editMessage, let messageId = editMessage.id else { return }
        let req = EditMessageRequest(messageId: messageId, model: makeModel())
        ChatManager.activeInstance?.message.edit(req)
    }

    public func sendLocation(_ location: LocationItem) {
        send { [weak self] in
            guard let self = self else {return}
            let message = UploadFileWithLocationMessage(location: location, model: makeModel())
            uplVM.append(request: message)
            attVM.clear()
        }
    }

    public func send(completion: @escaping () -> Void) {
        if viewModel?.isSimulatedThared == true {
            createP2PThread(completion)
        } else {
            completion()
        }
    }

    public func createP2PThread(_ completion: @escaping () -> Void) {
        creator = P2PConversationBuilder()
        if let coreuserId = navModel.userToCreateThread?.coreUserId {
            creator?.create(coreUserId: coreuserId) { [weak self] conversation in
                self?.onCreateP2PThread(conversation)
                completion()
                self?.creator = nil
            }
        }
    }

    public func onCreateP2PThread(_ conversation: Conversation) {
        self.viewModel?.updateConversation(conversation)
        DraftManager.shared.clear(contactId: navModel.userToCreateThread?.contactId ?? -1)
        navModel.userToCreateThread = nil
        animateObjectWillChange()
    }

    func makeModel(_ uploadFileIndex: Int? = nil) -> SendMessageModel {
        let textMessage = sendVM.getText()
        return SendMessageModel(textMessage: textMessage,
                                replyMessage: viewModel?.replyMessage,
                                meId: AppState.shared.user?.id,
                                conversation: thread,
                                threadId: threadId,
                                userGroupHash: thread.userGroupHash,
                                uploadFileIndex: uploadFileIndex,
                                replyPrivatelyMessage: navModel.replyPrivately
        )
    }
}
