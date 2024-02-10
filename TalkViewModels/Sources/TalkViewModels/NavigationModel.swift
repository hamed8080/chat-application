import Chat
import SwiftUI
import TalkModels
import ChatModels
import ChatCore

public final class NavigationModel: ObservableObject {
    @Published public var selectedId: Int?
    @Published public var paths = NavigationPath()
    var pathsTracking: [Any] = []
    public init() {}

    public func append<T: NavigaitonValueProtocol>(type: NavigationType, value: T) {
        paths.append(type)
        pathsTracking.append(value)
    }

    public func popAllPaths() {
        if paths.count > 0 {
            for _ in 0...paths.count - 1 {
                popLastPath()
            }
        }
        pathsTracking.removeAll()
    }

    public func popPathTrackingAt(at index: Int) {
        pathsTracking.remove(at: index)
    }

    public func popLastPathTracking() {
        pathsTracking.removeLast()
    }

    public func popLastPath() {
        paths.removeLast()
    }

    public func remove<T>(type: T.Type) {
        if pathsTracking.count > 0 {
            popLastPathTracking()
            if pathsTracking.count == 0, paths.count > 0 {
                popLastPath()
            }
        }
    }
}

// Common methods and properties.
public extension NavigationModel {
    var previousItem: Any? {
        if pathsTracking.count > 1 {
            return pathsTracking[pathsTracking.count - 2]
        } else {
            return nil
        }
    }

    var previousTitle: String {
        if let thread = previousItem as? Conversation {
            return thread.computedTitle
        } else if let threadVM = previousItem as? ThreadViewModel {
            return threadVM.thread.computedTitle
        } else if let detail = previousItem as? ThreadDetailViewModel {
            return detail.thread?.title ?? ""
        } else if let detail = previousItem as? ParticipantDetailViewModel {
            return detail.participant.name ?? ""
        } else if let navTitle = previousItem as? NavigationTitle {
            return navTitle.title
        } else {
            return ""
        }
    }

    func clear() {
        animateObjectWillChange()
    }
}

// ThreadViewModel
public extension NavigationModel {
    private var threadsViewModel: ThreadsViewModel? { AppState.shared.objectsContainer.threadsVM }
    var threadStack: [ThreadViewModel] { pathsTracking.compactMap{ $0 as? ThreadViewModel } }

    func switchFromThreadList(thread: Conversation) {
        presentedThreadViewModel?.cancelAllObservers()
        popAllPaths()
        append(thread: thread)
    }

    func append(thread: Conversation) {
        let viewModel = viewModel(for: thread.id ?? 0) ?? createViewModel(conversation: thread)
        let value = ConversationNavigationValue(viewModel: viewModel)
        append(type: .threadViewModel(viewModel), value: value)
        selectedId = thread.id
    }

    private func createViewModel(conversation: Conversation) -> ThreadViewModel {
       return ThreadViewModel(thread: conversation, threadsViewModel: threadsViewModel)
    }

    var presentedThreadViewModel: ThreadViewModel? {
        threadStack.last
    }

    func viewModel(for threadId: Int) -> ThreadViewModel? {
        /// We return last for when the user sends the first message inside a p2p thread after sending a message the thread object inside the ThreadViewModel will change to update the new id and other stuff.
        return threadStack.first(where: {$0.threadId == threadId}) ?? threadStack.last
    }

    func setSelectedThreadId() {
        selectedId = threadStack.last?.threadId
    }

    func remove(threadId: Int? = nil) {
        remove(type: ThreadViewModel.self)
        if threadId != nil {
            presentedThreadViewModel?.cancelAllObservers()
        }
        if let threadId = threadId, (pathsTracking.last as? ThreadViewModel)?.threadId == threadId {
            popLastPathTracking()
            popLastPath()
        }
        setSelectedThreadId()
    }
}

// ThreadDetailViewModel
public extension NavigationModel {
    func appendThreadDetail(threadViewModel: ThreadViewModel? = nil, paricipant: Participant? = nil) {
        let detailViewModel = AppState.shared.objectsContainer.threadDetailVM
        if let participant = paricipant {
            detailViewModel.setup(participant: participant)
        } else {
            detailViewModel.setup(thread: threadViewModel?.thread, threadVM: threadViewModel)
        }
        paths.append(NavigationType.threadDetil(detailViewModel))
        pathsTracking.append(detailViewModel)
        selectedId = threadViewModel?.threadId
    }
}
