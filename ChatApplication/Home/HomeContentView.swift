//
//  HomeContentView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

struct HomeContentView: View {
    
    @StateObject
    var threadsViewModel:ThreadsViewModel
    
    @StateObject
    var loginModel = LoginViewModel()
    
    @StateObject
    var contactsViewModel:ContactsViewModel
    
    @StateObject
    var callsHistoryViewModel:CallsHistoryViewModel
    
    @State
    private var seletedTabTag = 2
    
    @EnvironmentObject
    var appState:AppState
    
    @EnvironmentObject
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    var body: some View {
//        WebRTCView()
//        WebRTCDirectSignalingView()
        
        if TokenManager.shared.getSSOTokenFromUserDefaults() == nil && loginModel.model.state != .SUCCESS_LOGGED_IN {
            LoginView(viewModel:loginModel)
        }else{
            if callState.model.showCallView{
                CallControlsContent(viewModel: CallControlsViewModel())
                    .transition(.asymmetric(insertion: .scale.animation(.spring().speed(2)), removal: .move(edge: .trailing)))
            }else{
                TabView(selection:$seletedTabTag){

                    ContactContentList(viewModel: contactsViewModel)
                        .tabItem {
                            Label("Contacts", systemImage: "person.fill")
                        }.tag(1)

                    ThreadContentList(viewModel: threadsViewModel)
                        .tabItem {
                            Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                        }.tag(2)

                    CallsHistoryContentList(viewModel: callsHistoryViewModel)
                        .tabItem {
                            Label("Calls", systemImage: "phone")
                        }.tag(3)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }.tag(4)

                }
                .onReceive(appState.$dark, perform: { _ in
                    self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
                })
                .onAppear{
                    self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            }
        }
    }
}



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let threadsViewModel = ThreadsViewModel()
        let contactsViewModel = ContactsViewModel()
        let callsHistoryViewModel = CallsHistoryViewModel()
        let appState = AppState.shared
        let callState = CallState.shared
        HomeContentView(threadsViewModel:threadsViewModel,contactsViewModel:contactsViewModel,callsHistoryViewModel:callsHistoryViewModel)
            .environmentObject(appState)
            .environmentObject(callState)
            .onAppear(){
                threadsViewModel.setupPreview()
            }
    }
}
