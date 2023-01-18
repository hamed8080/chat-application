//
//  SettingViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 9/17/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

class SettingViewModel: ObservableObject {
    @Published var currentUser: User?
    private(set) var cancellableSet: Set<AnyCancellable> = []
    private(set) var firstSuccessResponse = false

    init() {
        let currentUser = ChatManager.activeInstance.userInfo ?? AppState.shared.user
        self.currentUser = currentUser
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
