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
    @Published public var reactions = ReactionViewModel.shared

    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
        NotificationCenter.default.publisher(for: .message)
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
        guard notificationSettings.soundEnable,
              AppState.shared.user?.id != response.result?.ownerId,
              let conversation = threadsVM.threads.first(where: { $0.id == response.result?.conversation?.id })
        else { return }
        if conversation.group == false, notificationSettings.privateChat.sound {
            playMessageSound(sent: false)
        } else if conversation.group == true, notificationSettings.group.sound {
            playMessageSound(sent: false)
        } else if conversation.type == .channel || conversation.type == .channelGroup, notificationSettings.channel.sound {
            playMessageSound(sent: false)
        }

        if notificationSettings.vibration {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func playMessageSound(sent: Bool) {
        if let fileURL = Bundle.main.url(forResource: sent ? "sent_message" : "new_message", withExtension: "mp3") {
            messagePlayer.setup(message: nil, fileURL: fileURL, ext: "mp3")
            messagePlayer.toggle()
        }
    }
}
