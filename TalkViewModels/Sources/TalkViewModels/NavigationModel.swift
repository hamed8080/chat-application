import Combine
import Chat
import SwiftUI
import TalkModels
import ChatModels

public enum NavigationType: Hashable {
    case conversation(Conversation)
    case contact(Contact)
    case detail(DetailViewModel)
    case preference(PreferenceNavigationValue)
    case assistant(AssistantNavigationValue)
    case log(LogNavigationValue)
    case archives(ArchivesNavigationValue)
    case language(LanguageNavigationValue)
    case blockedContacts(BlockedContactsNavigationValue)
    case notificationSettings(NotificationSettingsNavigationValue)
    case automaticDownloadsSettings(AutomaticDownloadsNavigationValue)
    case support(SupportNavigationValue)
    case messageParticipantsSeen(MessageParticipantsSeenNavigationValue)
}

public protocol NavigaitonValueProtocol: Hashable {}
public struct PreferenceNavigationValue: NavigaitonValueProtocol {}
public struct AssistantNavigationValue: NavigaitonValueProtocol {}
public struct LogNavigationValue: NavigaitonValueProtocol {}
public struct ArchivesNavigationValue: NavigaitonValueProtocol {}
public struct LanguageNavigationValue: NavigaitonValueProtocol {}
public struct BlockedContactsNavigationValue: NavigaitonValueProtocol {}
public struct NotificationSettingsNavigationValue: NavigaitonValueProtocol {}
public struct AutomaticDownloadsNavigationValue: NavigaitonValueProtocol {}
public struct SupportNavigationValue: NavigaitonValueProtocol {}
public struct MessageParticipantsSeenNavigationValue: NavigaitonValueProtocol { public let message: Message }

public final class NavigationModel: ObservableObject {
    @Published public var selectedThreadId: Conversation.ID?
    public var threadsViewModel: ThreadsViewModel?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
    private var threadStack: [ThreadViewModel] { pathsTracking.compactMap{ $0 as? ThreadViewModel}}
    public init() {}

    public func clear() {
        animateObjectWillChange()
    }

    public func appendBlockedContacts() {
        let blockedContacts = BlockedContactsNavigationValue()
        paths.append(NavigationType.blockedContacts(blockedContacts))
        pathsTracking.append(blockedContacts)
    }

    public func appendPreference() {
        let preference = PreferenceNavigationValue()
        paths.append(NavigationType.preference(preference))
        pathsTracking.append(preference)
    }

    public func appendAssistant() {
        let assistant = AssistantNavigationValue()
        paths.append(NavigationType.assistant(assistant))
        pathsTracking.append(assistant)
    }

    public func appendNotificationSetting() {
        let notification = NotificationSettingsNavigationValue()
        paths.append(NavigationType.notificationSettings(notification))
        pathsTracking.append(notification)
    }

    public func appendAutomaticDownloads() {
        let downloads = AutomaticDownloadsNavigationValue()
        paths.append(NavigationType.automaticDownloadsSettings(downloads))
        pathsTracking.append(downloads)
    }

    public func appendMessageParticipantsSeen(_ message: Message) {
        let seen = MessageParticipantsSeenNavigationValue(message: message)
        paths.append(NavigationType.messageParticipantsSeen(seen))
        pathsTracking.append(seen)
    }

    public func appendSupport() {
        let support = SupportNavigationValue()
        paths.append(NavigationType.support(support))
        pathsTracking.append(support)
    }

    public func appendLog() {
        let log = LogNavigationValue()
        paths.append(NavigationType.log(log))
        pathsTracking.append(log)
    }

    public func appendArhives() {
        let archives = ArchivesNavigationValue()
        paths.append(NavigationType.archives(archives))
        pathsTracking.append(archives)
    }

    public func appendLanguage() {
        let language = LanguageNavigationValue()
        paths.append(NavigationType.language(language))
        pathsTracking.append(language)
    }

    public func append(participantDetail: Participant) {
        let detailViewModel = DetailViewModel(user: participantDetail)
        paths.append(NavigationType.detail(detailViewModel))
        pathsTracking.append(detailViewModel)
    }

    public func append(threadDetail: Conversation) {
        let detailViewModel = DetailViewModel(thread: threadDetail)
        detailViewModel.threadVM = pathsTracking
            .compactMap{$0 as? ThreadViewModel}
            .first(where: {$0.threadId == threadDetail.id})
        paths.append(NavigationType.detail(detailViewModel))
        pathsTracking.append(detailViewModel)
        selectedThreadId = threadDetail.id
    }

    public func append(thread: Conversation) {
        if !threadStack.contains(where: {$0.threadId == thread.id}) {
            let threadViewModel = ThreadViewModel(thread: thread, threadsViewModel: threadsViewModel)
            pathsTracking.append(threadViewModel)
        } else if let threadViewModel = threadViewModel(threadId: thread.id ?? 0) {
            pathsTracking.append(threadViewModel)
        }
        paths.append(NavigationType.conversation(thread))
        selectedThreadId = thread.id
    }

    public func threadViewModel(threadId: Int) -> ThreadViewModel? {
        /// We return last for when the user sends the first message inside a p2p thread after sending a message the thread object inside the ThreadViewModel will change to update the new id and other stuff.
        return threadStack.first(where: {$0.threadId == threadId}) ?? threadStack.last
    }

    var presentedThreadViewModel: ThreadViewModel? {
        threadStack.last
    }

    public func remove<T>(type: T.Type, threadId: Int? = nil) {
        if pathsTracking.count > 0 {
            pathsTracking.removeLast()
            if pathsTracking.count == 0, paths.count > 0 {
                paths.removeLast()
            }
        }
        setSelectedThreadId()
    }

    private func index(of conversationId: Int?) -> Array<Conversation>.Index? {
        pathsTracking.lastIndex(where: {($0 as? ThreadViewModel)?.threadId == conversationId})
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
