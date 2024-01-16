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
import SwiftUI

public final class ThreadUploadMessagesViewModel: ObservableObject {
    let thread: Conversation
    @Published public private(set) var uploadMessages: ContiguousArray<Message> = .init()
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
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancelable)

        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
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

    public func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .canceled(uniqueId: let uniqueId):
            withAnimation {
                uploadMessages.removeAll(where: { $0.uniqueId == uniqueId })
            }
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
