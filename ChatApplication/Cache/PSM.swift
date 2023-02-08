//
//  PSM.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//
// TLDR 'Persistance Service Manager'
import CoreData

class PSM {
    static let shared = PSM()
    static let modelName = "ChatApplicationDataModel"
    static let previewPS = PSM(inMemory: true)

    static var previewVC: NSManagedObjectContext {
        previewPS.container.viewContext
    }

    var container: NSPersistentCloudKitContainer

    static var preview: PSM = {
        let logs = generateLogs(5)
        do {
            try previewVC.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return previewPS
    }()

    static func generateLogs(_ count: Int) -> [Log] {
        var logs: [Log] = []
        for index in 0 ..< count {
            let log = Log(context: previewVC)
            log.received = index % 2 == 0
            log.json = "Test\(index)"
            logs.append(log)
        }
        return logs
    }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: PSM.modelName)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                #if DEBUG
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                #endif
            }
        } else {
            print("Application Cache Nothing has changed")
        }
    }
}
