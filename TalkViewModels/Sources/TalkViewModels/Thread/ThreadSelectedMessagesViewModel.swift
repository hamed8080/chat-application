//
//  ThreadSelectedMessagesViewModel.swift
//  
//
//  Created by hamed on 11/27/23.
//

import Foundation
import Chat
import TalkModels

public final class ThreadSelectedMessagesViewModel: ObservableObject {
    @Published public var isInSelectMode: Bool = false
    public weak var viewModel: ThreadViewModel?
    public init() {}

    public func setup(viewModel: ThreadViewModel? = nil) {
        self.viewModel = viewModel
    }

    public func clearSelection() {
        Task { @MainActor in
            await getSelectedMessages().forEach { viewModel in
                viewModel.calMessage.state.isSelected = false
                viewModel.animateObjectWillChange()
            }
            setInSelectionMode(isInSelectionMode: false)
            animateObjectWillChange()
        }
    }

    public func setInSelectionMode(isInSelectionMode: Bool) {
        isInSelectMode = isInSelectionMode
        viewModel?.sendContainerViewModel.animateObjectWillChange()
    }

    @MainActor
    public func getSelectedMessages() async -> [MessageRowViewModel] { 
        await viewModel?.historyVM.getSections().flatMap{$0.vms}.filter({$0.calMessage.state.isSelected}) ?? []
    }
}
