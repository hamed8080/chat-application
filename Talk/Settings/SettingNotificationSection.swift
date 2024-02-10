//
//  SettingNotificationSection.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkUI
import TalkViewModels

struct SettingNotificationSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "bell.fill", title: "Settings.notifictionSettings", color: .red, showDivider: false) {
            let value = NotificationSettingsNavigationValue()
            navModel.append(type: .notificationSettings(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct NotificationSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Group {
                Toggle("Notification.Sound", isOn: $model.notificationSettings.soundEnable)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                if EnvironmentValues.isTalkTest {
                    Toggle("Notification.ShowDetails", isOn: $model.notificationSettings.showDetails)
                        .listRowBackground(Color.App.bgPrimary)
                        .listRowSeparatorTint(Color.App.dividerPrimary)
                }
                if EnvironmentValues.isTalkTest {
                    Toggle("Notification.Vibration", isOn: $model.notificationSettings.vibration)
                        .listRowBackground(Color.App.bgPrimary)
                        .listSectionSeparator(.hidden)
                }
            }
            .toggleStyle(MyToggleStyle())
            .listSectionSeparator(.hidden)

            if EnvironmentValues.isTalkTest {
                Group {
                    StickyHeaderSection(header: "", height: 10)
                        .listRowInsets(.zero)
                        .listRowSeparator(.hidden)

                    NavigationLink {
                        PrivateNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "person.fill",
                                               title: "Notification.PrivateSettings",
                                               color: Color.App.color5)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)

                    NavigationLink {
                        GroupNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "person.3.fill",
                                               title: "Notification.GroupSettings",
                                               color: Color.App.color2)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)

                    NavigationLink {
                        ChannelNotificationSetting()
                    } label: {
                        SectionNavigationLabel(imageName: "megaphone.fill",
                                               title: "Notification.ChannelSettings",
                                               color: Color.App.color3)
                    }
                    .listRowBackground(Color.App.bgPrimary)
                    .listSectionSeparator(.hidden)
                }
                .listRowSeparatorTint(Color.clear)
            }
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
                    AppState.shared.objectsContainer.navVM.remove(type: PreferenceNavigationValue.self)
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
        .toggleStyle(MyToggleStyle())
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
        .toggleStyle(MyToggleStyle())
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
        .toggleStyle(MyToggleStyle())
        .environment(\.defaultMinListRowHeight, 8)
        .listStyle(.plain)
        .background(Color.App.bgPrimary)
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct SettingNotificationSection_Previews: PreviewProvider {
    static var previews: some View {
        SettingNotificationSection()
    }
}
