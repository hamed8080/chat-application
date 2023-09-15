import Combine
import Chat
import SwiftUI
import TalkModels
import ChatModels

public final class NavigationModel: ObservableObject {
    @Published public var selectedThreadId: Conversation.ID?
    public var threadViewModel: ThreadsViewModel?
    @Published public var paths = NavigationPath()
    public var currentThreadVM: ThreadViewModel?
    var threadStack: [ThreadViewModel] = []
    public init() {}

    public func clear() {
        animateObjectWillChange()
    }

    public func append(participantDetail: Participant) {
        paths.append(DetailViewModel(user: participantDetail))
    }

    public func append(threadDetail: Conversation) {
        paths.append(DetailViewModel(thread: threadDetail))
        selectedThreadId = threadDetail.id
        setCurrentThreadViewModel()
    }

    public func append(thread: Conversation) {
        if !threadStack.contains(where: {$0.threadId == thread.id}) {
            threadStack.append(ThreadViewModel(thread: thread, threadsViewModel: threadViewModel))
        }
        paths.append(thread)
        selectedThreadId = thread.id
        setCurrentThreadViewModel()
    }

    func setCurrentThreadViewModel() {
        guard let thread = threadViewModel?.threads.first(where: { $0.id  == selectedThreadId }) else { return }
        currentThreadVM = ThreadViewModel(thread: thread)
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
