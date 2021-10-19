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

    var body: some View {
        //        WebRTCView()
        //                WebRTCDirectSignalingView()
        //        WebRTCViewLocalSignalingView()
        
        if tokenManager.isLoggedIn == false{
            LoginView(viewModel:loginModel)
        }else{
            
            NavigationView{
                MasterView(callsHistoryViewModel:callsHistoryViewModel,
                           contactsViewModel: contactsViewModel,
                           threadsViewModel: threadsViewModel)
                
                    DetailView()
            }
//            .navigationViewStyle(StackNavigationViewStyle())
            .onReceive(appState.$dark, perform: { _ in
                self.statusBarStyle.currentStyle = appState.dark ? .lightContent : .darkContent
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
                shareCallLogs = appState.callLogs != nil
            })
            .onReceive(callState.$model , perform: { _ in
                showCallView = callState.model.showCallView
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
        .toolbar{
            ToolbarItemGroup(placement:.navigationBarTrailing){
                if seletedTabTag == Tabs.CONTACTS.rawValue{
                    let plus = NavBarButton(systemImageName: "plus", action: {
                        contactsView.viewModel.navigateToAddOrEditContact.toggle()
                    })
                    plus.getNavBarItem().view
                }
                
                if seletedTabTag == Tabs.CHATS.rawValue{
                    NavBarButton(systemImageName: "square.and.pencil") {
                        withAnimation {
                            threadsView.viewModel.toggleThreadContactPicker.toggle()
                        }
                    }.getNavBarItem().view
                }
            }

            ToolbarItemGroup(placement:.navigationBarLeading){
                if seletedTabTag == Tabs.CONTACTS.rawValue{
                    let edit = NavBarButton(title: "Edit", action: {
                        contactsView.viewModel.isInEditMode.toggle()
                        seletedTabTag = seletedTabTag//to refresh this view and cause to trigger and show and hide delete button
                        showDeleteButton.toggle()
                    })
                    edit.getNavBarItem().view
                    
                    if showDeleteButton,contactsView.viewModel.isInEditMode{
                        NavBarButton(title: "Delete") {
                            contactsView.viewModel.deleteSelectedItems()
                        }.getNavBarItem().view
                    }
                }
            }
            
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(Tabs(rawValue: seletedTabTag)?.stringValue ?? "")
                        .fixedSize()
                        .font(.headline)
                    Text(appState.connectionStatusString)
                        .fixedSize()
                        .font(.caption)
                }
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailView:View{
    
    var body: some View{
        Text("salam")
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

enum Tabs:Int{
    case CONTACTS = 1
    case CHATS    = 2
    case CALLS    = 3
    case SETTINGS = 4
    
    var stringValue:String{
        switch self {
        case .CONTACTS : return "Contacts"
        case .CHATS    : return "Chats"
        case .CALLS    : return "Calls"
        case .SETTINGS : return "Settings"
        }
    }
}
