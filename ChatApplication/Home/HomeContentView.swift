//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatAppModels
import ChatAppUI
import ChatAppViewModels
import ChatModels
import Combine
import SwiftUI
import Swipy

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

    var body: some View {
        if TokenManager.shared.isLoggedIn == false {
            LoginView()
        }
    }
}

struct SplitView: View {
    let container: ObjectsContainer
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @EnvironmentObject var navVM: NavigationModel

    @ViewBuilder var body: some View {
        bodyView
    }

    @ViewBuilder var bodyView: some View {
        if TokenManager.shared.isLoggedIn {
            NavigationSplitView {
                SideBarView(container: container)
            } content: {
                SplitViewContentView()
            } detail: {
                NavigationStack(path: $navVM.paths) {
                    StackContentView()
                        .navigationDestination(for: Conversation.self) { thread in
                            ThreadView()
                                .id(thread.id)
                                .environmentObject(navVM.threadViewModel(threadId: thread.id ?? 0))
                        }
                        .navigationDestination(for: DetailViewModel.self) { viewModel in
                            DetailView()
                                .environmentObject(viewModel)
                                .environmentObject(container.threadsVM)
                                .environmentObject(container.navVM.currentThreadVM!)
                        }
                }
            }
            .toast(
                isShowing: Binding(get: { AppState.shared.error != nil }, set: { _ in }),
                title: "An error had happened with code: \(AppState.shared.error?.code ?? 0)",
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
                container.threadsVM.title = "Chats"
                container.navVM.contactsViewModel = container.contactsVM
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
            }
        }
    }
}

struct SplitViewContentView: View {
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        if container.navVM.isThreadType {
            ThreadContentList(container: container)
        } else if container.navVM.selectedSideBarId == "Contacts" {
            ContactContentList()
        } else if container.navVM.selectedSideBarId == "Settings" {
            SettingsView()
        }
    }
}

struct StackContentView: View {
    @EnvironmentObject var navVM: NavigationModel
    @EnvironmentObject var container: ObjectsContainer

    var body: some View {
        if let viewModel = navVM.currentThreadVM {
            ThreadView()
                .environmentObject(viewModel)
                .id(viewModel.thread.id) // don't remove this from here it leads to never change in view
        } else {
            DetailContentView(threadsVM: container.threadsVM)
        }
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

struct DetailContentView: View {
    let threadsVM: ThreadsViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .opacity(0.2)
            VStack(spacing: 16) {
                Text("Nothing has been selected. You can start a conversation right now!")
                    .font(.iransansSubheadline)
                    .foregroundColor(.secondaryLabel)
                Button {
                    threadsVM.sheetType = .startThread
                } label: {
                    Text("Start")
                        .font(.iransansBoldBody)
                }
            }
        }
        .padding([.leading, .trailing], 48)
        .padding([.bottom, .top], 96)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
                container.objectWillChange.send()
            }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomePreview()
    }
}
