import Chat
import Combine
import ChatModels
import ChatAppModels
import Foundation
import ChatCore

public final class UserConfigManagerVM: ObservableObject, Equatable {
    public static func == (lhs: UserConfigManagerVM, rhs: UserConfigManagerVM) -> Bool {
        lhs.userConfigs.count == rhs.userConfigs.count
    }

    @Published public var userConfigs: [UserConfig] = []
    @Published public var currentUserConfig: UserConfig?
    public static let instance = UserConfigManagerVM()

    private init() {
        setup()
    }

    private func setup() {
        if let data = UserDefaults.standard.data(forKey: "userConfigsData"), let userConfigs = try? JSONDecoder.instance.decode([UserConfig].self, from: data) {
            self.userConfigs = userConfigs
        }

        if let data = UserDefaults.standard.data(forKey: "userConfigData"), let currentUserConfig = try? JSONDecoder.instance.decode(UserConfig.self, from: data) {
            self.currentUserConfig = currentUserConfig
            setCurrentUserAndSwitch(currentUserConfig)
        }
    }

    public func addUserInUserDefaultsIfNotExist(userConfig: UserConfig) {
        appendOrReplace(userConfig)
        setCurrentUserAndSwitch(userConfig)
        setup()
    }

    public func appendOrReplace(_ userConfig: UserConfig) {
        var newUserConfigs = userConfigs
        if let index = newUserConfigs.firstIndex(where: { $0.user.id == userConfig.user.id }) {
            newUserConfigs[index] = userConfig
        } else {
            newUserConfigs.append(userConfig)
        }
        UserDefaults.standard.set(newUserConfigs.data, forKey: "userConfigsData")
    }

    public func setCurrentUserAndSwitch(_ userConfig: UserConfig) {
        UserDefaults.standard.setValue(userConfig.data, forKey: "userConfigData")
        ChatManager.switchToUser(userId: userConfig.user.id ?? -1)
    }

    public func createChatObjectAndConnect(userId: Int?, config: ChatConfig, delegate: ChatDelegate?) {
        ChatManager.activeInstance?.dispose()
        ChatManager.instance.createOrReplaceUserInstance(userId: userId, config: config)
        ChatManager.activeInstance?.delegate = delegate
        ChatManager.activeInstance?.connect()
    }

    public func switchToUser(_ userConfig: UserConfig, delegate: ChatDelegate) {
        TokenManager.shared.saveSSOToken(ssoToken: userConfig.ssoToken)
        setCurrentUserAndSwitch(userConfig)
        createChatObjectAndConnect(userId: userConfig.user.id, config: userConfig.config, delegate: delegate)
        setup() // to set current user @Published var
    }

    public func onUser(_ user: User) {
        if let config = ChatManager.activeInstance?.config, let ssoToken = TokenManager.shared.getSSOTokenFromUserDefaults() {
            addUserInUserDefaultsIfNotExist(userConfig: .init(user: user, config: config, ssoToken: ssoToken))
        }
    }

    public func logout(delegate: ChatDelegate) {
        if let index = userConfigs.firstIndex(where: { $0.id == currentUserConfig?.id }) {
            userConfigs.remove(at: index)
            UserDefaults.standard.set(userConfigs.data, forKey: "userConfigsData")
            setup()
            if let firstUser = userConfigs.first {
                switchToUser(firstUser, delegate: delegate)
            } else {
                // Remove last user config from userDefaults
                UserDefaults.standard.removeObject(forKey: "userConfigData")
            }
        }
    }
}
