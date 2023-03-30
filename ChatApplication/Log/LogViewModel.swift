//
//  LogViewModel.swift
//  ChatApplication
//
//  Created by hamed on 6/27/22.
//

import Combine
import CoreData
import FanapPodChatSDK
import Foundation

final class LogViewModel: ObservableObject {
    @Published var logs: [Log] = []
    @Published var viewContext: NSManagedObjectContext
    @Published var searchText: String = ""
    @Published var type: LogEmitter?
    private(set) var cancellableSet: Set<AnyCancellable> = []

    init(isPreview: Bool = false) {
        viewContext = isPreview ? PSM.preview.container.viewContext : PSM.shared.container.viewContext
        load()
        NotificationCenter.default.publisher(for: .logsName)
            .compactMap { $0.object as? FanapPodChatSDK.Log }
            .sink { [weak self] sdkLog in
                self?.addSdkLog(sdkLog)
            }
            .store(in: &cancellableSet)
    }

    private func addSdkLog(_ sdkLog: FanapPodChatSDK.Log) {
        Task {
            await MainActor.run {
                let log = Log(context: viewContext)
                log.createDate = sdkLog.time ?? Date()
                log.type = Int64(sdkLog.type?.rawValue ?? 0)
                log.log = sdkLog.message
                logs.insert(log, at: 0)
                try? viewContext.save()
            }
        }
    }

    func load() {
        let req = Log.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \Log.createDate, ascending: false)]
        do {
            logs = try viewContext.fetch(req)
        } catch {
            print("Fetch failed: Error \(error.localizedDescription)")
        }
    }

    var filtered: [Log] {
        if searchText.isEmpty {
            return type == nil ? logs : logs.filter { $0.type == type?.rawValue ?? 0 }
        } else {
            if let type = type {
                return logs.filter {
                    $0.log?.lowercased().contains(searchText.lowercased()) ?? false && $0.type == type.rawValue
                }
            } else {
                return logs.filter {
                    $0.log?.lowercased().contains(searchText.lowercased()) ?? false
                }
            }
        }
    }

    public func deleteLogs() {
        logs.forEach { log in
            viewContext.delete(log)
            clearLogs()
        }
    }

    public func clearLogs() {
        logs.removeAll()
    }
}
