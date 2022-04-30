//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct HomeContentView: View {
    
    @StateObject
    var loginModel     = LoginViewModel()
    
    @StateObject
    var contactsVM     = ContactsViewModel()
    
    @StateObject
    var threadsVM      = ThreadsViewModel()
    
    @StateObject
    var settingsVM     = SettingViewModel()
    
    @StateObject
    var tokenManager   = TokenManager.shared
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @Environment(\.colorScheme)
    var colorScheme
    
    @Environment(\.isPreview)
    var isPreview
    
    @State var appState = AppState.shared
    
    @State
    var showThreadView:Bool = false
    
    @State
    var selectedThread:Conversation? = nil
    
    var body: some View {
        if tokenManager.isLoggedIn == false{
            LoginView(viewModel:loginModel)
        }else{
            NavigationView{
                SideBar(contactsVM:contactsVM,threadsVM:threadsVM,settingsVM:settingsVM)
                    .environmentObject(appState)
                
                SecondSideBar(threadsVM:threadsVM)
                
                DetailContentView(threadsVM: threadsVM)
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
    
    @StateObject
    var contactsVM:ContactsViewModel
    
    @StateObject
    var threadsVM:ThreadsViewModel
    
    @StateObject
    var settingsVM:SettingViewModel
    
    var body: some View{
        
        List{
            NavigationLink {
                ContactContentList(viewModel: contactsVM)
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
                ThreadContentList(viewModel: threadsVM)
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
    
    @StateObject
    var threadsVM:ThreadsViewModel
    
    var body: some View{
        ThreadContentList(viewModel: threadsVM)
    }
}

struct DetailContentView:View{
    
    @StateObject
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
            .preferredColorScheme(.light)
            .previewDevice("iPad Pro (12.9-inch) (5th generation)")
            .environmentObject(appState)
            .onAppear(){
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
            }
            .previewInterfaceOrientation(.landscapeLeft)
        
    }
}
