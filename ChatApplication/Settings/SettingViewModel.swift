//
//  SettingViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Chat
import Combine
import SwiftUI

final class SettingViewModel: ObservableObject {
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false

    init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            firstSuccessResponse = true
        }
    }
}
