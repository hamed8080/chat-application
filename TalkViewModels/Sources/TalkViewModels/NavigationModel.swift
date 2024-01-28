import Combine
import Chat
import SwiftUI
import TalkModels
import ChatModels
import ChatCore

public enum NavigationType: Hashable {
    case conversation(Conversation)
    case contact(Contact)
    case threadDetil(ThreadDetailViewModel)
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
    case editProfile(EditProfileNavigationValue)
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
public struct MessageParticipantsSeenNavigationValue: NavigaitonValueProtocol { 
    public let message: Message
    public let threadVM: ThreadViewModel
}
public struct EditProfileNavigationValue: NavigaitonValueProtocol {}

public final class NavigationModel: ObservableObject {
    @Published public var selectedThreadId: Conversation.ID?
    public var threadsViewModel: ThreadsViewModel?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
    private var threadStack: [ThreadViewModel] { pathsTracking.compactMap{ $0 as? ThreadViewModel} }
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        NotificationCenter.thread.publisher(for: .thread)
            .compactMap { $0.object as? ThreadEventTypes }
            .sink { [weak self] event in
                self?.onThreadEvents(event)
            }
            .store(in: &cancelable)

        NotificationCenter.participant.publisher(for: .participant)
            .compactMap { $0.object as? ParticipantEventTypes }
            .sink { [weak self] event in
                self?.onParticipantsEvents(event)
            }
            .store(in: &cancelable)
    }

    private func onThreadEvents(_ event: ThreadEventTypes) {
        switch event {
        case .created(let response):
            onCreated(response)
        case .deleted(let response):
            onDeleted(response)
        case .left(let response):
            onLeft(response)
        default:
            break
        }
    }

    private func onParticipantsEvents(_ event: ParticipantEventTypes) {
        switch event {
        case .add(let response):
            onAddParticipants(response)
        default:
            break
        }
    }

    private func onDeleted(_ response: ChatResponse<Participant>) {
        if let index = pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
            pathsTracking.remove(at: index)
        }
    }

    private func onLeft(_ response: ChatResponse<User>) {
        let deletedUserId = response.result?.id
        let myId = AppState.shared.user?.id
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.subjectId})
        let threadVM = threadStack.first(where: {$0.threadId == conversation?.id})
        let participant = threadVM?.participantsViewModel.participants.first(where: {$0.id == deletedUserId})

        if deletedUserId == myId {
            if let conversation = conversation {
                threadsVM.removeThread(conversation)
            }

            /// Remove the ThreadViewModel for cleaning the memory.
            if let index = pathsTracking.firstIndex(where: { ($0 as? ThreadViewModel)?.threadId == response.subjectId }) {
                pathsTracking.remove(at: index)
            }

            /// If I am in the detail view and press leave thread I should remove first DetailViewModel -> ThreadViewModel
            /// That is the reason why we call paths.removeLast() twice.
            if let index = pathsTracking.firstIndex(where: { ($0 as? ThreadDetailViewModel)?.thread?.id == response.subjectId }) {
                pathsTracking.remove(at: index)
                paths.removeLast()
                paths.removeLast()
            }
        } else {
            if let participant = participant {
                threadVM?.participantsViewModel.removeParticipant(participant)
            }
            conversation?.participantCount = (conversation?.participantCount ?? 0) - 1
            threadVM?.thread.participantCount = conversation?.participantCount
            threadVM?.animateObjectWillChange()
        }
    }

    func onAddParticipants(_ response: ChatResponse<Conversation>) {
        let addedParticipants = response.result?.participants ?? []
        let threadsVM = AppState.shared.objectsContainer.threadsVM
        let conversation = threadsVM.threads.first(where: {$0.id == response.result?.id})
        let threadVM = threadStack.first(where: {$0.threadId == conversation?.id})
        conversation?.participantCount = response.result?.participantCount ?? (conversation?.participantCount ?? 0) + addedParticipants.count
        threadVM?.participantsViewModel.onAdded(addedParticipants)
        threadVM?.animateObjectWillChange()
    }

    func onCreated(_ response: ChatResponse<Conversation>) {
        if let conversation = response.result, conversation.type == .selfThread {
            append(thread: conversation)
        }
    }

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

    public func appendMessageParticipantsSeen(_ message: Message, threadVM: ThreadViewModel) {
        let seen = MessageParticipantsSeenNavigationValue(message: message, threadVM: threadVM)
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

    public func appendEditProfile() {
        let editProfile = EditProfileNavigationValue()
        paths.append(NavigationType.editProfile(editProfile))
        pathsTracking.append(editProfile)
    }

    public func appendThreadDetail(threadViewModel: ThreadViewModel? = nil, paricipant: Participant? = nil) {
        let detailViewModel = AppState.shared.objectsContainer.threadDetailVM
        if let participant = paricipant {
            detailViewModel.setup(participant: participant)
        } else {
            detailViewModel.setup(thread: threadViewModel?.thread, threadVM: threadViewModel)
        }
        paths.append(NavigationType.threadDetil(detailViewModel))
        pathsTracking.append(detailViewModel)
        selectedThreadId = threadViewModel?.threadId
    }

    public func switchFromThreadList(thread: Conversation) {
        presentedThreadViewModel?.cancelAllObservers()
        if paths.count > 0 {
            for _ in 0...paths.count - 1 {
                paths.removeLast()
            }
        }
        pathsTracking.removeAll()
        let threadViewModel = ThreadViewModel(thread: thread, threadsViewModel: threadsViewModel)
        pathsTracking.append(threadViewModel)
        paths.append(NavigationType.conversation(thread))
        selectedThreadId = thread.id
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
        if threadId != nil {
            presentedThreadViewModel?.cancelAllObservers()
        }
        if pathsTracking.count > 0 {
            pathsTracking.removeLast()
            if pathsTracking.count == 0, paths.count > 0 {
                paths.removeLast()
            }
        }
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.threadId == threadId {
            pathsTracking.removeLast()
            paths.removeLast()
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
        } else if let detail = previousItem as? ThreadDetailViewModel {
            return detail.thread?.title ?? ""
        } else if let detail = previousItem as? ParticipantDetailViewModel {
            return detail.participant.name ?? ""
        } else if previousItem is LogNavigationValue {
            return "Logs.title"
        } else if previousItem is AssistantNavigationValue {
            return "Assistant.Assistants"
        } else {
            return ""
        }
    }
}
