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
import UIKit
import TalkModels

public final class ThreadScrollingViewModel: ObservableObject {
    var task: Task<(), Never>?
    public var isProgramaticallyScroll: Bool = false
    public weak var scrollDelegate: HistoryScrollDelegate? { threadVM?.historyVM.delegate }
    public var scrollingUP = false
    public weak var threadVM: ThreadViewModel? {
        didSet {
            isAtBottomOfTheList = thread.lastMessageVO?.id == thread.lastSeenMessageId
        }
    }
    private var thread: Conversation { threadVM?.thread ?? .init(id: -1)}
    public var isAtBottomOfTheList: Bool = false
    public var lastContentOffsetY: CGFloat = 0
    init() {}

    @MainActor
    private func scrollTo(_ uniqueId: String, position: UITableView.ScrollPosition = .bottom) async {
        scrollDelegate?.scrollTo(uniqueId: uniqueId, position: position)
    }

    public func scrollToBottom() {
        if let messageId = thread.lastMessageVO?.id, let time = thread.lastMessageVO?.time {
            threadVM?.historyVM.moveToTime(time, messageId, highlight: false)
        }
    }

    public func scrollToEmptySpace() {
        task = Task {
//            scrollDelegate?.scrollTo("\(LocalId.emptySpcae.rawValue)", position: .bottom)
        }
    }

    public func scrollToLastMessageIfLastMessageIsVisible(_ message: Message) async {
        if isAtBottomOfTheList || message.isMe(currentUserId: AppState.shared.user?.id), let uniqueId = message.uniqueId {
            disableExcessiveLoading()
            await scrollTo(uniqueId)
        }
    }

    public func showHighlighted(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, position: UITableView.ScrollPosition = .bottom) {
       task = Task {
            if Task.isCancelled { return }
            await MainActor.run {
                if highlight {
                    NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
                }
            }
           await scrollTo(uniqueId, position: position)
        }
    }

    public func showHighlightedAsync(_ uniqueId: String, _ messageId: Int, highlight: Bool = true, position: UITableView.ScrollPosition = .bottom) async {
        if Task.isCancelled { return }
        await MainActor.run {
            if highlight {
                NotificationCenter.default.post(name: Notification.Name("HIGHLIGHT"), object: messageId)
            }
        }
        await scrollTo(uniqueId, position: position)
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
