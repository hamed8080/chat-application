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
    var callsHistoryViewModel = CallsHistoryViewModel()
    
    @StateObject
    var contactsViewModel     = ContactsViewModel()
    
    @StateObject
    var threadsViewModel      = ThreadsViewModel()
    
    @StateObject
    var tokenManager          = TokenManager.shared
    
    @EnvironmentObject
    var appState:AppState
    
    @EnvironmentObject
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @State
    var showCallView = false
    
    @State
    var shareCallLogs = false
    
    @State
    var showThreadView:Bool = false
    
    
    var body: some View {
        //        WebRTCView()
        //                WebRTCDirectSignalingView()
        //        WebRTCViewLocalSignalingView()
//      TestAsyncRefactor()
        if tokenManager.isLoggedIn == false{
            LoginView(viewModel:loginModel)
        }else{

            NavigationView{
                ZStack{
                    MasterView(callsHistoryViewModel:callsHistoryViewModel,
                               contactsViewModel: contactsViewModel,
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
            .fullScreenCover(isPresented: $showCallView, onDismiss: nil, content: {
                CallControlsContent(viewModel: CallControlsViewModel())
                    .environmentObject(callState)
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
                self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
            }
        }
    }
    
}

struct MasterView:View{
    
    @EnvironmentObject
    var appState:AppState
    
    @State
    var seletedTabTag = 2
    
    
    @State var showDeleteButton = false
    
    private var callView      : CallsHistoryContentList
    private var contactsView  : ContactContentList
    private var settingssView : SettingsView
    private var threadsView   : ThreadContentList
    
    
    init(callsHistoryViewModel:CallsHistoryViewModel,
         contactsViewModel:ContactsViewModel,
         threadsViewModel:ThreadsViewModel){
        callView      = CallsHistoryContentList(viewModel: callsHistoryViewModel)
        contactsView  = ContactContentList(viewModel: contactsViewModel)
        settingssView = SettingsView()
        threadsView   = ThreadContentList(viewModel: threadsViewModel)
    }
    
    var body: some View{
        TabView(selection: $seletedTabTag){
            
            callView
                .tabItem {
                    Label("Calls", systemImage: "phone")
                }.tag(3)
            
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
        let callState = CallState.shared
        HomeContentView()
            .environmentObject(appState)
            .environmentObject(callState)
            .onAppear(){
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
            }
    }
}
