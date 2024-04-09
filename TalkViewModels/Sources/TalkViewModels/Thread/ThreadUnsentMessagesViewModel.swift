//
//  ThreadUnsentMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import ChatModels
import Chat
import ChatCore
import ChatDTO
import TalkModels
import Combine
import OSLog

public final class ThreadUnsentMessagesViewModel: ObservableObject {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    @Published public private(set) var unsentMessages: ContiguousArray<Message> = .init()
    private var cancelable: Set<AnyCancellable> = []
    weak var threadVM: ThreadViewModel?

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        if let threadId = thread?.id {
            ChatManager.activeInstance?.message.unsentTextMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentEditMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentFileMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentForwardMessages(.init(threadId: threadId))
        }
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)
    }

    func onQueueTextMessages(_ response: ChatResponse<[SendTextMessageRequest]>) {
        unsentMessages.append(contentsOf: response.result?.compactMap { SendTextMessage(from: $0, thread: thread) } ?? [])
    }

    func onQueueEditMessages(_ response: ChatResponse<[EditMessageRequest]>) {
        unsentMessages.append(contentsOf: response.result?.compactMap { EditTextMessage(from: $0, thread: thread) } ?? [])
    }

    func onQueueForwardMessages(_ response: ChatResponse<[ForwardMessageRequest]>) {
        unsentMessages.append(contentsOf: response.result?.compactMap { ForwardMessage(from: $0,
                                                                                       destinationThread: .init(id: $0.threadId, title: thread?.title),
                                                                                       thread: thread) } ?? [])
    }

    func onQueueFileMessages(_ response: ChatResponse<[(UploadFileRequest, SendTextMessageRequest)]>) {
        unsentMessages.append(contentsOf: response.result?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: thread) } ?? [])
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        unsentMessages.removeAll(where: {$0.uniqueId == uniqueId})
    }

    public func onMessageEvent(_ event: MessageEventTypes?) {
        switch event {
        case .queueTextMessages(let response):
            onQueueTextMessages(response)
        case .queueEditMessages(let response):
            onQueueEditMessages(response)
        case .queueForwardMessages(let response):
            onQueueForwardMessages(response)
        case .queueFileMessages(let response):
            onQueueFileMessages(response)
        default:
            break
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
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
            threadVM?.historyVM.removeByUniqueId(req.uniqueId)
            if message.isImage, let imageRequest = req.uploadImageRequest {
                let imageMessage = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                threadVM?.uploadMessagesViewModel.append(contentsOf: ([imageMessage]))
                self.animateObjectWillChange()
            } else if let fileRequest = req.uploadFileRequest {
                let fileMessage = UploadFileWithTextMessage(uploadFileRequest: fileRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                threadVM?.uploadMessagesViewModel.append(contentsOf: ([fileMessage]))
                self.animateObjectWillChange()
            }
        default:
            log("Type not detected!")
        }
    }

    public func onUnSentEditCompletionResult(_ response: ChatResponse<Message>) {
        if let message = response.result, thread?.id == message.conversation?.id {
            Task { [weak self] in
                guard let self = self else { return }
                threadVM?.historyVM.onDeleteMessage(response)
                await threadVM?.historyVM.appendMessagesAndSort([message])
            }
        }
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
