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

public protocol ScrollToPositionProtocol {
    func scrollToBottom(animation: Animation?)
    func scrollToLastMessageIfLastMessageIsVisible(_ message: Message)
}

public final class ThreadScrollingViewModel: ObservableObject {
    var task: Task<(), Never>?
    public var isProgramaticallyScroll: Bool = false
    public var scrollProxy: ScrollViewProxy?
    public var scrollingUP = false
    public weak var threadVM: ThreadViewModel? {
        didSet {
            isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId
        }
    }
    private var thread: Conversation { threadVM?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false

    init() {}

    @MainActor
    private func scrollTo(_ uniqueId: String, delay: TimeInterval = TimeInterval(0.6), _ animation: Animation? = .easeInOut, anchor: UnitPoint? = .bottom) async {
        try? await Task.sleep(for: .milliseconds(delay))
        if Task.isCancelled == true { return }
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }

        /// Ensure the view is shown as a result of SwiftUI can't properly move for the first time
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(animation) {
            scrollProxy?.scrollTo(uniqueId, anchor: anchor)
        }
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

    public func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, anchor: UnitPoint? = .bottom) {
       task = Task {
            if Task.isCancelled { return }
            await MainActor.run {
                if highlight {
                    NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
                }
            }
            await scrollTo(uniqueId, anchor: anchor)
        }
    }

    public func disableExcessiveLoading() {
        task = Task { [weak self] in
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isProgramaticallyScroll = true
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                isProgramaticallyScroll = false
            }
        }
    }

    public func cancelTask() {
        task?.cancel()
        task = nil
    }
}
