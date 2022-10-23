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
    var threadsVM: ThreadsViewModel

    @EnvironmentObject
    var contactsVM: ThreadsViewModel

    @EnvironmentObject
    var tokenManager: TokenManager
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle

    @Environment(\.colorScheme)
    var colorScheme

    @Environment(\.isPreview)
    var isPreview

    var body: some View {
        if tokenManager.isLoggedIn == false{
            LoginView()
        }else{
            NavigationView{
                SideBar()

                SecondSideBar()

                DetailContentView()
            }
            .onAppear{
                self.statusBarStyle.currentStyle = colorScheme == .dark ? .lightContent : .darkContent
                if isPreview{
                    threadsVM.setupPreview()
                    contactsVM.setupPreview()
                }
            }
        }
    }
}

struct SideBar:View{
    
    @EnvironmentObject
    var contactsVM:ContactsViewModel
    
    @EnvironmentObject
    var threadsVM:ThreadsViewModel
    
    @EnvironmentObject
    var settingsVM:SettingViewModel
    
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

            ForEach(threadsVM.tagViewModel.model.tags, id:\.id){ tag in
                NavigationLink {
                    ThreadContentList(folder:tag)
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
            
            NavigationLink {
                SettingsView(viewModel: settingsVM)
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
        HomeContentView()
            .environmentObject(appState)
            .onAppear(){
                AppState.shared.connectionStatus = .CONNECTED
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
            }
        
    }
}
