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
import Additive

struct SettingsView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                UserProfileView()
                CustomSection {
                    SettingSettingSection()
                    SavedMessageSection()
                    // SettingCallHistorySection()
                    // SettingSavedMessagesSection()
                    // SettingCallSection()
                    SettingLogSection()
                    SettingAssistantSection()
                }

                CustomSection {
                    SettingNotificationSection()
                }

                CustomSection {
                    SupportSection()
                }

                CustomSection {
                    TokenExpireSection()
                }
            }
            .padding(16)
        }
        .font(.iransansSubheadline)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 48)
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

   @ViewBuilder var leadingViews: some View {
       #if DEBUG
       ToolbarButtonItem(imageName: "qrcode", hint: "General.edit")
       #endif
    }

    var centerViews: some View {
        ConnectionStatusToolbar()
    }

    var trailingViews: some View {
#if DEBUG
        ToolbarButtonItem(imageName: "plus.app", hint: "General.add") {
            withAnimation {
                container.loginVM.resetState()
                showLoginSheet.toggle()
            }
        }
#endif
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        SectionButton(imageName: "gearshape.fill", title: "Settings.title", color: .gray) {
            navModel.appendPreference()
        }
    }
}

struct PreferenceView: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Section("Tab.contacts") {
                VStack(alignment: .leading, spacing: 2) {
                    Toggle("Contacts.Sync.sync", isOn: $model.isSyncOn)
                    Text("Contacts.Sync.subtitle")
                        .foregroundColor(.gray)
                        .font(.iransansCaption3)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings.title")
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct NotificationSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Section {
                Toggle("Notification.Sound", isOn: $model.notificationSettings.soundEnable)
                Toggle("Notification.ShowDetails", isOn: $model.notificationSettings.showDetails)
                Toggle("Notification.Vibration", isOn: $model.notificationSettings.vibration)
            }
            .toggleStyle(.switch)
            .toggleStyle(MyToggleStyle())

            Section {
                NavigationLink {
                    PrivateNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.fill",
                                           title: "Notification.PrivateSettings",
                                           color: .purple)
                }

                NavigationLink {
                    GroupNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.3.fill",
                                           title: "Notification.GroupSettings",
                                           color: .green)
                }

                NavigationLink {
                    ChannelNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "megaphone.fill",
                                           title: "Notification.ChannelSettings",
                                           color: .yellow)
                }
            }
        }
        .font(.iransansSubheadline)
        .listStyle(.insetGrouped)
        .navigationTitle("Settings.notifictionSettings")
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct PrivateNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound", isOn: $model.notificationSettings.privateChat.sound)
        }
        .listStyle(.insetGrouped)
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct GroupNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound", isOn: $model.notificationSettings.group.sound)
        }
        .listStyle(.insetGrouped)
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct ChannelNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound", isOn: $model.notificationSettings.channel.sound)
        }
        .listStyle(.insetGrouped)
        .onChange(of: model) { _ in
            model.save()
        }
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
        #if DEBUG
        SectionButton(imageName: "doc.text.fill", title: "Settings.logs", color: .brown) {
            navModel.appendLog()
        }
        #endif
    }
}

struct SavedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        SectionButton(imageName: "bookmark.fill", title: "Thread.selfThread", color: .purple) {
            ChatManager.activeInstance?.conversation.create(.init(title: String(localized: .init("Thread.selfThread")), type: .selfThread))
        }
    }
}

struct SettingNotificationSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        SectionButton(imageName: "bell.fill", title: "Settings.notifictionSettings", color: .red, showDivider: false) {
            navModel.appendNotificationSetting()
        }
    }
}

