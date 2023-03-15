//
//  NavigationModel.swift
//  ChatApplication
//
//  Created by hamed on 1/21/23.
//

import Combine
import FanapPodChatSDK
import Foundation

class NavigationModel: ObservableObject {
    @Published var selectedSideBarId: String? = "Chats"
    @Published var selectedThreadId: Conversation.ID?
    @Published var selectedThreadIds: Set<Conversation.ID> = []
    @Published var selectedTagId: Tag.ID?
    var threadViewModel: ThreadsViewModel?
    var contactsViewModel: ContactsViewModel?
    var sections: [Section] = []
    var cancelable: AnyCancellable?

    init() {
        setup()
    }

    func setup() {
        sections.append(
            .init(title: "Chats", items:
                [
                    .init(id: "Contacts", title: "Contacts", icon: "person.icloud"),
                    .init(id: "Chats", title: "Chats", icon: "captions.bubble"),
                    .init(id: "Archives", title: "Archives", icon: "tray.and.arrow.down"),
                ]))
        sections.append(.init(title: "Folders", items: []))
        sections.append(.init(title: "Settings", items: [.init(id: "Settings", title: "Settings", icon: "gear")]))
        cancelable = $selectedSideBarId.sink { [weak self] newValue in
            if newValue != self?.selectedSideBarId {
                self?.manageThreadChange(newValue)
            }
        }
    }

    func manageThreadChange(_ newValue: String?) {
        threadViewModel?.title = sectionItem(newValue)?.title ?? ""
        if newValue == "Archives" {
            threadViewModel?.getArchivedThreads()
        } else if selectedSideBarId == "Archives" {
            threadViewModel?.resetArchiveSettings()
        }

        if let folder = folder(newValue) {
            threadViewModel?.getThreadsInsideFolder(folder)
        } else if selectedSideBarId?.contains("Tag") == true {
            threadViewModel?.resetFolderSettings()
        }
    }

    func addTags(_ tags: [Tag]) {
        if tags.count == 0 { return }
        tags.forEach { tag in
            let tagId = "Tag-\(tag.id)"
            let foldersSectionIndex = sections.firstIndex(where: { $0.title == "Folders" })
            guard let foldersSectionIndex = foldersSectionIndex else { return }
            if !sections[foldersSectionIndex].items.contains(where: { $0.id == tagId }) {
                sections[foldersSectionIndex].items.append(.init(id: tagId, tag: tag, title: tag.name, icon: "folder"))
            } else if let oldtagIndex = sections[foldersSectionIndex].items.firstIndex(where: { $0.id == tagId }) {
                sections[foldersSectionIndex].items[oldtagIndex].tag = tag
            }
        }
        objectWillChange.send()
    }

    func clear() {
        sections = []
        objectWillChange.send()
    }

    var isThreadType: Bool {
        let type = selectedSideBarId ?? ""
        return type.contains("Tag") || type == "Chats" || type == "Archives"
    }

    func folder(_ selectedSideBarId: String?) -> Tag? {
        sections.first(where: { $0.title == "Folders" })?.items.first(where: { $0.id == selectedSideBarId })?.tag
    }

    var selectedThread: Conversation? {
        threadViewModel?.threads.first(where: { $0.id == selectedThreadId })
    }

    func sectionItem(_ selectedSideBarId: String?) -> SideBarItem? {
        sections.flatMap(\.items).first(where: { $0.id == selectedSideBarId })
    }

    struct Section: Hashable, Identifiable {
        var id = UUID()
        var title: String
        var items: [SideBarItem]
    }

    struct SideBarItem: Identifiable, Hashable {
        var id: String
        var tag: Tag?
        var title: String
        var icon: String
    }
}
