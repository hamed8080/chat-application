//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct HomeContentView: View {
    @StateObject var navModel = NavigationModel()
    @StateObject var loginModel = LoginViewModel()
    @StateObject var contactsVM = ContactsViewModel()
    @StateObject var threadsVM = ThreadsViewModel()
    @StateObject var settingsVM = SettingViewModel()
    @StateObject var tokenManager = TokenManager.shared
    @StateObject var appState = AppState.shared
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if tokenManager.isLoggedIn == false {
            LoginView()
                .environmentObject(loginModel)
                .environmentObject(tokenManager)
                .environmentObject(appState)
        } else {
            NavigationSplitView {
                SideBar()
            } content: {
                if navModel.isThreadType {
                    ThreadContentList()
                } else if navModel.selectedSideBarId == "contacts" {
                    ContactContentList()
                } else if navModel.selectedSideBarId == "settings" {
                    SettingsView()
                }
            } detail: {
                NavigationStack {
                    if let thread = navModel.selectedThread {
                        ThreadView(thread: thread)
                            .id(thread.id) // don't remove this from here it leads to never change in view
                    } else {
                        DetailContentView()
                    }
                }
            }
            .environmentObject(navModel)
            .environmentObject(settingsVM)
            .environmentObject(contactsVM)
            .environmentObject(threadsVM)
            .environmentObject(appState)
            .environmentObject(loginModel)
            .environmentObject(tokenManager)
            .onReceive(threadsVM.tagViewModel.$tags) { tags in
                navModel.addTags(tags)
            }
            .toast(
                isShowing: Binding(get: { appState.error != nil }, set: { _ in }),
                title: "Error happened with code: \(appState.error?.code ?? 0)",
                message: appState.error?.message ?? "",
                image: Image(systemName: "xmark.square.fill"),
                imageColor: .red.opacity(0.5)
            )
            .onAppear {
                appState.navViewModel = navModel
                navModel.threadViewModel = threadsVM
                threadsVM.title = "chats"
                navModel.contactsViewModel = contactsVM
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
            }
        }
    }
}

struct SideBar: View {
    @EnvironmentObject var navModel: NavigationModel
    var body: some View {
        List(navModel.sections, selection: $navModel.selectedSideBarId) { section in
            Section(section.title) {
                ForEach(section.items) { item in
                    NavigationLink(value: item.id) {
                        Label(item.title, systemImage: item.icon)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Chat Application")
        .listStyle(.insetGrouped)
    }
}

struct DetailContentView: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel

    var body: some View {
        VStack(spacing: 48) {
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 148)
                .opacity(0.2)
            VStack(spacing: 16) {
                Text("Nothing has been selected. You can start a conversation right now!")
                    .font(.body.bold())
                    .foregroundColor(Color.primary.opacity(0.8))
                Button {
                    threadsVM.toggleThreadContactPicker.toggle()
                } label: {
                    Text("Start")
                }
                .font(.body.bold())
            }
        }
        .padding([.leading, .trailing], 48)
        .padding([.bottom, .top], 96)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let threadsVM = ThreadsViewModel()
        HomeContentView()
            .environmentObject(threadsVM)
            .environmentObject(TokenManager.shared)
            .environmentObject(LoginViewModel())
            .onAppear {
                AppState.shared.connectionStatus = .connected
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
                threadsVM.appendThreads(threads: MockData.generateThreads(count: 10))
                threadsVM.objectWillChange.send()
            }
    }
}
