//
//  AutomaticDownloadSettings.swift
//  Talk
//
//  Created by hamed on 11/14/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct AutomaticDownloadSection: View {
    @EnvironmentObject var navModel: NavigationModel

    var body: some View {
        ListSectionButton(imageName: "arrow.down.square.fill", title: "Settings.download", color: Color.App.purple, showDivider: false) {
            navModel.appendAutomaticDownloads()
        }
        .listRowInsets(.zero)
        .listRowBackground(Color.App.bgPrimary)
        .listRowSeparatorTint(Color.App.divider)
    }
}

struct AutomaticDownloadSettings: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Group {
                Toggle("Download.images", isOn: $model.automaticDownloadSettings.downloadImages)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.divider)
                Toggle("Download.files", isOn: $model.automaticDownloadSettings.downloadFiles)
                    .listRowBackground(Color.App.bgPrimary)
                    .listRowSeparatorTint(Color.App.divider)
            }
            .toggleStyle(.switch)
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
                                           color: Color.App.purple)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                NavigationLink {
                    GroupDownloadSetting()
                } label: {
                    SectionNavigationLabel(imageName: "person.3.fill",
                                           title: "Notification.GroupSettings",
                                           color: Color.App.green)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                NavigationLink {
                    ChannelDownloadSetting()
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
        .navigationTitle("Settings.download")
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

struct PrivateDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images", isOn: $model.automaticDownloadSettings.privateChat.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files", isOn: $model.automaticDownloadSettings.downloadFiles)
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

struct GroupDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images", isOn: $model.automaticDownloadSettings.group.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files", isOn: $model.automaticDownloadSettings.group.downloadFiles)
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

struct ChannelDownloadSetting: View {
    @State var model = AppSettingsModel.restore()

    var body: some View {
        List {
            Toggle("Download.images", isOn: $model.automaticDownloadSettings.channel.downloadImages)
                .listRowBackground(Color.App.bgPrimary)
                .listSectionSeparator(.hidden)

            Toggle("Download.files", isOn: $model.automaticDownloadSettings.channel.downloadFiles)
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

struct AutomaticDownloadSettings_Previews: PreviewProvider {
    static var previews: some View {
        AutomaticDownloadSettings()
    }
}
