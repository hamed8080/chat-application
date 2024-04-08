//
//  ThreadScrollingViewModel.swift
//
//
//  Created by hamed on 12/24/23.
//

import Chat
import Foundation
import ChatModels
import ChatDTO
import ChatCore
import SwiftUI
import Combine

public protocol ScrollToPositionProtocol {
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible(_ message: Message)
}

public final class ThreadScrollingViewModel: ObservableObject {
    var task: Task<(), Never>?
    private var isProgramaticallyScroll: Bool = false
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    private var cancelablleSet = Set<AnyCancellable>()
    private var queue = DispatchQueue(label: "ScrollingStateSerialQueue")
    public weak var threadVM: ThreadViewModel? {
        didSet {
            isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId
        }
    }
    private var thread: Conversation { threadVM?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false

    init() {
        registerObservers()
    }

    @MainActor
    private func scrollTo(_ uniqueId: String, delay: TimeInterval = TimeInterval(0.3), _ animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) async {
        guard let uniqueId = threadVM?.historyVM.messageViewModel(for: uniqueId)?.uniqueId else { return }
        try? await Task.sleep(for: .milliseconds(delay))
        if Task.isCancelled == true { return }
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }

        /// Ensure the view is shown as a result of SwiftUI can't properly move for the first time
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }
    }

    public func scrollToSlot(_ uniqueId: String, anchor: UnitPoint? = .top) {
        scrollProxy?.scrollTo(uniqueId, anchor: anchor)
    }

    public func scrollToBottom(animation: Animation? = .easeInOut) {
        if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            threadVM?.historyVM.moveToTime(time, messageId, highlight: false)
        }
    }

    public func scrollToEmptySpace(animation: Animation? = .easeInOut) {
        task = Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(animation) {
                scrollProxy?.scrollTo(-3, anchor: .bottom)
            }
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) async {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            await scrollTo(uniqueId, delay: 0.1, .easeInOut)
        }
    }

    public func showHighlighted(_ uniqueId: String, _ messageId: Int, animation: Animation? = .easeInOut, highlight: Bool = true, anchor: UnitPoint? = .bottom) {
       task = Task {
            if Task.isCancelled { return }
            await MainActor.run {
                if highlight {
                    NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
                }
            }
           await scrollTo(uniqueId, animation, anchor: anchor)
        }
    }

    public func showHighlightedAsync(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, anchor: UnitPoint? = .bottom) async {
        if Task.isCancelled { return }
        await MainActor.run {
            if highlight {
                NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
            }
        }
        await scrollTo(uniqueId, anchor: anchor)
    }

    public func disableExcessiveLoading() {
        task = Task { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                setProgramaticallyScrollingState(newState: true)
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                setProgramaticallyScrollingState(newState: false)
            }
        }
    }

    private func registerObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scrollToBottomIfPossible()
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scrollToBottomIfPossible()
        }

        NotificationCenter.message.publisher(for: .message)
            .sink { [weak self] notif in
                guard let self = self else { return }
                if let event = notif.object as? MessageEventTypes {
                    if case .new(let response) = event, response.result?.conversation?.id == threadVM?.threadId {
                        scrollToBottomIfPossible()
                    }
                }
            }
            .store(in: &cancelablleSet)
    }

    private func scrollToBottomIfPossible() {
        // We have to wait until all the animations for clicking on TextField are finished and then start our animation.
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                if self.isAtBottomOfTheList {
                    self.scrollToBottom()
                }
            }
        }
    }

    // MARK: Cancel Observers
    internal func cancelAllObservers() {
        cancelablleSet.forEach { cancelable in
            cancelable.cancel()
        }
        cancelablleSet.removeAll()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    public func getProgramaticallyScrollingState() -> Bool {
        queue.sync {
            return isProgramaticallyScroll
        }
    }

    public func setProgramaticallyScrollingState(newState: Bool) {
        queue.sync {
            isProgramaticallyScroll = newState
        }
    }

    public func cancelTask() {
        task?.cancel()
        task = nil
    }
}
