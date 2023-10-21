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

struct SettingsView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                UserProfileView()
                CustomListSection {
                    SettingSettingSection()
                    SavedMessageSection()
                    BlockedMessageSection()
                    // SettingCallHistorySection()
                    // SettingSavedMessagesSection()
                    // SettingCallSection()
                    SettingLogSection()
                    if EnvironmentValues.isTalkTest {
                        SettingAssistantSection()
                    }
                }

                CustomListSection {
                    SettingNotificationSection()
                }

                CustomListSection {
                    SupportSection()
                }

                CustomListSection {
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
    }
}

struct SettingSettingSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "gearshape.fill", title: "Settings.title", color: .gray) {
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
        if EnvironmentValues.isTalkTest {
            ListSectionButton(imageName: "doc.text.fill", title: "Settings.logs", color: .brown) {
                navModel.appendLog()
            }
        }
    }
}

struct SavedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bookmark.fill", title: "Settings.savedMessage", color: .purple) {
            ChatManager.activeInstance?.conversation.create(.init(title: String(localized: .init("Thread.selfThread")), type: .selfThread))
        }
    }
}
struct BlockedMessageSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "hand.raised.slash", title: "General.blocked", color: .redSoft) {
            withAnimation {
                navModel.appendBlockedContacts()
            }
        }
    }
}

struct SettingNotificationSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bell.fill", title: "Settings.notifictionSettings", color: .red, showDivider: false) {
            navModel.appendNotificationSetting()
        }
    }
}

struct SupportSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "exclamationmark.bubble.fill", title: "Settings.support", color: .green, showDivider: false) {
            navModel.appendSupport()
        }
    }
}

struct SettingAssistantSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "person.fill", title: "Settings.assistants", color: .blue, showDivider: false) {
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

struct TokenExpireSection: View {
    @EnvironmentObject var viewModel: TokenManager
    @EnvironmentObject var navModel: NavigationModel
    
    var body: some View {
        if EnvironmentValues.isTalkTest {
            let secondToExpire = viewModel.secondToExpire.formatted(.number.precision(.fractionLength(0)))
            ListSectionButton(imageName: "key.fill", title: "Token expire in: \(secondToExpire)", color: .yellow, showDivider: false, shownavigationButton: false)
                .onAppear {
                    viewModel.startTokenTimer()
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
