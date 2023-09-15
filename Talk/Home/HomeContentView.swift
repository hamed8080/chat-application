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
    let container: ObjectsContainer
    @State private var isLoggedIn: Bool = false

    @ViewBuilder var body: some View {
        Group {
            if isLoggedIn {
                SplitViewContent(container: container)
            }
        }
        .animation(.easeInOut, value: isLoggedIn)
        .onReceive(TokenManager.shared.$isLoggedIn) { isLoggedIn in
            if self.isLoggedIn != isLoggedIn {
                self.isLoggedIn = isLoggedIn
            }
        }
    }
}

struct SplitViewContent: View {
    let container: ObjectsContainer
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @EnvironmentObject var navVM: NavigationModel
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ContainerSplitView(
            sidebarView:
                TabContainerView(
                    tabs: [
                        .init(
                            tabContent: ContactContentList(),
                            contextMenus: Button("Contact Context Menu") {},
                            title: "contacts",
                            iconName: "person.crop.circle"
                        ),
                        .init(
                            tabContent: ThreadContentList(container: container),
                            contextMenus: Button("Thread Context Menu") {},
                            title: "chats",
                            iconName: "ellipsis.message.fill"
                        ),
                        .init(
                            tabContent: SettingsView(container: container),
                            contextMenus: Button("Setting Context Menu") {},
                            title: "settings",
                            iconName: "gear"
                        )
                    ]
                ), container: container
        )
        .toast(
            isShowing: Binding(get: { AppState.shared.error != nil }, set: { _ in }),
            title: String(format: String(localized: "Errors.occuredTitle"), AppState.shared.error?.code ?? 0),
            message: AppState.shared.error?.message ?? "",
            titleFont: .title2,
            messageFont: .subheadline
        ) {
            Image(systemName: "xmark.square.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .onTapGesture {
                    withAnimation {
                        AppState.shared.error = nil
                    }
                }
        }
        .onReceive(container.$columnVisibility) { newValue in
            if newValue != columnVisibility {
                columnVisibility = newValue
            }
        }
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
