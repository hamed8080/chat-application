import Combine
import Chat
import SwiftUI
import TalkModels
import ChatModels

public struct PreferenceNavigationValue: Hashable {}
public struct AssistantNavigationValue: Hashable {}
public struct LogNavigationValue: Hashable {}
public struct BlockedContactsNavigationValue: Hashable {}
public struct NotificationSettingsNavigationValue: Hashable {}
public struct SupportNavigationValue: Hashable {}

public final class NavigationModel: ObservableObject {
    @Published public var selectedThreadId: Conversation.ID?
    public var threadViewModel: ThreadsViewModel?
    @Published public var paths = NavigationPath()
    var threadStack: [ThreadViewModel] = []
    var pathsTracking: [Any] = []
    public init() {}

    public func clear() {
        animateObjectWillChange()
    }

    public func appendBlockedContacts() {
        let blockedContacts = BlockedContactsNavigationValue()
        paths.append(blockedContacts)
        pathsTracking.append(blockedContacts)
    }

    public func appendPreference() {
        let preference = PreferenceNavigationValue()
        paths.append(preference)
        pathsTracking.append(preference)
    }

    public func appendAssistant() {
        let assistant = AssistantNavigationValue()
        paths.append(assistant)
        pathsTracking.append(assistant)
    }

    public func appendNotificationSetting() {
        let notification = NotificationSettingsNavigationValue()
        paths.append(notification)
        pathsTracking.append(notification)
    }

    public func appendSupport() {
        let support = SupportNavigationValue()
        paths.append(support)
        pathsTracking.append(support)
    }

    public func appendLog() {
        let log = LogNavigationValue()
        paths.append(log)
        pathsTracking.append(log)
    }

    public func append(participantDetail: Participant) {
        paths.append(DetailViewModel(user: participantDetail))
    }

    public func append(threadDetail: Conversation) {
        let detailViewModel = DetailViewModel(thread: threadDetail)
        detailViewModel.threadVM = pathsTracking
            .compactMap{$0 as? ThreadViewModel}
            .first(where: {$0.threadId == threadDetail.id})
        paths.append(detailViewModel)
        pathsTracking.append(detailViewModel)
        selectedThreadId = threadDetail.id
    }

    public func append(thread: Conversation) {
        if !threadStack.contains(where: {$0.threadId == thread.id}) {
            let threadViewModel = ThreadViewModel(thread: thread, threadsViewModel: threadViewModel)
            threadStack.append(threadViewModel)
            pathsTracking.append(threadViewModel)
        }
        paths.append(thread)
        selectedThreadId = thread.id
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

    public func remove<T>(type: T.Type, threadId: Int? = nil) {
        if pathsTracking.filter({$0 is T }).count == 1 {
            if type is ThreadViewModel.Type {
                threadStack.removeAll(where: { $0.threadId == threadId })
            }
            pathsTracking.removeAll(where: {($0 is T)})
        } else if let index = pathsTracking.firstIndex(where: {$0 is T }) {
            pathsTracking.remove(at: index)
            if threadStack.filter({$0.threadId == threadId}).count == 1, let index = threadStack.lastIndex(where: {$0.threadId == threadId}) {
                threadStack.remove(at: index)
            }
        }
        setSelectedThreadId()
    }

    public func setSelectedThreadId() {
        selectedThreadId = threadStack.last?.threadId
    }

    public var previousItem: Any? {
        if pathsTracking.count > 1 {
            return pathsTracking[pathsTracking.count - 2]
        } else {
            return nil
        }
    }

    public var previousTitle: String {
        if let thread = previousItem as? Conversation {
            return thread.computedTitle
        } else if let threadVM = previousItem as? ThreadViewModel {
            return threadVM.thread.computedTitle
        } else if previousItem is PreferenceNavigationValue {
            return "Settings.title"
        } else if previousItem is BlockedContactsNavigationValue {
            return "Contacts.blockedList"
        } else if let detail = previousItem as? DetailViewModel {
            return detail.title
        } else if previousItem is LogNavigationValue {
            return "Logs.title"
        } else if previousItem is AssistantNavigationValue {
            return "Assistant.Assistants"
        } else {
            return ""
        }
    }
}
