//
//  UserConfigManager.swift
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
    public let ssoToken: SSOTokenResponseResult
}

class UserConfigManager {
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()
    static let instance = UserConfigManager()

    private init() {
        if let userConfig = UserConfigManager.currentUserConfig {
            UserConfigManager.setCurrentUserAndSwitch(userConfig)
        }
    }

    public class var currentUserConfig: UserConfig? {
        let data = UserDefaults.standard.data(forKey: "userConfigData")
        return try? decoder.decode(UserConfig.self, from: data ?? Data())
    }

    public class var userConfigs: [UserConfig] {
        let data = UserDefaults.standard.data(forKey: "userConfigsData")
        let userConfigs = (try? decoder.decode([UserConfig].self, from: data ?? Data())) ?? []
        return userConfigs
    }

    class func addUserInUserDefaultsIfNotExist(userConfig: UserConfig) {
        appendOrReplace(userConfig)
        if ChatManager.activeInstance?.userInfo?.id == currentUserConfig?.id {
            return
        }
        setCurrentUserAndSwitch(userConfig)
    }

    class func appendOrReplace(_ userConfig: UserConfig) {
        var newUserConfigs = userConfigs
        if let index = newUserConfigs.firstIndex(where: { $0.user.id == userConfig.user.id }) {
            newUserConfigs[index] = userConfig
        } else {
            newUserConfigs.append(userConfig)
        }
        UserDefaults.standard.set(newUserConfigs.toData(), forKey: "userConfigsData")
    }

    public class func setCurrentUserAndSwitch(_ userConfig: UserConfig) {
        UserDefaults.standard.setValue(userConfig.toData(), forKey: "userConfigData")
        ChatManager.switchToUser(userId: userConfig.user.id ?? -1)
    }

    public class func createChatObjectAndConnect(userId: Int?, config: ChatConfig) {
        ChatManager.activeInstance?.dispose()
        ChatManager.instance.createOrReplaceUserInstance(userId: userId, config: config)
        ChatManager.activeInstance?.delegate = ChatDelegateImplementation.sharedInstance
        ChatManager.activeInstance?.connect()
    }

    public class func switchToUser(_ userConfig: UserConfig) {
        TokenManager.shared.saveSSOToken(ssoToken: userConfig.ssoToken)
        setCurrentUserAndSwitch(userConfig)
        createChatObjectAndConnect(userId: userConfig.user.id, config: userConfig.config)
    }

    public class func onUser(_ user: User) {
        if let config = ChatManager.activeInstance?.config, let ssoToken = TokenManager.shared.getSSOTokenFromUserDefaults() {
            addUserInUserDefaultsIfNotExist(userConfig: .init(user: user, config: config, ssoToken: ssoToken))
        }
    }
}
