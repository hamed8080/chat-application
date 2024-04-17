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
import ChatCore
import OSLog
import Combine

public final class ThreadSendMessageViewModel: ObservableObject {
    private weak var viewModel: ThreadViewModel?
    private var createThreadCompletion: (()-> Void)?
    private var cancelable: Set<AnyCancellable> = []

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
        registerNotifications()
    }

    /// It triggers when send button tapped
    public func sendTextMessage() {
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
        } else {
            sendNormalMessage()
        }

        /// A delay is essential for creating a conversation with a person for the person if we are in simulated mode.
        /// It prevents to delete textMessage inside the SendContainerViewModel with the clear method.
        Timer.scheduledTimer(withTimeInterval: viewModel?.isSimulatedThared == true ? 0.5 : 0, repeats: false) { [weak self] _ in
            self?.sendVM.clear() // close ui
        }
        seenVM?.sendSeenForAllUnreadMessages()
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
        if attVM.attachments.count == 1, let first = attVM.attachments.first {
            sendSingleReplyPrivatelyAttachment(first)
        } else if attVM.attachments.count > 1 {
            sendMultipleAttachemntWithReplyPrivately()
        } else {
            sendTextOnlyReplyPrivately()
        }
        attVM.clear()
        navModel = .init()
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

    public func sendAudiorecording() {
        send { [weak self] in
            guard let self = self,
                  let request = UploadFileWithTextMessage(audioFileURL: recorderVM.recordingOutputPath, model: makeModel())
            else { return }
            uplVM.append(contentsOf: [request])
            recorderVM.cancel()
        }
    }

    public func sendNormalMessage() {
        send {
            Task { [weak self] in
                guard let self = self else { return }
                let tuple = Message.makeRequest(model: makeModel(), checkLink: true)
                await self.historyVM?.appendMessagesAndSort([tuple.message])
                ChatManager.activeInstance?.message.send(tuple.req)
            }
        }
    }

    public func openDestinationConversationToForward(_ destinationConversation: Conversation?, _ contact: Contact?) {
        sendVM.clear() /// Close edit mode in ui
        viewModel?.sheetType = nil
        animateObjectWillChange()
        let messages = selectVM.selectedMessages.compactMap{$0.message}
        AppState.shared.openThread(from: threadId, conversation: destinationConversation, contact: contact, messages: messages)
        selectVM.clearSelection()
    }

    public func sendForwardMessages() {
        if let req = navModel.forwardMessageRequest {
            let model = makeModel()
            if !model.textMessage.isEmpty {
                let messageReq = SendTextMessageRequest(threadId: threadId, textMessage: model.textMessage, messageType: .text)
                ChatManager.activeInstance?.message.send(messageReq)
            }
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                ChatManager.activeInstance?.message.send(req)
                self?.navModel = .init()
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
                let fileMessage = UploadFileWithTextMessage(urlItem: url, isLastItem: isLastItem, urlModel: makeModel(index))
                self.uplVM.append(contentsOf: [fileMessage])
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

    public func send(completion: @escaping ()-> Void) {
        if viewModel?.isSimulatedThared == true {
            self.createThreadCompletion = completion
            createP2PThread()
        } else {
            completion()
        }
    }

    public func createP2PThread() {
        guard let coreuserId = navModel.userToCreateThread?.id else { return }
        let req = CreateThreadRequest(invitees: [.init(id: "\(coreuserId)", idType: .coreUserId)], title: "")
        RequestsManager.shared.append(prepend: "CREATE-P2P", value: req)
        ChatManager.activeInstance?.conversation.create(req)
    }

    public func onCreateP2PThread(_ response: ChatResponse<Conversation>) {
        guard response.pop(prepend: "CREATE-P2P") != nil, let thread = response.result else { return }
        self.viewModel?.updateConversation(thread)
        navModel.userToCreateThread = nil
        animateObjectWillChange()
        createThreadCompletion?()
        createThreadCompletion = nil
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


    func registerNotifications() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvent(event)
            }
            .store(in: &cancelable)
    }

    public func onThreadEvent(_ event: ThreadEventTypes?) {
        switch event {
        case .created(let response):
            onCreateP2PThread(response)
        default:
            break
        }
    }
}
