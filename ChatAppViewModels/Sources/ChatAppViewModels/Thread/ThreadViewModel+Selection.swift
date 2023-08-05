//
//  ThreadViewModel+Selection.swift
//  ChatApplication
//
//  Created by hamed on 11/24/22.
//

import Foundation

public extension ThreadViewModel {
    var selectedMessages: [MessageRowViewModel] { messageViewModels.filter({$0.isSelected}) }
    func clearSelection() {
        selectedMessages.forEach { viewModel in
            viewModel.isSelected = false
        }
        animateObjectWillChange()
    }
}
