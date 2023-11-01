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
import Additive
import ChatCore

struct SettingsView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false
    
    var body: some View {
        List {
            Group {
                UserProfileView()
                    .listRowBackground(Color.App.bgPrimary)
            }
            .listRowSeparator(.hidden)

            UserInformationSection()
                .listRowSeparator(.hidden)

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)
                SettingSettingSection()
                SavedMessageSection()
                BlockedMessageSection()
                // SettingCallHistorySection()
                // SettingSavedMessagesSection()
                // SettingCallSection()
                SettingArchivesSection()
                SettingLanguageSection()
                SettingLogSection()
                if EnvironmentValues.isTalkTest {
                    SettingAssistantSection()
                }

                SettingNotificationSection()
                    .listRowSeparator(.hidden)
            }

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)

                SupportSection()
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(Color.App.bgPrimary.ignoresSafeArea())
        .environment(\.defaultMinListRowHeight, 8)
        .font(.iransansSubheadline)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 44)
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
            LoginNavigationContainerView {
                container.reset()
                showLoginSheet.toggle()
            }
        }
    }

    @ViewBuilder var leadingViews: some View {
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "qrcode", hint: "General.edit")
        }
    }

    var centerViews: some View {
        ConnectionStatusToolbar()
    }

    @ViewBuilder
    var trailingViews: some View {
        if EnvironmentValues.isTalkTest {
            ToolbarButtonItem(imageName: "plus.app", hint: "General.add") {
                withAnimation {
                    container.loginVM.resetState()
                    showLoginSheet.toggle()
                }
            }
        }

        ToolbarButtonItem(imageName: "magnifyingglass", hint: "General.search") {}
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "gearshape.fill", title: "Settings.title", color: .gray, showDivider: false) {
            navModel.appendPreference()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct UserInformationSection: View {
    @EnvironmentObject var navModel: NavigationModel
    @State var phone = ""
    @State var userName = ""
    @State var bio = ""

    var body: some View {
        if !userName.isEmpty || !phone.isEmpty || !bio.isEmpty {
            StickyHeaderSection(header: "", height: 10)
                .listRowInsets(.zero)
        }

        if !phone.isEmpty {
            VStack(alignment: .leading) {
                TextField("", text: $phone)
                    .foregroundColor(Color.App.text)
                    .font(.iransansSubheadline)
                    .disabled(true)
                Text("Settings.phoneNumber")
                    .foregroundColor(Color.App.hint)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.divider)
        }

        if !userName.isEmpty {
            VStack(alignment: .leading) {
                TextField("", text: $userName)
                    .foregroundColor(Color.App.text)
                    .font(.iransansSubheadline)
                    .disabled(true)
                Text("Settings.userName")
                    .foregroundColor(Color.App.hint)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.divider)
        }

        if !bio.isEmpty {
            VStack(alignment: .leading) {
                TextField("", text: $bio)
                    .foregroundColor(Color.App.text)
                    .font(.iransansSubheadline)
                    .disabled(true)
                Text("Settings.bio")
                    .foregroundColor(Color.App.hint)
                    .font(.iransansCaption)
            }
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.clear)
        }
        EmptyView()
            .frame(width: 0, height: 0)
            .listRowSeparator(.hidden)
            .onAppear {
                let user = AppState.shared.user
                phone = user?.cellphoneNumber ?? ""
                userName = user?.username ?? ""
                bio = user?.chatProfileVO?.bio ?? ""
            }
            .onReceive(NotificationCenter.default.publisher(for: .connect)) { notification in
                /// We use this to fetch the user profile image once the active instance is initialized.
                if let status = notification.object as? ChatState, status == .connected {
                    let user = AppState.shared.user
                    phone = user?.cellphoneNumber ?? ""
                    userName = user?.username ?? ""
                    bio = user?.chatProfileVO?.bio ?? ""
                }
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
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparator(.hidden)
        }
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .navigationTitle("Settings.title")
        .navigationBarBackButtonHidden(true)
        .onChange(of: model) { _ in
            model.save()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: PreferenceNavigationValue.self)
                }
            }
        }
    }
}

