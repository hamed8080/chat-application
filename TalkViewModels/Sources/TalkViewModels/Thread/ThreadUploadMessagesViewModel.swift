//
//  ThreadUploadMessagesViewModel.swift
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

public final class ThreadUploadMessagesViewModel: ObservableObject {
    let thread: Conversation
    @Published public private(set) var uploadMessages: [Message] = []
    private var cancelable: Set<AnyCancellable> = []

    public static func == (lhs: ThreadUploadMessagesViewModel, rhs: ThreadUploadMessagesViewModel) -> Bool {
        rhs.thread.id == lhs.thread.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(thread)
    }

    public init(thread: Conversation) {
        self.thread = thread
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

    public func append(contentsOf requests: [UploadFileWithTextMessage]) {
        uploadMessages.append(contentsOf: requests)
    }

    public func append(request: UploadFileWithTextMessage) {
        uploadMessages.append(request)
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        uploadMessages.removeAll(where: {$0.uniqueId == uniqueId})
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
        default:
            break
        }
    }
}
