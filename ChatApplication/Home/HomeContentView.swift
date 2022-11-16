//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct HomeContentView: View {

    @EnvironmentObject
    var tokenManager: TokenManager
    
    @EnvironmentObject
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle

    @Environment(\.colorScheme)
    var colorScheme

    @EnvironmentObject
    var appState: AppState
    
    @State
    var showCallView = false
    
    @State
    var shareCallLogs = false

    var body: some View {
        if tokenManager.isLoggedIn == false{
            LoginView()
        }else{
            NavigationView{

                SideBar()

                SecondSideBar()

                DetailContentView()
            }
            .fullScreenCover(isPresented: $showCallView, onDismiss: nil, content: {
                CallControlsContent()
            })
            .sheet(isPresented: $shareCallLogs, onDismiss: {
                if let zipFile =  appState.callLogs?.first{
                    FileManager.default.deleteFile(urlPathToZip: zipFile)
                }
            }, content:{
                if let zipUrl = appState.callLogs{
                    ActivityViewControllerWrapper(activityItems: zipUrl)
                }else{
                    EmptyView()
                }
            })
            .onReceive(appState.$callLogs , perform: { _ in
                withAnimation {
                    shareCallLogs = appState.callLogs != nil
                }
            })
            .onReceive(callState.$model , perform: { _ in
                withAnimation {
                    showCallView = callState.model.showCallView
                }
            })
            .onAppear{
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
            }
        }
    }
}

struct SideBar:View {
    
    var body: some View{
        
        List{
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

    @EnvironmentObject
    var threadsVM: ThreadsViewModel

    var body: some View {
        ForEach(threadsVM.tagViewModel.tags, id:\.id){ tag in
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

///this view only render once when view created to show list of threads after that all views are created by SideBar from list
struct SecondSideBar:View{

    var body: some View{
        ThreadContentList()
    }
}

struct DetailContentView:View{
    
    @EnvironmentObject
    var threadsVM:ThreadsViewModel
    
    var body: some View{
        VStack(spacing:48){
            Image(systemName: "doc.text.magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 148)
                .opacity(0.2)
            VStack(spacing:16){
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
        .padding([.leading,.trailing], 48)
        .padding([.bottom,.top], 96)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let callState = CallState.shared
        HomeContentView()
            .environmentObject(appState)
            .environmentObject(callState)
            .onAppear(){
                AppState.shared.connectionStatus = .CONNECTED
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
            }
        
    }
}
