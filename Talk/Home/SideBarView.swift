//
//  SideBarView.swift
//  Talk
//
//  Created by hamed on 7/17/23.
//

import Chat
import SwiftUI
import Swipy
import TalkModels
import TalkViewModels

struct SideBarView: View {
    let container: ObjectsContainer
    @State private var showLoginSheet = false

    var body: some View {
        VStack(spacing: 0) {
            SwipyView(container: container)
            SideBarSectionsView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("General.appName")
        .sheet(isPresented: $showLoginSheet) {
            LoginView {
                container.reset()
                showLoginSheet.toggle()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    container.loginVM.resetState()
                    showLoginSheet.toggle()
                } label: {
                    Label("General.add", systemImage: "plus.app")
                }
            }
        }
    }
}

struct SwipyView: View {
    let container: ObjectsContainer
    private var userConfigsVM: UserConfigManagerVM { container.userConfigsVM }
    private let containerHeight: CGFloat = 72
    @State private var selectedUser: UserConfig.ID?
    @State private var userConfigs: [UserConfig] = []

    var body: some View {
        HStack {
            VSwipy(userConfigs, selection: $selectedUser) { item in
                UserConfigView(userConfig: item)
                    .frame(height: containerHeight)
                    .background(Color.swipyBackground)
                    .cornerRadius(12)
            } onSwipe: { item in
                DispatchQueue.main.async {
                    if item.user.id == container.userConfigsVM.currentUserConfig?.id { return }
                    ChatManager.activeInstance?.dispose()
                    userConfigsVM.switchToUser(item, delegate: ChatDelegateImplementation.sharedInstance)
                    container.reset()
                }
            }
            .frame(height: containerHeight)
            .background(Color.orange.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .onAppear {
            selectedUser = UserConfigManagerVM.instance.currentUserConfig?.id
        }
        .onReceive(userConfigsVM.objectWillChange) { _ in
            if userConfigsVM.currentUserConfig?.id != selectedUser {
                selectedUser = userConfigsVM.currentUserConfig?.id
            }

            if userConfigsVM.userConfigs.count != userConfigs.count {
                userConfigs = userConfigsVM.userConfigs
            }
        }
    }
}

struct SideBarSectionsView: View {
    @EnvironmentObject var container: ObjectsContainer
    @State private var sections: [TalkModels.Section] = []
    @State var selectedSideBarId: String? = "Tab.chats"

    var body: some View {
        List(sections, selection: $container.navVM.selectedSideBarId) { section in
            Section(String(localized: .init(section.title))) {
                ForEach(section.items) { item in
                    NavigationLink(value: item.id) {
                        Label(String(localized: .init(item.title)), systemImage: item.icon)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .onReceive(container.tagsVM.objectWillChange) { _ in
            container.navVM.addTags(container.tagsVM.tags)
        }
        .onReceive(container.navVM.objectWillChange) { _ in
            if sections != container.navVM.sections {
                sections = container.navVM.sections
            }
        }
        .onReceive(container.navVM.$selectedSideBarId) { newValue in
            if selectedSideBarId != newValue {
                selectedSideBarId = newValue
            }
        }
    }
}

struct SideBarView_Previews: PreviewProvider {
    static var previews: some View {
        SideBarView(container: ObjectsContainer(delegate: ChatDelegateImplementation()))
    }
}
