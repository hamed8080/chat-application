import Combine
import Chat
import SwiftUI
import TalkModels
import ChatModels

public final class NavigationModel: ObservableObject {
    @Published public var selectedSideBarId: String? = "Tab.chats"
    @Published public var selectedThreadId: Conversation.ID? {
        didSet {
            if let selectedThread = selectedThread {
                currentThreadVM = .init(thread: selectedThread, threadsViewModel: threadViewModel)
                clearThreadStack()
                animateObjectWillChange()
            }
        }
    }
    @Published public var selectedThreadIds: Set<Conversation.ID> = []
    @Published public var selectedTagId: Tag.ID?
    public var threadViewModel: ThreadsViewModel?
    public var contactsViewModel: ContactsViewModel?
    public var sections: [TalkModels.Section] = []
    public var cancelable: AnyCancellable?
    @Published public var paths = NavigationPath()
    public var currentThreadVM: ThreadViewModel?
    var threadStack: [ThreadViewModel] = []

    public init() {
        setup()
    }

    public func setup() {
        sections.append(
            .init(title: "Tab.chats", items:
                    [
                        .init(id: "Tab.contacts", title: "Tab.contacts", icon: "person.icloud"),
                        .init(id: "Tab.chats", title: "Tab.chats", icon: "captions.bubble"),
                        .init(id: "Tab.archives", title: "Tab.archives", icon: "tray.and.arrow.down"),
                    ]))

        sections.append(.init(title: "Tab.folders", items: []))
        sections.append(.init(title: "Tab.settings", items: [.init(id: "Tab.settings", title: "Tab.settings", icon: "gear")]))
        cancelable = $selectedSideBarId.sink { [weak self] newValue in
            if newValue != self?.selectedSideBarId {
                self?.manageThreadChange(newValue)
            }
        }
        selectedSideBarId = selectedSideBarIdStorage
    }

    public func manageThreadChange(_ newValue: String?) {
        threadViewModel?.title = sectionItem(newValue)?.title ?? ""
        if newValue == "Tab.archives" {
            threadViewModel?.getArchivedThreads()
        } else if selectedSideBarId == "Tab.archives" {
            threadViewModel?.resetArchiveSettings()
        }

        if let folder = folder(newValue) {
            threadViewModel?.getThreadsInsideFolder(folder)
        } else if selectedSideBarId?.contains("Tag") == true {
            threadViewModel?.resetFolderSettings()
        }
        saveToUserDefaults(selectedSideBarId: newValue)
    }

    func saveToUserDefaults(selectedSideBarId: String?) {
        UserDefaults.standard.setValue(selectedSideBarId, forKey: "selectedSideBarId")
    }

    var selectedSideBarIdStorage: String {
        UserDefaults.standard.string(forKey: "selectedSideBarId") ?? "Tab.chats"
    }

    public func addTags(_ tags: [Tag]) {
        if tags.count == 0 { return }
        tags.forEach { tag in
            let tagId = "Tag-\(tag.id)"
            let foldersSectionIndex = sections.firstIndex(where: { $0.title == "Tab.folders" })
            guard let foldersSectionIndex = foldersSectionIndex else { return }
            if !sections[foldersSectionIndex].items.contains(where: { $0.id == tagId }) {
                sections[foldersSectionIndex].items.append(.init(id: tagId, tag: tag, title: tag.name, icon: "folder"))
            } else if let oldtagIndex = sections[foldersSectionIndex].items.firstIndex(where: { $0.id == tagId }) {
                sections[foldersSectionIndex].items[oldtagIndex].tag = tag
            }
        }
        animateObjectWillChange()
    }

    public func clear() {
        sections = []
        animateObjectWillChange()
    }

    public var isThreadType: Bool {
        let type = selectedSideBarId ?? ""
        return type.contains("Tag") || type == "Tab.chats" || type == "Tab.archives"
    }

    public func folder(_ selectedSideBarId: String?) -> Tag? {
        sections.first(where: { $0.title == "Tab.folders" })?.items.first(where: { $0.id == selectedSideBarId })?.tag
    }

    public var selectedThread: Conversation? {
        threadViewModel?.threads.first(where: { $0.id == selectedThreadId })
    }

    public func sectionItem(_ selectedSideBarId: String?) -> SideBarItem? {
        sections.flatMap(\.items).first(where: { $0.id == selectedSideBarId })
    }

    public func append(participantDetail: Participant) {
        paths.append(DetailViewModel(user: participantDetail))
    }

    public func append(threadDetail: Conversation) {
        paths.append(DetailViewModel(thread: threadDetail))
    }

    public func append(thread: Conversation) {
        if !threadStack.contains(where: {$0.threadId == thread.id}) {
            threadStack.append(ThreadViewModel(thread: thread, threadsViewModel: threadViewModel))
        }
        paths.append(thread)
    }

    public func threadViewModel(threadId: Int) -> ThreadViewModel? {
        /// We return last for when the user sends the first message inside a p2p thread after sending a message the thread object inside the ThreadViewModel will change to update the new id and other stuff.
        return threadStack.first(where: {$0.threadId == threadId}) ?? threadStack.last
    }

    public func clearThreadStack() {
        threadStack.removeAll()
    }

    var presentedThreadViewModel: ThreadViewModel? {
        threadStack.last
    }
}
