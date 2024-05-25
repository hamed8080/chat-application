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
    public private(set) var isInSelectMode: Bool = false
    public weak var viewModel: ThreadViewModel?
    public var selectedMessages: [MessageRowViewModel] { viewModel?.historyVM.sections.flatMap{$0.vms}.filter({$0.state.isSelected}) ?? []}
    public init() {}

    public func setup(viewModel: ThreadViewModel? = nil) {
        self.viewModel = viewModel
    }

    public func clearSelection() {
        selectedMessages.forEach { viewModel in
            viewModel.state.isSelected = false
        }
        setInSelectionMode(false)
    }

    public func setInSelectionMode(_ value: Bool) {
        isInSelectMode = value
        animateObjectWillChange()
    }
}
