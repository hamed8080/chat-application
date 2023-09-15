import Combine
import SwiftUI
import Chat
import ChatCore
import ChatModels

public final class ObjectsContainer: ObservableObject {
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    @Published public var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @Published public var userConfigsVM = UserConfigManagerVM.instance
    @Published public var navVM = NavigationModel()
    @Published public var loginVM: LoginViewModel
    @Published public var logVM = LogViewModel()
    @Published public var contactsVM = ContactsViewModel()
    @Published public var threadsVM = ThreadsViewModel()
    @Published public var tagsVM = TagsViewModel()
    @Published public var settingsVM = SettingViewModel()
    @Published public var tokenVM = TokenManager.shared
    @Published public var audioPlayerVM = AVAudioPlayerViewModel()
    @Published public var messagePlayer = AVAudioPlayerViewModel()
    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancellableSet)
    }

    public func reset() {
        threadsVM.clear()
        contactsVM.clear()
        tagsVM.clear()
        tagsVM.getTagList()
        navVM.clear()
        threadsVM.getThreads()
        contactsVM.getContacts()
        logVM.clearLogs()
    }

    private func onMessageEvent(_ event: MessageEventTypes) {
        switch event {
        case .new(let chatResponse):
            onNewMessage(chatResponse)
            break
        case .sent(_):
            playMessageSound(sent: true)
            break
        default:
            break
        }
    }

    private func onNewMessage(_ response: ChatResponse<Message>) {
        if AppState.shared.user?.id != response.result?.ownerId, threadsVM.threads.first(where: { $0.id == response.result?.conversation?.id })?.mute == false {
            playMessageSound(sent: false)
        }
    }

    private func playMessageSound(sent: Bool) {
        if let fileURL = Bundle.main.url(forResource: sent ? "sent_message" : "new_message", withExtension: "mp3") {
            messagePlayer.setup(fileURL: fileURL, ext: "mp3")
            messagePlayer.toggle()
        }
    }
}