struct SupportSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        SectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.support", color: .green, showDivider: false) {
            navModel.appendSupport()
        }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        SectionButton(imageName: "person.fill", title: "Settings.assistants", color: .blue, showDivider: false) {
            navModel.appendAssistant()
        }
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    var user: User? { container.userConfigsVM.currentUserConfig?.user }

    var body: some View {
        SwipyView(container: container)
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
        }
    }
}
struct MyToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isOn ? Color.gray.opacity(0.3) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            .padding([.top, .bottom], 16)
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
                .background(Color.main.opacity(0.3))
                .cornerRadius(12)
            }
        }
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
            swipyVM.updateForSelectedItem()
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
    @EnvironmentObject var viewModel: SettingViewModel

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: userConfig.user.image, userName: userConfig.user.name)
                .id("\(userConfig.user.image ?? "")\(userConfig.user.id ?? 0)")
                .frame(width: 48, height: 48)
                .cornerRadius(24)
                .padding()
                .overlay {
                    ZStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                    }
                    .frame(width: 48, height: 48)
                    .background(.blue)
                    .cornerRadius(24, corners: .allCorners)
                    .scaleEffect(x: viewModel.isEditing ? 1 : 0.001,
                                 y: viewModel.isEditing ? 1 : 0.001,
                                 anchor: .center)
                    .onTapGesture {
                        if viewModel.isEditing {
                            viewModel.showImagePicker.toggle()
                        }
                    }
                }

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
                }
            }
            Spacer()
            VStack {
                ToolbarButtonItem(imageName: "square.and.pencil", hint: "General.edit") {
                    viewModel.isEditing.toggle()
                }
                Text(Config.serverType(config: userConfig.config)?.rawValue ?? "")
                    .font(.iransansBody)
                    .foregroundColor(.green)
            }
            .padding(.trailing)
        }
        .animation(.spring(), value: viewModel.isEditing)
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image, assestResources in
                viewModel.showImagePicker.toggle()
                Task {
                    await viewModel.updateProfilePicture(image: image)
                }
            }
        }
    }
}

struct TokenExpireSection: View {
    @EnvironmentObject var viewModel: TokenManager
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        #if DEBUG
        let secondToExpire = viewModel.secondToExpire.formatted(.number.precision(.fractionLength(0)))
        SectionButton(imageName: "key.fill", title: "Token expire in: \(secondToExpire)", color: .yellow, showDivider: false, shownavigationButton: false)
            .onAppear {
                viewModel.startTokenTimer()
            }
        #endif
    }
}

struct MyButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.3) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CustomSection<Content>: View where Content: View {
    let header: String?
    let footer: String?
    let content: () -> (Content)

    init(header: String? = nil, footer: String? = nil, @ViewBuilder content: @escaping () -> (Content)) {
        self.header = header
        self.footer = footer
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            if let header {
                Text(header)
                    .font(.iransansCaption2)
            }

            content()

            if let footer {
                Text(footer)
                    .font(.iransansCaption2)
            }
        }
        .background(.ultraThickMaterial)
        .cornerRadius(12, corners: .allCorners)
    }
}

struct SectionNavigationLabel: View {
    @Environment(\.colorScheme) var scheme
    let imageName: String
    let title: String
    let color: Color

    init(imageName: String, title: String, color: Color) {
        self.imageName = imageName
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack {
            HStack {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white)
            }
            .padding(4)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(8, corners: .allCorners)

            Text(String(localized: .init(title)))
                .foregroundColor(scheme == .dark ? .white : .black)
        }
        .padding([.top, .bottom], 5)
    }
}

struct SectionButton: View {
    let imageName: String
    let title: String
    let color: Color
    let showDivider: Bool
    let shownavigationButton: Bool
    let action: (() -> ())?

    init(imageName: String, title: String, color: Color, showDivider: Bool = true, shownavigationButton: Bool = true, action: (() -> Void)? = nil) {
        self.imageName = imageName
        self.title = title
        self.color = color
        self.showDivider = showDivider
        self.action = action
        self.shownavigationButton = shownavigationButton
    }

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.white)
                    }
                    .padding(4)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .cornerRadius(8, corners: .allCorners)

                    Text(String(localized: .init(title)))
                    if shownavigationButton {
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
                if showDivider {
                    Rectangle()
                        .fill(.gray.opacity(0.35))
                        .frame(height: 0.5)
                        .padding([.leading])
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .contentShape(Rectangle())
            .padding([.leading, .trailing, .top], 12)
            .padding(.bottom, showDivider ? 0 : 8)
        }
        .buttonStyle(MyButtonStyle())
        .contentShape(Rectangle())
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
