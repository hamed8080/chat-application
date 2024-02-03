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

public final class ThreadUploadMessagesViewModel {
    public weak var threadVM: ThreadViewModel?
    let thread: Conversation
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
        NotificationCenter.upload.publisher(for: .upload)
            .compactMap { $0.object as? UploadEventTypes }
            .sink { [weak self] event in
                self?.onUploadEvent(event)
            }
            .store(in: &cancelable)
    }

    public func append(contentsOf requests: [UploadFileWithTextMessage]) {
        Task {
            await threadVM?.historyVM.appendMessagesAndSort(requests)
            await threadVM?.historyVM.asyncAnimateObjectWillChange()
            if let last = requests.last {
                await threadVM?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(last)
            }
        }
    }

    public func append(request: UploadFileWithTextMessage) {
        Task {
            await threadVM?.historyVM.appendMessagesAndSort([request])
            await threadVM?.historyVM.asyncAnimateObjectWillChange()
            await threadVM?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(request)
        }
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        threadVM?.historyVM.removeByUniqueId(uniqueId)
    }

    public func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .canceled(uniqueId: let uniqueId):
            withAnimation {
                threadVM?.historyVM.removeByUniqueId(uniqueId)
            }
        default:
            break
        }
    }

    public func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
