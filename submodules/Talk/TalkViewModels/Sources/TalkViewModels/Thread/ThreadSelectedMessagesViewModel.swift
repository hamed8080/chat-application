//
//  ThreadSelectedMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
import TalkModels

public final class ThreadSelectedMessagesViewModel {
    public private(set) var isInSelectMode: Bool = false
    public weak var viewModel: ThreadViewModel?
    public init() {}

    public func setup(viewModel: ThreadViewModel? = nil) {
        self.viewModel = viewModel
    }

    public func clearSelection() {
        Task { @MainActor in
            getSelectedMessages().forEach { viewModel in
                viewModel.calMessage.state.isSelected = false
            }
            setInSelectionMode(false)
        }
    }

    public func setInSelectionMode(_ value: Bool) {
        isInSelectMode = value
        putAllInSeclectionMode(value)
    }

    public func getSelectedMessages() -> [MessageRowViewModel] {
        viewModel?.historyVM.sections.flatMap{$0.vms}.filter({$0.calMessage.state.isSelected}) ?? []
    }

    public func putAllInSeclectionMode(_ isInSelectionMode: Bool) {
        viewModel?.historyVM.sections.flatMap({$0.vms}).forEach({ vm in
            vm.calMessage.state.isInSelectMode = isInSelectionMode
        })
    }
}
