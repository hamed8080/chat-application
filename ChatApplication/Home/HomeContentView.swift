//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct HomeContentView: View {
    @StateObject var loginModel = LoginViewModel()
    @StateObject var contactsVM = ContactsViewModel()
    @StateObject var threadsVM = ThreadsViewModel()
    @StateObject var settingsVM = SettingViewModel()
    @StateObject var tokenManager = TokenManager.shared
    @StateObject var appState = AppState.shared
    @StateObject var callsHistoryVM = CallsHistoryViewModel()
    @StateObject var callViewModel = CallViewModel.shared
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @Environment(\.colorScheme) var colorScheme
    @State var showCallView = false
    @State var shareCallLogs = false

    var body: some View {
        if tokenManager.isLoggedIn == false {
            LoginView()
                .environmentObject(loginModel)
                .environmentObject(tokenManager)
                .environmentObject(appState)
        } else {
            NavigationView {
                SideBar()

                SecondSideBar()

                DetailContentView()
            }
            .environmentObject(settingsVM)
            .environmentObject(contactsVM)
            .environmentObject(threadsVM)
            .environmentObject(appState)
            .environmentObject(loginModel)
            .environmentObject(tokenManager)
            .environmentObject(callViewModel)
            .environmentObject(callsHistoryVM)
            .fullScreenCover(isPresented: $showCallView, onDismiss: nil) {
                CallView()
                    .environmentObject(appState)
                    .environmentObject(callViewModel)
                    .environmentObject(RecordingViewModel(callId: CallViewModel.shared.callId))
            }
            .sheet(isPresented: $shareCallLogs, onDismiss: {
                if let zipFile = appState.callLogs?.first {
                    FileManager.default.deleteFile(urlPathToZip: zipFile)
                }
            }, content: {
                if let zipUrl = appState.callLogs {
                    ActivityViewControllerWrapper(activityItems: zipUrl)
                } else {
                    EmptyView()
                }
            })
            .onReceive(appState.$callLogs) { _ in
                withAnimation {
                    shareCallLogs = appState.callLogs != nil
                }
            }
            .animation(.easeInOut, value: showCallView)
            .onReceive(CallViewModel.shared.$showCallView) { newShowCallView in
                if showCallView != newShowCallView {
                    showCallView = newShowCallView
                }
            }
            .onAppear {
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
            }
        }
    }
}

struct SideBar: View {
    var body: some View {
        List {
            NavigationLink {
                ContactContentList()
            } label: {
                Label {
                    Text("Contacts")
                } icon: {
                    Image(systemName: "person.icloud")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }

            NavigationLink {
                ThreadContentList()
            } label: {
                Label {
                    Text("Chats")
                } icon: {
                    Image(systemName: "captions.bubble")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }

            NavigationLink {
                CallsHistoryContentList()
            } label: {
                Label {
                    Text("Calls")
                } icon: {
                    Image(systemName: "phone")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }

            NavigationLink {
                ThreadContentList()
                    .environmentObject(ThreadsViewModel(archived: true))
            } label: {
                Label {
                    Text("Archive")
                } icon: {
                    Image(systemName: "tray.and.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }

            TagContentList()

            NavigationLink {
                SettingsView()
            } label: {
                Label {
                    Text("Setting")
                } icon: {
                    Image(systemName: "gear")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }
        }
        .listStyle(.plain)
    }
}

/// Separate this view to prevent redraw view in the sidebar and consequently redraw the whole applicaiton
/// view multiple times and reinit the view models multiple times.
struct TagContentList: View {
    @EnvironmentObject var threadsVM: ThreadsViewModel

    var body: some View {
        ForEach(threadsVM.tagViewModel.tags) { tag in
            NavigationLink {
                ThreadContentList(folder: tag)
            } label: {
                Label {
                    Text(tag.name)
                } icon: {
                    Image(systemName: "folder")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.blue)
                }
            }
        }
    }
}

/// This view only render once when view created to show list of threads after that all views are created by SideBar from list
struct SecondSideBar: View {
    var body: some View {
        ThreadContentList()
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
        let appState = AppState.shared
        let callState = CallViewModel.shared
        let threadsVM = ThreadsViewModel()
        HomeContentView()
            .environmentObject(appState)
            .environmentObject(callState)
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
