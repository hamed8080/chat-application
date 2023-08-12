//
//  HomeContentView.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import Combine
import SwiftUI
import Swipy
import TalkModels
import TalkUI
import TalkViewModels

struct HomeContentView: View {
    let container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)

    var body: some View {
        LoginHomeView(container: container)
            .environmentObject(container.loginVM)
            .environmentObject(container.tokenVM)
            .environmentObject(AppState.shared)
        SplitView(container: container)
            .environmentObject(AppState.shared)
            .environmentObject(container)
            .environmentObject(container.navVM)
            .environmentObject(container.settingsVM)
            .environmentObject(container.contactsVM)
            .environmentObject(container.threadsVM)
            .environmentObject(container.loginVM)
            .environmentObject(container.tokenVM)
            .environmentObject(container.tagsVM)
            .environmentObject(container.userConfigsVM)
            .environmentObject(container.logVM)
            .environmentObject(container.audioPlayerVM)
            .environmentObject(container.reactions)
    }
}

struct LoginHomeView: View {
    let container: ObjectsContainer
    @EnvironmentObject var tokenManager: TokenManager

    var body: some View {
        if tokenManager.isLoggedIn == false {
            LoginView()
        }
    }
}

struct SplitView: View {
    @Environment(\.colorScheme) var colorScheme
    let container: ObjectsContainer
    @State private var isLoggedIn: Bool = false

    @ViewBuilder var body: some View {
        Group {
            if isLoggedIn {
                SplitViewContent(container: container)
            }
        }
        .background(colorScheme == .dark ? .black : .white)
        .animation(.easeInOut, value: isLoggedIn)
        .overlay {
            AppOverlayView(onDismiss: onDismiss) {
                AppOverlayFactory()
            }
            .environmentObject(container.appOverlayVM)
        }
        .onReceive(TokenManager.shared.$isLoggedIn) { isLoggedIn in
            if self.isLoggedIn != isLoggedIn {
                self.isLoggedIn = isLoggedIn
            }
        }
    }

    private func onDismiss() {
        container.appOverlayVM.clear()
    }
}

struct SplitViewContent: View {
    let container: ObjectsContainer
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @EnvironmentObject var navVM: NavigationModel

    var body: some View {
        ContainerSplitView(
            sidebarView:
                TabContainerView(
                    iPadMaxAllowedWidth: 400,
                    selectedId: "Tab.chats",
                    tabs: [
                        .init(
                            tabContent: ContactContentList(),
                            contextMenus: Button("Contact Context Menu") {},
                            title: "Tab.contacts",
                            iconName: "person.crop.circle"
                        ),
                        .init(
                            tabContent: ThreadContentList(container: container),
                            contextMenus: Button("Thread Context Menu") {},
                            title: "Tab.chats",
                            iconName: "ellipsis.message.fill"
                        ),
                        .init(
                            tabContent: SettingsView(container: container),
                            contextMenus: Button("Setting Context Menu") {},
                            title: "Tab.settings",
                            iconName: "gear"
                        )
                    ],
                    config: .init(alignment: .bottom)
                ), container: container
        )
        .background(Color.bgMain)
        .onAppear {
            AppState.shared.navViewModel = container.navVM
            container.navVM.threadViewModel = container.threadsVM
            container.threadsVM.title = "Tab.chats"
            self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
        }
    }
}

struct HomePreview: View {
    @State var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    var body: some View {
        HomeContentView()
            .onAppear {
                AppState.shared.connectionStatus = .connected
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
                container.threadsVM.appendThreads(threads: MockData.generateThreads(count: 10))
                container.animateObjectWillChange()
            }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomePreview()
    }
}
