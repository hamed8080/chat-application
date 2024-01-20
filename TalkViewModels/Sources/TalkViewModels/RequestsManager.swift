//
//  BotViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import ChatDTO
import ChatCore

class RequestsManager {
    public static let shared = RequestsManager()
    public var requests: [String: ChatDTO.UniqueIdProtocol] = [:]
    private var queue = DispatchQueue(label: "RequestQueue")

    private init(){}

    func append(value: ChatDTO.UniqueIdProtocol, autoCancel: Bool = true) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(value.uniqueId)"
            requests[key] = value
            if autoCancel {
                addCancelTimer(key: key)
            }
        }
    }

    func append(prepend: String, value: ChatDTO.UniqueIdProtocol, autoCancel: Bool = true) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(prepend)-\(value.uniqueId)"
            requests[key] = value
            if autoCancel {
                addCancelTimer(key: key)
            }
        }
    }

    @discardableResult
    func remove(prepend: String, for key: String) -> Bool {
        remove(key: "\(prepend)-\(key)")
    }

    @discardableResult
    func remove(key: String) -> Bool {
        if !requests.keys.contains(key) { return false }
        requests.removeValue(forKey: key)
        return true
    }

    func value(prepend: String, for key: String?) -> ChatDTO.UniqueIdProtocol? {
        guard let key = key else { return nil }
        let prependedKey = "\(prepend)-\(key)"
        if !requests.keys.contains(prependedKey) { return nil }
        return requests[prependedKey]
    }

    func pop(prepend: String, for key: String?) -> ChatDTO.UniqueIdProtocol? {
        guard let key = key else { return nil }
        let prependedKey = "\(prepend)-\(key)"
        if !requests.keys.contains(prependedKey) { return nil }
        requests.removeValue(forKey: prependedKey)
        return requests[prependedKey]
    }

    func value(for key: String?) -> ChatDTO.UniqueIdProtocol? {
        guard let key = key, requests.keys.contains(key) else { return nil }
        return requests[key]
    }

    /// Automatically cancel a request if there is no response come back from the chat server after 25 seconds.
    func addCancelTimer(key: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            if ((self?.requests.keys.contains(where: { $0 == key})) != nil) {
                self?.remove(key: key)
                NotificationCenter.onRequestTimer.post(name: .onRequestTimer, object: key)
            }
        }
    }
}

public extension ChatResponse {

    var value: ChatDTO.UniqueIdProtocol? {
        guard let uniqueId = uniqueId else { return nil }
        return RequestsManager.shared.value(for: uniqueId)
    }

    @discardableResult
    func value(prepend: String) -> ChatDTO.UniqueIdProtocol? {
        guard let uniqueId = uniqueId else { return nil }
        return RequestsManager.shared.value(prepend: prepend, for: uniqueId)
    }

    @discardableResult
    func pop(prepend: String) -> ChatDTO.UniqueIdProtocol? {
        guard let uniqueId = uniqueId else { return nil }
        return RequestsManager.shared.value(prepend: prepend, for: uniqueId)
    }
}
