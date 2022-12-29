//
//  Config.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/5/21.
//

import Foundation

enum Server {
    case integeration
    case sandbox
    case main

    var description: String {
        String(reflecting: self)
    }
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
    static func getConfig(_ server: Server = .integeration) -> Config? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: ".json") else { return nil }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
            let configs = try? JSONDecoder().decode([Config].self, from: data)
            let selectedConfig = configs?.first { $0.server == String(describing: server) }
            return selectedConfig
        } else {
            return nil
        }
    }
}
