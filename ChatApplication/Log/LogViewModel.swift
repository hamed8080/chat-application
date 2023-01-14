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
import SwiftUI

class LogViewModel: ObservableObject {
    @Published var logs: [Log] = []
    @Published var viewContext: NSManagedObjectContext
    @Published var searchText: String = ""
    fileprivate static let NotificationKey = "InsertLog"
    private(set) var cancellableSet: Set<AnyCancellable> = []

    init(isPreview: Bool = false) {
        viewContext = isPreview ? PSM.preview.container.viewContext : PSM.shared.container.viewContext
        load()
        NotificationCenter.default.publisher(for: Notification.Name(LogViewModel.NotificationKey))
            .compactMap { $0.object as? Log }
            .sink { [weak self] log in
                withAnimation {
                    self?.logs.insert(log, at: 0)
                }
            }
            .store(in: &cancellableSet)
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
            return logs
        } else {
            return logs.filter {
                $0.json?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
    }

    public func clearLogs() {
        logs.forEach { log in
            viewContext.delete(log)
            withAnimation {
                logs.removeAll(where: { $0 == log })
            }
        }
    }
}
