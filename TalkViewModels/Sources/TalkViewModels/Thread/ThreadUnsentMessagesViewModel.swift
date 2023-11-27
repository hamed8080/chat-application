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

public final class ThreadUnsentMessagesViewModel: ObservableObject {
    let thread: Conversation
    @Published public private(set) var unsentMessages: [Message] = []
    private var cancelable: Set<AnyCancellable> = []

    public static func == (lhs: ThreadUnsentMessagesViewModel, rhs: ThreadUnsentMessagesViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        self.thread = thread
        if let threadId = thread.id {
            ChatManager.activeInstance?.message.unsentTextMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentEditMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentFileMessages(.init(threadId: threadId))
            ChatManager.activeInstance?.message.unsentForwardMessages(.init(threadId: threadId))
        }
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .chatEvents)
            .compactMap { $0.object as? ChatEventType }
            .sink { [weak self] event in
                self?.onChatEvent(event)
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
                                                                                       destinationThread: .init(id: $0.threadId, title: thread.title),
                                                                                       thread: thread) } ?? [])
    }

    func onQueueFileMessages(_ response: ChatResponse<[(UploadFileRequest, SendTextMessageRequest)]>) {
        unsentMessages.append(contentsOf: response.result?.compactMap { UnsentUploadFileWithTextMessage(uploadFileRequest: $0.0, sendTextMessageRequest: $0.1, thread: thread) } ?? [])
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        unsentMessages.removeAll(where: {$0.uniqueId == uniqueId})
    }
    
    public func onChatEvent(_ event: ChatEventType) {
        switch event {
        case .message(let messageEventTypes):
            onMessageEvent(messageEventTypes)
        default:
            break
        }
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
}
