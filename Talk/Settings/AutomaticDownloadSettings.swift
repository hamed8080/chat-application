//
//  AutomaticDownloadSettings.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkModels

struct AutomaticDownloadSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "arrow.down.square.fill", title: "Settings.download", color: Color.App.color5, showDivider: false) {
            let value = AutomaticDownloadsNavigationValue()
            navModel.append(type: .automaticDownloadsSettings(value), value: value)
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.dividerPrimary)
    }
}

struct AutomaticDownloadSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Group {
                Toggle("Download.images".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.downloadImages)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
                Toggle("Download.files".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.downloadFiles)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.dividerPrimary)
            }
            .toggleStyle(MyToggleStyle())
            .listSectionSeparator(.hidden)

            Group {
                StickyHeaderSection(header: "", height: 10)
                    .listRowInsets(.zero)
                    .listRowSeparator(.hidden)

                NavigationLink {
                    PrivateDownloadSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.fill",
                                           title: "Notification.PrivateSettings",
                                           color: Color.App.color5)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.dividerPrimary)

                NavigationLink {
                    GroupDownloadSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.3.fill",
                                           title: "Notification.GroupSettings",
                                           color: Color.App.color2)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.dividerPrimary)

                NavigationLink {
                    ChannelDownloadSetting()
                } label: {
                    SectionNavigationLabel(imageName: "megaphone.fill",
                                           title: "Notification.ChannelSettings",
                                           color: Color.App.red)
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
        .normalToolbarView(title: "Settings.download", type: AutomaticDownloadsNavigationValue.self)
        .onChange(of: model) { _ in
            model.save()
        }
    }
}

struct PrivateDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.privateChat.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.downloadFiles)
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

struct GroupDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.group.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.group.downloadFiles)
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

struct ChannelDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.channel.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files".localized(bundle: Language.preferedBundle), isOn: $model.automaticDownloadSettings.channel.downloadFiles)
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

struct AutomaticDownloadSettings_Previews: PreviewProvider {
    static var previews: some View {
        AutomaticDownloadSettings()
    }
}
