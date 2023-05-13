import Combine
import SwiftUI
import Chat

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
    public init(delegate: ChatDelegate) {
        loginVM = LoginViewModel(delegate: delegate)
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
}
