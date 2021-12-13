//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct HomeContentView: View {
    
    @StateObject
    var loginModel            = LoginViewModel()
    
    @StateObject
    var contactsViewModel     = ContactsViewModel()
    
    @StateObject
    var threadsViewModel      = ThreadsViewModel()
    
    @StateObject
    var tokenManager          = TokenManager.shared
    
    @EnvironmentObject
    var appState:AppState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @State
    var showThreadView:Bool = false
    
    var body: some View {
        if tokenManager.isLoggedIn == false{
            LoginView(viewModel:loginModel)
        }else{
            
            NavigationView{
                ZStack{
                    MasterView(contactsViewModel: contactsViewModel,
                               threadsViewModel: threadsViewModel)
                      
                    
                    ///do not remove this navigation to any view swift will give you unexpected behavior
                    NavigationLink(destination: ThreadView(viewModel: ThreadViewModel()) ,isActive: $showThreadView) {
                        EmptyView()
                    }
                }
            }
            .navigationViewStyle(.stack)//dont remove this line in ipad tabs will be hidden
            .onReceive(appState.$dark, perform: { _ in
                self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
            })
            .onReceive(appState.$selectedThread, perform: { selectedThread in
                self.showThreadView = selectedThread != nil
            })
            .onAppear{
                self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
            }
        }
    }
    
}

struct MasterView:View{
    
    @State
    var seletedTabTag = 2
    
    private var contactsView  : ContactContentList
    private var settingssView : SettingsView
    private var threadsView   : ThreadContentList
    
    
    init(contactsViewModel:ContactsViewModel,
         threadsViewModel:ThreadsViewModel){
        contactsView  = ContactContentList(viewModel: contactsViewModel)
        settingssView = SettingsView()
        threadsView   = ThreadContentList(viewModel: threadsViewModel)
    }
    
    var body: some View{
        TabView(selection: $seletedTabTag){
            
            contactsView
                .tabItem {
                    Label("Contacts", systemImage: "person.fill")
                }.tag(1)
            
            threadsView
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }.tag(2)
            
            settingssView
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(4)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        HomeContentView()
            .environmentObject(appState)
            .onAppear(){
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
            }
    }
}
