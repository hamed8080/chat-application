//
//  SettingViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
import Combine
import SwiftUI
import ChatModels
import ChatAppModels

public final class SettingViewModel: ObservableObject {
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false

    public init() {
        AppState.shared.$connectionStatus
            .sink{ [weak self] status in
                self?.onConnectionStatusChanged(status)
            }
            .store(in: &cancellableSet)
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            firstSuccessResponse = true
        }
    }
}
