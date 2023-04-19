//
//  LogViewModel.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Chat
import Combine
import CoreData
import Foundation
import Logger

public final class LogViewModel: ObservableObject {
    @Published public var logs: [Log] = []
    @Published public var searchText: String = ""
    @Published public var type: LogEmitter?
    public private(set) var cancellableSet: Set<AnyCancellable> = []

    public init() {
        NotificationCenter.default.publisher(for: .logsName)
            .compactMap { $0.object as? Log }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] log in
                self?.logs.insert(log, at: 0)
            }
            .store(in: &cancellableSet)
    }

    public var filtered: [Log] {
        if searchText.isEmpty {
            return type == nil ? logs : logs.filter { $0.type == type }
        } else {
            if let type = type {
                return logs.filter {
                    $0.message?.lowercased().contains(searchText.lowercased()) ?? false && $0.type == type
                }
            } else {
                return logs.filter {
                    $0.message?.lowercased().contains(searchText.lowercased()) ?? false
                }
            }
        }
    }

    public func deleteLogs() {
        logs.forEach { _ in
            Logger.clear(prefix: "CHAT_SDK")
            Logger.clear(prefix: "ASYNC_SDK")
            clearLogs()
        }
    }

    public func clearLogs() {
        logs.removeAll()
    }
}
