//
//  File.swift
//  
//
//  Created by hamed on 2/13/24.
//

import Foundation

public extension URL {
    var widgetThreaId: Int? {
        if !absoluteString.contains("Widget") { return nil }
        let threadIdString = absoluteString.replacingOccurrences(of: "Widget://link-", with: "")
        guard let threadId = Int(threadIdString) else { return nil }
        return threadId
    }

    var openThreadUserName: String? {
        if !absoluteString.contains("showUser") { return nil }
        let userName = absoluteString.replacingOccurrences(of: "showUser:User?userName=", with: "")
        return userName
    }

    var decodedOpenURL: URL? {
        if !absoluteString.contains("openURL") { return nil }
        let encodedURL = absoluteString.replacingOccurrences(of: "openURL:url?encodedValue=", with: "")
        guard
            let data = Data(base64Encoded: encodedURL),
           let decodedString = String(data: data, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let decodedURL = URL(string: decodedString)
        else { return nil }
        return decodedURL
    }
}
