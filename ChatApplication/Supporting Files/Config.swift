//
//  Config.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/5/21.
//

import FanapPodAsyncSDK
import FanapPodChatSDK
import Foundation

enum ServerTypes: String, CaseIterable, Identifiable {
    var id: Self { self }
    case main
    case sandbox
    case integration
}

struct Config: Codable {
    var socketAddresss: String
    var ssoHost: String
    var platformHost: String
    var fileServer: String
    var serverName: String
    var debugToken: String?
    var server: String
}

extension Config {
    static func getConfig(_ server: ServerTypes = .integration) -> Config? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: ".json") else { return nil }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            let configs = try? JSONDecoder().decode([Config].self, from: data)
            let selectedConfig = configs?.first { $0.server == String(describing: server) }
            return selectedConfig
        } else {
            return nil
        }
    }

    static func config(token: String, selectedServerType: ServerTypes) -> ChatConfig {
        guard let config = Config.getConfig(selectedServerType) else { fatalError("couldn't find config in the json file!") }
        let asyncConfig = AsyncConfigBuilder()
            .socketAddress(config.socketAddresss)
            .reconnectCount(Int.max)
            .reconnectOnClose(true)
            .appId("PodChat")
            .serverName(config.serverName)
            .isDebuggingLogEnabled(false)
            .build()
        let chatConfig = ChatConfigBuilder(asyncConfig)
            .token(token)
            .ssoHost(config.ssoHost)
            .platformHost(config.platformHost)
            .fileServer(config.fileServer)
            .enableCache(false)
            .msgTTL(800_000) // for integeration server need to be long time
            .isDebuggingLogEnabled(true)
            .persistLogsOnServer(true)
            .appGroup(AppGroup.group)
            .sendLogInterval(15)
            .build()
        return chatConfig
    }

    static func serverType(config: ChatConfig?) -> ServerTypes? {
        if config?.asyncConfig.socketAddress == Config.getConfig(.main)?.socketAddresss {
            return .main
        } else if config?.asyncConfig.socketAddress == Config.getConfig(.sandbox)?.socketAddresss {
            return .sandbox
        } else if config?.asyncConfig.socketAddress == Config.getConfig(.integration)?.socketAddresss {
            return .integration
        } else {
            return nil
        }
    }
}
