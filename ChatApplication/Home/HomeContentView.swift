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
import SwiftUI
import Swipy

struct HomeContentView: View {
    @StateObject var container = ObjectsContainer(delegate: ChatDelegateImplementation.sharedInstance)
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if container.tokenVM.isLoggedIn == false {
            LoginView()
                .environmentObject(container.loginVM)
                .environmentObject(container.tokenVM)
                .environmentObject(AppState.shared)
        } else {
            NavigationSplitView(columnVisibility: $container.columnVisibility) {
                SideBar()
            } content: {
                if container.navVM.isThreadType {
                    ThreadContentList()
                } else if container.navVM.selectedSideBarId == "Contacts" {
                    ContactContentList()
                } else if container.navVM.selectedSideBarId == "Settings" {
                    SettingsView()
                }
            } detail: {
                NavigationStack {
                    if let thread = container.navVM.selectedThread {
                        ThreadView(viewModel: ThreadViewModel(thread: thread, threadsViewModel: container.threadsVM))
                            .id(thread.id) // don't remove this from here it leads to never change in view
                    } else {
                        DetailContentView()
                    }
                }
            }
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

struct SideBar: View {
    @EnvironmentObject var container: ObjectsContainer
    @EnvironmentObject var userConfigsVM: UserConfigManagerVM
    @State var selectedUser: UserConfig.ID?
    @State var showLoginSheet = false
    let containerHeight: CGFloat = 72

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VSwipy(container.userConfigsVM.userConfigs, selection: $selectedUser) { item in
                    UserConfigView(userConfig: item)
                        .frame(height: containerHeight)
                        .background(Color.swipyBackground)
                        .cornerRadius(12)
                } onSwipe: { item in
                    DispatchQueue.main.async {
                        if item.user.id == container.userConfigsVM.currentUserConfig?.id { return }
                        ChatManager.activeInstance?.dispose()
                        container.userConfigsVM.switchToUser(item, delegate: ChatDelegateImplementation.sharedInstance)
                        container.reset()
                    }
                }
                .frame(height: containerHeight)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(12)
            }
            .padding()

            List(container.navVM.sections, selection: $container.navVM.selectedSideBarId) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        NavigationLink(value: item.id) {
                            Label(item.title, systemImage: item.icon)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Chat Application")
        .onAppear {
            selectedUser = UserConfigManagerVM.instance.currentUserConfig?.id
        }
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
                    Label("Add User", systemImage: "plus.app")
                }
            }
        }
        .onChange(of: container.tagsVM.tags) { tags in
            container.navVM.addTags(tags)
            container.objectWillChange.send()
        }
        .onReceive(userConfigsVM.$currentUserConfig) { newUserConfig in
            selectedUser = newUserConfig?.id
        }
    }
}

struct UserConfigView: View {
    let userConfig: UserConfig

    var body: some View {
        HStack {
            ImageLaoderView(url: userConfig.user.image, userName: userConfig.user.name)
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
    @EnvironmentObject var threadsVM: ThreadsViewModel

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
        HomeContentView(container: container)
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
