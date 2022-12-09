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

    class func printCallLogsFile() {
//        if let appSupportDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false){
//            let logFileDir = "WEBRTC-LOG"
//            let url = appSupportDir.appendingPathComponent(logFileDir)
//            let contentsOfDir = try? FileManager.default.contentsOfDirectory(atPath: url.path)
//
//            DispatchQueue.global(qos: .background).async {
//                let df = DateFormatter()
//                df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
//                let dateString = df.string(from: Date())
//                FileManager.default.zipFile(urlPathToZip: url, zipName: "WEBRTC-Logs-\(dateString)") { zipFile in
//                    if let zipFile = zipFile{
//                        AppState.shared.callLogs = [zipFile]
//                    }
//                }
//            }
//
//            contentsOfDir?.forEach({ file in
//                DispatchQueue.global(qos: .background).async {
//                    if let data = try? Data(contentsOf: url.appendingPathComponent(file)) , let string = String(data: data, encoding: .utf8){
//                        print("data of log file '\(file)' is:\n")
//                        print(string)
//                        let log = LogResult(json: string, receive: false)
//                        ResultViewController.addToLog(logResult: log)
//                    }
//                }
//            })
//        }
    }

    public func clearLogs() {
        logs.forEach { log in
            viewContext.delete(log)
            withAnimation {
                logs.removeAll(where: { $0 == log })
            }
        }
        CacheFactory.save()
    }

    public class func addToLog(logResult: LogResult) {
        DispatchQueue.main.async {
            withAnimation {
                let log = Log(context: PSM.shared.context)
                log.json = logResult.json
                log.received = logResult.receive
                log.createDate = Date()
                CacheFactory.save()
                NotificationCenter.default.post(name: NSNotification.Name(LogViewModel.NotificationKey), object: log)
            }
        }
    }
}
