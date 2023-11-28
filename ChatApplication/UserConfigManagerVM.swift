//
//  UserConfigManagerVM.swift
//  ChatApplication
//
//  Created by hamed on 1/28/23.
//

import FanapPodChatSDK
import Foundation
import SwiftUI

public struct UserConfig: Codable, Identifiable {
    public var id: Int? { user.id }
    public let user: User
    public let config: ChatConfig
    public let ssoToken: SSOTokenResponse
}

class UserConfigManagerVM: ObservableObject, Equatable {
    static func == (lhs: UserConfigManagerVM, rhs: UserConfigManagerVM) -> Bool {
        lhs.userConfigs.count == rhs.userConfigs.count
    }

    @Published var userConfigs: [UserConfig] = []
    @Published var currentUserConfig: UserConfig?

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    static let instance = UserConfigManagerVM()

    private init() {
        setup()
    }

    private func setup() {
        if let data = UserDefaults.standard.data(forKey: "userConfigsData"), let userConfigs = try? decoder.decode([UserConfig].self, from: data) {
            self.userConfigs = userConfigs
        }

        if let data = UserDefaults.standard.data(forKey: "userConfigData"), let currentUserConfig = try? decoder.decode(UserConfig.self, from: data) {
            self.currentUserConfig = currentUserConfig
            setCurrentUserAndSwitch(currentUserConfig)
        }
    }

    func addUserInUserDefaultsIfNotExist(userConfig: UserConfig) {
        appendOrReplace(userConfig)
        setCurrentUserAndSwitch(userConfig)
        setup()
    }

    func appendOrReplace(_ userConfig: UserConfig) {
        var newUserConfigs = userConfigs
        if let index = newUserConfigs.firstIndex(where: { $0.user.id == userConfig.user.id }) {
            newUserConfigs[index] = userConfig
        } else {
            newUserConfigs.append(userConfig)
        }
        UserDefaults.standard.set(newUserConfigs.toData(), forKey: "userConfigsData")
    }

    public func setCurrentUserAndSwitch(_ userConfig: UserConfig) {
        UserDefaults.standard.setValue(userConfig.toData(), forKey: "userConfigData")
    }

    public func createChatObjectAndConnect(userId: Int?, config: ChatConfig) {
        ChatManager.activeInstance?.dispose()
        ChatManager.instance.createOrReplaceUserInstance(userId: userId, config: config)
        ChatManager.activeInstance?.delegate = ChatDelegateImplementation.sharedInstance
        ChatManager.activeInstance?.connect()
    }

    public func switchToUser(_ userConfig: UserConfig) {
        TokenManager.shared.saveSSOToken(ssoToken: userConfig.ssoToken)
        setCurrentUserAndSwitch(userConfig)
        createChatObjectAndConnect(userId: userConfig.user.id, config: userConfig.config)
        setup() // to set current user @Published var
    }

    public func onUser(_ user: User) {
        if let config = ChatManager.activeInstance?.config, let ssoToken = TokenManager.shared.getSSOTokenFromUserDefaults() {
            addUserInUserDefaultsIfNotExist(userConfig: .init(user: user, config: config, ssoToken: ssoToken))
        }
    }

    func logout() {
        if let index = userConfigs.firstIndex(where: { $0.id == currentUserConfig?.id }) {
            userConfigs.remove(at: index)
            UserDefaults.standard.set(userConfigs.toData(), forKey: "userConfigsData")
            setup()
            if let firstUser = userConfigs.first {
                switchToUser(firstUser)
            }
        }
    }
}
