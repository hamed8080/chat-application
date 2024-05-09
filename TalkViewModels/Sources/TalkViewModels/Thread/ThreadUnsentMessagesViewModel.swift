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
    private var cancelable: Set<AnyCancellable> = []
    public private(set) var rowViewModels: [MessageRowViewModel] = []

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        setupNotificationObservers()
        if let threadId = thread?.id {
            ChatManager.activeInstance?.message.unsentTextMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentEditMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentFileMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentForwardMessages(.init(threadId: threadId))
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { event in
                Task { [weak self] in
                    await self?.onMessageEvent(event)
                }
            }
            .store(in: &cancelable)
    }

    func onQueueTextMessages(_ response: ChatResponse<[SendTextMessageRequest]>) async {
        let array = response.result?.compactMap { SendTextMessage(from: $0, thread: thread) } ?? []
        await append(rows: array)
        await asyncAnimateObjectWillChange()
    }

    func onQueueEditMessages(_ response: ChatResponse<[EditMessageRequest]>) async {
        let array = response.result?.compactMap { EditTextMessage(from: $0, thread: thread) } ?? []
        await append(rows: array)
        await asyncAnimateObjectWillChange()
    }

    func onQueueForwardMessages(_ response: ChatResponse<[ForwardMessageRequest]>) async {
        let array = response.result?.compactMap { ForwardMessage(from: $0,
                                                     destinationThread: .init(id: $0.threadId, title: thread?.title),
                                                     thread: thread) } ?? []
        await append(rows: array)
        await asyncAnimateObjectWillChange()
    }

    func onQueueFileMessages(_ response: ChatResponse<[(UploadFileRequest, SendTextMessageRequest)]>) async {
        let array = response.result?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: thread) } ?? []
        await append(rows: array)
        await asyncAnimateObjectWillChange()
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        rowViewModels.removeAll(where: {$0.message.uniqueId == uniqueId})
        animateObjectWillChange()
    }

    public func append<M>(rows: [M]) async where M: Message {
        guard let viewModel = viewModel else { return }
        for row in rows {
            if !self.rowViewModels.contains(where: {$0.uniqueId == row.uniqueId}) {
                let vm = MessageRowViewModel(message: row, viewModel: viewModel)
                await vm.performaCalculation()
                self.rowViewModels.append(vm)
            }
        }
    }

    public func messageViewModelWith(_ uniqueId: String) -> MessageRowViewModel? {
        self.rowViewModels.first(where: {$0.message.uniqueId == uniqueId})
    }

    public func onMessageEvent(_ event: MessageEventTypes?) async {
        switch event {
        case .queueTextMessages(let response):
            await onQueueTextMessages(response)
        case .queueEditMessages(let response):
            await onQueueEditMessages(response)
        case .queueForwardMessages(let response):
            await onQueueForwardMessages(response)
        case .queueFileMessages(let response):
            await onQueueFileMessages(response)
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
            viewModel?.historyVM.removeByUniqueId(req.uniqueId)
            if message.isImage, let imageRequest = req.uploadImageRequest {
                let imageMessage = UploadFileWithTextMessage(imageFileRequest: imageRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                viewModel?.uploadMessagesViewModel.append(contentsOf: ([imageMessage]))
                self.animateObjectWillChange()
            } else if let fileRequest = req.uploadFileRequest {
                let fileMessage = UploadFileWithTextMessage(uploadFileRequest: fileRequest, sendTextMessageRequest: req.sendTextMessageRequest, thread: thread)
                viewModel?.uploadMessagesViewModel.append(contentsOf: ([fileMessage]))
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
                viewModel?.historyVM.onDeleteMessage(response)
                await viewModel?.historyVM.appendMessagesAndSort([message])
            }
        }
    }

    func log(_ string: String) {
#if DEBUG
        Logger.viewModels.info("\(string, privacy: .sensitive)")
#endif
    }
}
