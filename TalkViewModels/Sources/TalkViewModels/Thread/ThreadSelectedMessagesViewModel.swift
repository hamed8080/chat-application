//
//  ThreadSelectedMessagesViewModel.swift
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

public final class ThreadSelectedMessagesViewModel: ObservableObject {
    public weak var threadVM: ThreadViewModel?
    public var selectedMessages: [MessageRowViewModel] { threadVM?.historyVM.messageViewModels.filter({$0.isSelected}) ?? []}

    public init(threadVM: ThreadViewModel? = nil) {
        self.threadVM = threadVM
    }

    public func clearSelection() {
        selectedMessages.forEach { viewModel in
            viewModel.isSelected = false
            viewModel.animateObjectWillChange()
        }
        animateObjectWillChange()
    }
}
