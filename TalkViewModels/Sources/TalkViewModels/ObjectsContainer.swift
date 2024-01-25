import Combine
import SwiftUI
import Chat
import ChatCore
import ChatModels

public final class ObjectsContainer: ObservableObject {
    public private(set) var cancellableSet: Set<AnyCancellable> = []
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
    @Published public var appOverlayVM = AppOverlayViewModel()
    @Published public var searchVM = ThreadsSearchViewModel()
    @Published public var archivesVM = ArchiveThreadsViewModel()
    @Published public var reactions = ReactionViewModel.shared
    @Published public var errorVM = ErrorHandlerViewModel()

    /// As a result of a bug in the SwiftUI sheet where it can't release the memory, we have to keep a global object and rest its values to default to prevent memory leak unless we end up not receiving server messages.
    @Published public var conversationBuilderVM = ConversationBuilderViewModel()

    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
        NotificationCenter.message.publisher(for: .message)
            .compactMap { $0.object as? MessageEventTypes }
            .sink { [weak self] event in
                self?.onMessageEvent(event)
            }
            .store(in: &cancellableSet)
        AppState.shared.objectsContainer = self
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
        appOverlayVM.clear()
        reactions.clear()
        conversationBuilderVM.clear()
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
        let notificationSettings = AppSettingsModel.restore().notificationSettings
        if response.result?.conversation?.mute == true { return }
        guard notificationSettings.soundEnable,
              AppState.shared.user?.id != response.result?.ownerId,
              let conversation = response.result?.conversation
        else { return }
        if conversation.group == false, notificationSettings.privateChat.sound {
            playMessageSound(sent: false)
        } else if conversation.group == true, notificationSettings.group.sound {
            playMessageSound(sent: false)
        } else if conversation.type?.isChannelType == true, notificationSettings.channel.sound {
            playMessageSound(sent: false)
        }

        if notificationSettings.vibration {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func playMessageSound(sent: Bool) {
        if let fileURL = Bundle.main.url(forResource: sent ? "sent_message" : "new_message", withExtension: "mp3") {
            try? messagePlayer.setup(message: nil, fileURL: fileURL, ext: "mp3", category: .ambient)
            messagePlayer.toggle()
        }
    }
}
