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
    weak var viewModel: ThreadViewModel?
    private var thread: Conversation? { viewModel?.thread }
    private var cancelable: Set<AnyCancellable> = []

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
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

    internal func append(contentsOf requests: [Message]) {
        Task {
            await viewModel?.historyVM.appendMessagesAndSort(requests)
            await viewModel?.historyVM.asyncAnimateObjectWillChange()
            if let last = requests.last {
                await viewModel?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(last)
            }
        }
    }

    internal func append(request: Message) {
        Task {
            await viewModel?.historyVM.appendMessagesAndSort([request])
            await viewModel?.historyVM.asyncAnimateObjectWillChange()
            await viewModel?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(request)
        }
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        viewModel?.historyVM.removeByUniqueId(uniqueId)
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .canceled(uniqueId: let uniqueId):
            withAnimation {
                viewModel?.historyVM.removeByUniqueId(uniqueId)
            }
        default:
            break
        }
    }

    internal func cancelAllObservers() {
        cancelable.forEach { cancelable in
            cancelable.cancel()
        }
    }
}
