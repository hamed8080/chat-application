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

    @Published var imageLoader: ImageLoader

    init() {
        let currentUser = ChatManager.activeInstance.userInfo ?? AppState.shared.user
        imageLoader = ImageLoader(url: currentUser?.image ?? "", userName: currentUser?.username ?? currentUser?.name, size: .LARG)
        self.currentUser = currentUser
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        imageLoader.$image.sink { _ in
            self.objectWillChange.send()
        }
        .store(in: &cancellableSet)
        imageLoader.fetch()
    }

    func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            firstSuccessResponse = true
        }
    }
}
