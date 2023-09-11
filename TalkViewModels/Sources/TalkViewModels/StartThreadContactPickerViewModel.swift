//
//  StartThreadContactPickerViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import Foundation
import ChatModels
import TalkModels

final class StartThreadContactPickerViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public private(set) var model = StartThreadModel()
    public private(set) var cancellableSet: Set<AnyCancellable> = []

    public init() {
        AppState.shared.$connectionStatus.sink { [weak self] status in
            if self?.model.threads.count == 0, status == .connected {}
        }
        .store(in: &cancellableSet)
    }
}