struct NotificationSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Group {
                Toggle("Notification.Sound", isOn: $model.notificationSettings.soundEnable)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.divider)
                Toggle("Notification.ShowDetails", isOn: $model.notificationSettings.showDetails)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.divider)
                Toggle("Notification.Vibration", isOn: $model.notificationSettings.vibration)
                    .listRowBackground(Color.App.bgPrimary)
                    .listSectionSeparator(.hidden)
            }
            .toggleStyle(.switch)
            .toggleStyle(MyToggleStyle())
            .listSectionSeparator(.hidden)

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)

                NavigationLink {
                    PrivateNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.fill",
                                           title: "Notification.PrivateSettings",
                                           color: Color.App.purple)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                NavigationLink {
                    GroupNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.3.fill",
                                           title: "Notification.GroupSettings",
                                           color: Color.App.green)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                NavigationLink {
                    ChannelNotificationSetting()
                } label: {
                    SectionNavigationLabel(imageName: "megaphone.fill",
                                           title: "Notification.ChannelSettings",
                                           color: Color.App.yellow)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
            }
            .listRowSeparatorTint(Color.clear)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .font(.iransansSubheadline)
        .background(Color.App.bgPrimary)
        .listStyle(.plain)
        .navigationTitle("Settings.notifictionSettings")
        .navigationBarBackButtonHidden(true)
        .onChange(of: model) { _ in
            model.save()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                NavigationBackButton {
                    AppState.shared.navViewModel?.remove(type: PreferenceNavigationValue.self)
                }
            }
        }
    }
}

struct PrivateNotificationSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Notification.Sound", isOn: $model.notificationSettings.privateChat.sound)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
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
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
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
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
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
        if EnvironmentValues.isTalkTest {
            ListSectionButton(imageName: "doc.text.fill", title: "Settings.logs", color: .brown, showDivider: false) {
                navModel.appendLog()
            }
            .listRowInsets(.zero)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(Color.App.divider)
        }
    }
}

struct SettingArchivesSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "archivebox.fill", title: "Tab.archives", color: Color.App.mint, showDivider: false) {
            navModel.appendArhives()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct SettingLanguageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "globe", title: "Settings.language", color: Color.App.indigo, showDivider: false) {
            navModel.appendLanguage()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct SavedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bookmark.fill", title: "Settings.savedMessage", color: Color.App.purple, showDivider: false) {
            ChatManager.activeInstance?.conversation.create(.init(title: String(localized: .init("Thread.selfThread")), type: .selfThread))
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct BlockedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.raised.slash", title: "General.blocked", color: Color.App.red, showDivider: false) {
            withAnimation {
                navModel.appendBlockedContacts()
            }
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct SettingNotificationSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bell.fill", title: "Settings.notifictionSettings", color: .red, showDivider: false) {
            navModel.appendNotificationSetting()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct SupportSection: View {
    @EnvironmentObject var tokenManagerVM: TokenManager
    @EnvironmentObject var navModel: NavigationModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.support", color: Color.App.green, showDivider: false) {
            navModel.appendSupport()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)

        ListSectionButton(imageName: "arrow.backward.circle", title: "Settings.logout", color: Color.App.red, showDivider: false) {
            ChatManager.activeInstance?.user.logOut()
            TokenManager.shared.clearToken()
            UserConfigManagerVM.instance.logout(delegate: ChatDelegateImplementation.sharedInstance)
            container.reset()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)

        if EnvironmentValues.isTalkTest {
            let secondToExpire = tokenManagerVM.secondToExpire.formatted(.number.precision(.fractionLength(0)))
            ListSectionButton(imageName: "key.fill", title: "Token expire in: \(secondToExpire)", color: Color.App.yellow, showDivider: false, shownavigationButton: false)
                .listRowInsets(.zero)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.clear)
                .onAppear {
                    tokenManagerVM.startTokenTimer()
                }
        }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "person.fill", title: "Settings.assistants", color: Color.App.blue, showDivider: false) {
            navModel.appendAssistant()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct UserProfileView: View {
    @EnvironmentObject var container: ObjectsContainer
    var userConfig: UserConfig? { container.userConfigsVM.currentUserConfig }
    var user: User? { userConfig?.user }
    @EnvironmentObject var viewModel: SettingViewModel
    @StateObject var imageLoader = ImageLoaderViewModel()

    var body: some View {
        HStack(spacing: 0) {
            ImageLaoderView(imageLoader: imageLoader, url: userConfig?.user.image, userName: userConfig?.user.name)
                .id("\(userConfig?.user.image ?? "")\(userConfig?.user.id ?? 0)")
                .frame(width: 64, height: 64)
                .cornerRadius(28)
                .padding(.trailing, 16)

            Text(verbatim: user?.name ?? "")
                .foregroundStyle(Color.App.text)
                .font(.iransansSubheadline)
            Spacer()

            Button {

            } label: {
                Rectangle()
                    .fill(.clear)
                    .frame(width: 48, height: 48)
                    .background(.ultraThickMaterial)
                    .cornerRadius(24)
                    .overlay(alignment: .center) {
                        Image("ic_edit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.App.hint)
                    }
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        .frame(height: 70)
        .onReceive(NotificationCenter.default.publisher(for: .user)) { notification in
            let event = notification.object as? UserEventTypes
            if !imageLoader.isImageReady, case let .user(response) = event, let user = response.result {
                imageLoader.fetch(url: user.image, userName: user.name, size: .LARG)
            }
        }
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
