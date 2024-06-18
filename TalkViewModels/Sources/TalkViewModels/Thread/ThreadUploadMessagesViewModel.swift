//
//  ThreadUploadMessagesViewModel.swift
//
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
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

    internal func append(_ requests: [any HistoryMessageProtocol]) {
        Task { [weak self] in
            guard let self = self, let historyVM = viewModel?.historyVM else { return }
            let beforeSectionCount = historyVM.sections.count
            await historyVM.injectMessagesAndSort(requests)
            var indicies: [IndexPath] = []
            for request in requests {
                if let uniqueId = request.uniqueId, let indexPath = historyVM.sections.indicesByMessageUniqueId(uniqueId) {
                    indicies.append(indexPath)
                }
            }
            let afterSectionCount = historyVM.sections.count
            if afterSectionCount > beforeSectionCount {
                let secitonSet = IndexSet(beforeSectionCount..<afterSectionCount)
                viewModel?.delegate?.inserted(secitonSet, indicies)
            } else {
                viewModel?.delegate?.inserted(at: indicies)
            }
            if let last = requests.last {
                await viewModel?.scrollVM.scrollToLastMessageIfLastMessageIsVisible(last)
            }
        }
    }

    public func cancel(_ uniqueId: String?) {
        ChatManager.activeInstance?.message.cancel(uniqueId: uniqueId ?? "")
        Task { @HistoryActor [weak self] in
            self?.viewModel?.historyVM.removeByUniqueId(uniqueId)
        }
    }

    private func onUploadEvent(_ event: UploadEventTypes) {
        switch event {
        case .canceled(uniqueId: let uniqueId):
            Task { @HistoryActor [weak self] in
                self?.viewModel?.historyVM.removeByUniqueId(uniqueId)
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
