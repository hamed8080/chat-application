//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import FanapPodChatSDK
import SwiftUI

struct HomeContentView: View {
    @EnvironmentObject var tokenManager: TokenManager
    @Environment(\.localStatusBarStyle) var statusBarStyle
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if tokenManager.isLoggedIn == false {
            LoginView()
        } else {
            NavigationView {
                SideBar()

                SecondSideBar()

                DetailContentView()
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
