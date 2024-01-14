//
//  ChatResponse+.swift
//  TalkExtensions
//
//  Created by hamed on 12/4/22.
//

import ChatCore
import Additive
import Foundation

extension ChatError {
    public var localizedError: String? {
        guard let code = code, let chatCode = ServerErrorType(rawValue: code) else { return nil }
        switch chatCode {
        case .noOtherOwnership:
            return "Thread.onlyAdminError"
        case .temporaryBan:
            guard
                let data = message?.data(using: .utf8),
                let banError = try? JSONDecoder.instance.decode(BanError.self, from: data)
            else { return nil }
            let localized = "General.ban".localized()
            let banTime = banError.duration ?? 0
            return String(format: localized, "\(banTime / 1000)")
        default:
            return nil
        }
    }
}

fileprivate var presentableErrors: [ServerErrorType] = ServerErrorType.allCases

public extension ChatResponse {
    var isPresentable: Bool { presentableErrors.contains(where: { $0.rawValue == error?.code ?? 0}) }
}
