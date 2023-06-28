//
//  ChatDelegateImplementation.swift
//  ChatImplementation
//
//  Created by Hamed Hosseini on 2/6/21.
//

import Chat
import ChatAppModels
import ChatAppViewModels
import ChatCore
import ChatModels
import Foundation
import Logger
import UIKit

final class ChatDelegateImplementation: ChatDelegate {
    private(set) static var sharedInstance = ChatDelegateImplementation()

    func createChatObject() {
        if let userConfig = UserConfigManagerVM.instance.currentUserConfig, let userId = userConfig.id {
            UserConfigManagerVM.instance.createChatObjectAndConnect(userId: userId, config: userConfig.config, delegate: self)
            TokenManager.shared.initSetIsLogin()
        }

        Task {
            await MainActor.run {
                let ssoToken = SSOTokenResponseResult(accessToken: "fcf3671df7fb4bde82153aaacf610e15.XzIwMjM2", expiresIn: 900)
                let config = Config.config(token: ssoToken.accessToken ?? "", selectedServerType: .main)
                let user = User(id: 3_463_768)
                TokenManager.shared.saveSSOToken(ssoToken: ssoToken)
                UserConfigManagerVM.instance.appendOrReplace(UserConfig(user: user, config: config, ssoToken: ssoToken))
                UserConfigManagerVM.instance.createChatObjectAndConnect(userId: user.id, config: config, delegate: self)
            }
        }
    }

    func chatState(state: ChatState, currentUser: User?, error _: ChatError?) {
        switch state {
        case .connecting:
            print("🔄 chat connecting")
            AppState.shared.connectionStatus = .connecting
        case .connected:
            print("🟡 chat connected")
            AppState.shared.connectionStatus = .connecting
        case .closed:
            print("🔴 chat Disconnect")
            AppState.shared.connectionStatus = .disconnected
        case .asyncReady:
            print("🟡 Async ready")
        case .chatReady:
            print("🟢 chat ready Called\(String(describing: currentUser))")
            AppState.shared.connectionStatus = .connected
            NotificationCenter.default.post(name: .connect, object: nil)
        case .uninitialized:
            print("Chat object is not initialized.")
        }
    }

    func chatEvent(event: ChatEventType) {
        print(dump(event))
        NotificationCenter.post(event: event)
        switch event {
        case let .system(systemEventTypes):
            onSystemEvent(systemEventTypes)
        case let .user(userEventTypes):
            onUserEvent(userEventTypes)
        default:
            break
        }
    }

    private func onUserEvent(_ event: UserEventTypes) {
        switch event {
        case let .user(response):
            if let user = response.result {
                UserConfigManagerVM.instance.onUser(user)
            }
        default:
            break
        }
    }

    private func onSystemEvent(_ event: SystemEventTypes) {
        switch event {
        case let .error(chatResponse):
            onError(chatResponse)
        default:
            break
        }
    }

    private func onError(_ response: ChatResponse<Any>) {
        print(response)
        guard let error = response.error else { return }
        if error.code == 21 || error.code == 401 {
            TokenManager.shared.getNewTokenWithRefreshToken()
            AppState.shared.connectionStatus = .unauthorized
        } else {
            AppState.shared.animateAndShowError(error)
        }
    }

    func onLog(log: Log) {
        NotificationCenter.default.post(name: .logs, object: log)
        print(log.message ?? "", "\n")
    }
}
