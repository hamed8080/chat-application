//
//  DeleteMessagesViewModelModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 11/23/21.
//

import Foundation
import ChatModels

public final class DeleteMessagesViewModelModel: ObservableObject {
    public weak var viewModel: ThreadViewModel?
    private var thread: Conversation { viewModel?.thread ?? .init() }
    public var deleteForMe: Bool = true
    public var deleteForOthers: Bool = false
    public var deleteForOthserIfPossible: Bool = false
    public var hasPinnedMessage: Bool { messages.contains(where: {$0.id == viewModel?.thread.pinMessage?.id }) }
    public var isSingle: Bool { messages.count == 1 }
    public var isVstackLayout: Bool = false
    public var isSelfThread: Bool { viewModel?.thread.type == .selfThread }
    /// 86_400_000 is equal to the number of milliseconds in a day
    public var pastDeleteTimeForOthers: [Message] { messages.filter({ Int64($0.time ?? 0) + (86_400_000) < Date().millisecondsSince1970 }) }
    public var notPastDeleteTime: [Message] { messages.filter({!pastDeleteTimeForOthers.contains($0)}) }

    private var isGroup: Bool { thread.group == true }
    private var isAdmin: Bool { thread.admin == true }
    private var meUserId: Int { AppState.shared.user?.id ?? -1 }
    private var messages: [Message] { viewModel?.selectedMessagesViewModel.selectedMessages.compactMap({$0.message}) ?? [] }
    private var containsMe: Bool { messages.contains(where: { $0.isMe(currentUserId: meUserId) }) }
    private var containsNotMe: Bool { messages.contains(where: { !$0.isMe(currentUserId: meUserId) }) }
    private var onlyMyMessages: Bool { !containsNotMe }
    private var onlyOthersMessages: Bool { !containsMe }
    private var isOnlyContainsPastMessages: Bool { pastDeleteTimeForOthers.count == messages.count }

    public init() {}

    public func setup(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
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
        viewModel?.historyVM.deleteMessages(viewModel?.selectedMessagesViewModel.selectedMessages.compactMap({$0.message}) ?? [])
        viewModel?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel?.selectedMessagesViewModel.animateObjectWillChange()
    }

    public func deleteForAll() {
        viewModel?.historyVM.deleteMessages(viewModel?.selectedMessagesViewModel.selectedMessages.compactMap({$0.message}) ?? [], forAll: true)
        viewModel?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel?.selectedMessagesViewModel.animateObjectWillChange()
    }

    public func deleteForMeAndAllOthersPossible() {

        if pastDeleteTimeForOthers.count > 0 {
            viewModel?.historyVM.deleteMessages(pastDeleteTimeForOthers, forAll: false)
        }
        if notPastDeleteTime.count > 0 {
            viewModel?.historyVM.deleteMessages(notPastDeleteTime, forAll: true)
        }
        viewModel?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel?.selectedMessagesViewModel.animateObjectWillChange()
    }

    public func cleanup() {
        viewModel?.selectedMessagesViewModel.clearSelection()
        viewModel?.selectedMessagesViewModel.setInSelectionMode(isInSelectionMode: false)
        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
        viewModel?.selectedMessagesViewModel.animateObjectWillChange()
    }
}
