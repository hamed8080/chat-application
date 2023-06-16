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
    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
        NotificationCenter.default.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .compactMap { event -> ChatResponse<Message>? in
                if case let .new(response) = event { return response } else { return nil }
            }
            .filter{ AppState.shared.user?.id != $0.result?.ownerId }
            .sink { newMessage in
                let isMute = self.threadsVM.threads.first(where: { $0.id == newMessage.result?.conversation?.id })?.mute
                if isMute == false {
                    self.playNewMessageSound()
                }
            }
            .store(in: &cancellableSet)
    }

    public func reset() {
        threadsVM.clear()
        contactsVM.clear()
        tagsVM.clear()
        tagsVM.getTagList()
        navVM.clear()
        navVM.setup()
        threadsVM.getThreads()
        contactsVM.getContacts()
        logVM.clearLogs()
    }

    private func playNewMessageSound() {
        if let fileURL = Bundle.main.url(forResource: "new_message", withExtension: "mp3") {
            audioPlayerVM.setup(fileURL: fileURL, ext: "mp3")
            audioPlayerVM.toggle()
        }
    }
}
