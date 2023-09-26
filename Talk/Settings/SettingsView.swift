//
//  SettingsView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatModels
import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import Swipy

struct SettingsView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false
    
    var body: some View {
        List {
            UserProfileView()
            Group {
                SettingSettingSection()
//                SettingCallHistorySection()
//                SettingSavedMessagesSection()
                SettingLogSection()
                SettingAssistantSection()
//                SettingCallSection()
            }
            .font(.iransansSubheadline)
            .padding(8)
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 36)
        }
        .overlay(alignment: .top) {
            ToolbarView(
                title: "Tab.settings",
                leadingViews: leadingViews,
                centerViews: centerViews,
                trailingViews: trailingViews
            )
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                container.reset()
                showLoginSheet.toggle()
            }
        }
    }

    var leadingViews: some View {
        ToolbarButtonItem(imageName: "square.and.pencil", hint: "General.edit") {}
    }

    var centerViews: some View {
        ConnectionStatusToolbar()
    }

    var trailingViews: some View {
        ToolbarButtonItem(imageName: "plus.app", hint: "General.add") {
            withAnimation {
                container.loginVM.resetState()
                showLoginSheet.toggle()
            }
        }
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        Section {
            Button {
                navModel.paths.append(PreferenceNavigationValue())
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                    Text("Settings.title")
                }
            }
        }
    }
}

struct PreferenceView: View {
    @AppStorage("sync_contacts") var isSyncOn: Bool = false

    var body: some View {
        List {
            Section("Tab.contacts") {
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Contacts.Sync.sync", isOn: $isSyncOn)
                    Text("Contacts.Sync.subtitle")
                        .foregroundColor(.gray)
                        .font(.iransansCaption3)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct SettingCallHistorySection: View {
    var body: some View {
        Section {
            NavigationLink {} label: {
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.green)
                    Text("Settings.calls")
                }
            }
        }
    }
}

struct SettingSavedMessagesSection: View {
    var body: some View {
        NavigationLink {} label: {
            HStack {
                Image(systemName: "bookmark")
                    .foregroundColor(.purple)
                Text("Settings.savedMessage")
            }
        }
    }
}

struct SettingLogSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        Button {
            navModel.paths.append(LogNavigationValue())
        } label: {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.purple)
                Text("Settings.logs")
            }
        }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        Button {
            navModel.paths.append(AssistantNavigationValue())
        } label: {
            HStack {
                Image(systemName: "person.badge.shield.checkmark")
                    .foregroundColor(.purple)
                Text("Settings.assistants")
            }
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    var user: User? { container.userConfigsVM.currentUserConfig?.user }

    var body: some View {
        HStack {
            SwipyView(container: container)
        }
        .noSeparators()
    }
}

struct SettingCallSection: View {
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        Section(header: Text("Settings.manageCalls")) {
            Button {
                ChatManager.activeInstance?.user.logOut()
                TokenManager.shared.clearToken()
                UserConfigManagerVM.instance.logout(delegate: ChatDelegateImplementation.sharedInstance)
                container.reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.backward.circle")
                        .foregroundColor(.red)
                        .font(.body.weight(.bold))
                    Text("Settings.logout")
                        .fontWeight(.bold)
                        .foregroundColor(Color.red)
                    Spacer()
                }
            }
            TokenExpireView()
        }
    }
}

struct SwipyView: View {
    let container: ObjectsContainer
    private var userConfigsVM: UserConfigManagerVM { container.userConfigsVM }
    private let containerSize: CGFloat = 72
    @State private var selectedUser: UserConfig.ID?
    @State private var userConfigs: [UserConfig] = []
    @StateObject private var swipyVM: VSwipyViewModel<UserConfig> = .init([], itemSize: 72, containerSize: 72)

    var body: some View {
        HStack {
            if swipyVM.items.count > 0 {
                VSwipy(viewModel: swipyVM) { item in
                    UserConfigView(userConfig: item)
                        .frame(height: containerSize)
                        .background(Color.swipyBackground)
                        .cornerRadius(12)
                }
                .frame(height: containerSize)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(12)
            }
        }
        .padding()
        .onAppear {
            selectedUser = UserConfigManagerVM.instance.currentUserConfig?.id
            userConfigs = userConfigsVM.userConfigs
            setViewModel()
        }
        .onReceive(userConfigsVM.objectWillChange) { _ in
            if userConfigsVM.currentUserConfig?.id != selectedUser {
                selectedUser = userConfigsVM.currentUserConfig?.id
                container.reset()
                setViewModel()
            }

            if userConfigsVM.userConfigs.count != userConfigs.count {
                userConfigs = userConfigsVM.userConfigs
                setViewModel()
            }
        }
    }

    public func setViewModel() {
        if swipyVM.items.count == 0 {
            swipyVM.items = userConfigs
            swipyVM.containerSize = containerSize
            swipyVM.itemSize = containerSize
            swipyVM.selection = selectedUser
            swipyVM.onSwipe = onSwiped(item:)
            swipyVM.animateObjectWillChange()
        }
    }

    public func onSwiped(item: UserConfig) {
        if item.user.id == container.userConfigsVM.currentUserConfig?.id { return }
        ChatManager.activeInstance?.dispose()
        userConfigsVM.switchToUser(item, delegate: ChatDelegateImplementation.sharedInstance)
        container.reset()
    }
}

struct UserConfigView: View {
    let userConfig: UserConfig

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: userConfig.user.image, userName: userConfig.user.name)
                .id("\(userConfig.user.image ?? "")\(userConfig.user.id ?? 0)")
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .padding()
            VStack(alignment: .leading) {
                Text(userConfig.user.name ?? "")
                    .font(.iransansBoldSubtitle)
                    .foregroundColor(.primary)

                HStack {
                    Text(userConfig.user.cellphoneNumber ?? "")
                        .font(.iransansBody)
                        .fontDesign(.rounded)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Config.serverType(config: userConfig.config)?.rawValue ?? "")
                        .font(.iransansBody)
                        .foregroundColor(.green)
                }
            }
            Spacer()
        }
    }
}

struct TokenExpireView: View {
    @EnvironmentObject var viewModel: TokenManager

    var body: some View {
        #if DEBUG
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(Color.yellow)
                    .frame(width: 24, height: 24)
                let secondToExpire = viewModel.secondToExpire.formatted(.number.precision(.fractionLength(0)))
                Text("Token expire in: \(secondToExpire)")
                    .foregroundColor(Color.gray)
                Spacer()
            }
            .onAppear {
                viewModel.startTokenTimer()
            }
        #endif
    }
}

struct SettingsMenu_Previews: PreviewProvider {
    @State static var dark: Bool = false
    @State static var show: Bool = false
    @State static var showBlackView: Bool = false
    @StateObject static var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    static var vm = SettingViewModel()

    static var previews: some View {
        NavigationStack {
            SettingsView(container: container)
                .environmentObject(vm)
                .environmentObject(container)
                .environmentObject(TokenManager.shared)
                .environmentObject(AppState.shared)
                .onAppear {
                    let user = User(
                        cellphoneNumber: "+98 936 916 1601",
                        email: "h.hosseini.co@gmail.com",
                        image: "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
                        name: "Hamed Hosseini",
                        username: "hamed8080"
                    )
                    container.userConfigsVM.onUser(user)
                }
        }
    }
}
