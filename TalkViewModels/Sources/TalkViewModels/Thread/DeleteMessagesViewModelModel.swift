//
//  DeleteMessagesViewModelModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import ChatModels

public final class DeleteMessagesViewModelModel: ObservableObject {
    public let threadVM: ThreadViewModel
    public var viewModel: ThreadSelectedMessagesViewModel { threadVM.selectedMessagesViewModel }
    public var deleteForMe: Bool = true
    public var deleteForOthers: Bool = false
    public var deleteForOthserIfPossible: Bool = false
    public var hasPinnedMessage: Bool { messages.contains(where: {$0.id == threadVM.thread.pinMessage?.id }) }
    public var isSingle: Bool { messages.count == 1 }
    public var isVstackLayout: Bool = false
    public var isSelfThread: Bool { threadVM.thread.type == .selfThread }
    /// 86_400_000 is equal to the number of milliseconds in a day
    public var pastDeleteTimeForOthers: [Message] { messages.filter({ Int64($0.time ?? 0) + (86_400_000) < Date().millisecondsSince1970 }) }
    public var notPastDeleteTime: [Message] { messages.filter({!pastDeleteTimeForOthers.contains($0)}) }

    private var thread: Conversation { threadVM.thread }
    private var isGroup: Bool { thread.group == true }
    private var isAdmin: Bool { thread.admin == true }
    private var meUserId: Int { AppState.shared.user?.id ?? -1 }
    private var messages: [Message] { threadVM.selectedMessagesViewModel.selectedMessages.compactMap({$0.message}) }
    private var containsMe: Bool { messages.contains(where: { $0.isMe(currentUserId: meUserId) }) }
    private var containsNotMe: Bool { messages.contains(where: { !$0.isMe(currentUserId: meUserId) }) }
    private var onlyMyMessages: Bool { !containsNotMe }
    private var onlyOthersMessages: Bool { !containsMe }
    private var isOnlyContainsPastMessages: Bool { pastDeleteTimeForOthers.count == messages.count }

    public init(threadVM: ThreadViewModel) {
        self.threadVM = threadVM
        deleteForOthers = isDeletableForOthers()
        deleteForOthserIfPossible = isDeletableForOthersIfPossible()
        isVstackLayout = deleteForOthserIfPossible && !deleteForOthers
    }

    public static func isDeletable(isMe: Bool, message: Message, thread: Conversation?) -> Bool {
        let isChannel = thread?.type?.isChannelType == true
        let isAdmin = thread?.admin == true
        if isChannel && !isAdmin {
            return false
        }
        return true
    }

    private func isDeletableForOthers() -> Bool {
        if isSelfThread { return false }
        if !pastDeleteTimeForOthers.isEmpty { return false }
        if hasPinnedMessage { return false }
        if (isAdmin && isGroup) {
           return true
        }

        if !isGroup && onlyMyMessages {
            return true
        }

        if !isAdmin && isGroup && onlyMyMessages {
            return true
        }

        return false
    }

    private func isDeletableForOthersIfPossible() -> Bool {
        if isSelfThread { return false }
        if onlyOthersMessages { return false }
        if isOnlyContainsPastMessages { return false }
        if hasPinnedMessage { return false }
        return true
    }

    public func deleteMessagesForMe() {
        threadVM.historyVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}))
        threadVM.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel.animateObjectWillChange()
    }

    public func deleteForAll() {
        threadVM.historyVM.deleteMessages(viewModel.selectedMessages.compactMap({$0.message}), forAll: true)
        threadVM.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel.animateObjectWillChange()
    }

    public func deleteForMeAndAllOthersPossible() {

        if pastDeleteTimeForOthers.count > 0 {
            threadVM.historyVM.deleteMessages(pastDeleteTimeForOthers, forAll: false)
        }
        if notPastDeleteTime.count > 0 {
            threadVM.historyVM.deleteMessages(notPastDeleteTime, forAll: true)
        }
        threadVM.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel.animateObjectWillChange()
    }

    public func cleanup() {
        viewModel.clearSelection()
        threadVM.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel.animateObjectWillChange()
    }
}
