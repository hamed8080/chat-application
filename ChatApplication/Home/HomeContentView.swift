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
    var tokenManager = TokenManager.shared
    
    @StateObject
    var contactsViewModel:ContactsViewModel
    
    @StateObject
    var callsHistoryViewModel:CallsHistoryViewModel
    
    @EnvironmentObject
    var appState:AppState
    
    @EnvironmentObject
    var callState:CallState
    
    @Environment(\.localStatusBarStyle)
    var statusBarStyle          :LocalStatusBarStyle
    
    @State
    var seletedTabTag = 2
    
    var navigationBarTitle: String {
        Tabs(rawValue: seletedTabTag)?.stringValue ?? ""
    }
    
    var body: some View {
        //        WebRTCView()
//                WebRTCDirectSignalingView()
        //        WebRTCViewLocalSignalingView()
        
        if tokenManager.isLoggedIn == false{
            LoginView(viewModel:loginModel)
        }else{

            if callState.model.showCallView{
                CallControlsContent(viewModel: CallControlsViewModel())
                    .transition(.asymmetric(insertion: .scale.animation(.spring().speed(2)), removal: .move(edge: .trailing)))
            }else{
                NavigationView{
                    TabView(selection: $seletedTabTag){

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
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
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
                TokenManager.shared.setIsLoggedIn(isLoggedIn: true)
                threadsViewModel.setupPreview()
            }
    }
}

struct MyContentView_Previews: PreviewProvider {
    static var previews: some View {
        MyContentView()
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


struct MyContentView: View {
    @State private var tabSelection = 1
    
    var body: some View {
        NavigationView {
            TabView(selection: $tabSelection) {
                FirstView()
                    .tabItem {
                        Text("1")
                    }
                    .tag(1)
                SecondView()
                    .tabItem {
                        Text("2")
                    }
                    .tag(2)
            }
            .onAppear{             
                if #available(iOS 15.0, *) {
                    let appearance = UITabBarAppearance()
                    appearance.backgroundColor = .white
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
//            .tabViewStyle(TabViewStyle())
            // global, for all child views
            .navigationBarTitle(Text(navigationBarTitle), displayMode: .inline)
            //            .navigationBarHidden(navigationBarHidden)
                        .navigationBarItems(leading: navigationBarLeadingItems, trailing: navigationBarTrailingItems)
        }
    }
}


struct FirstView: View {
    var body: some View {
        NavigationLink(destination: Text("Some detail link")) {
            VStack{
                Text("Go to...")
                List(1...100,id:\.self){
                    Text("row:\($0)")
                }
            }
        }
    }
}

struct SecondView: View {
    var body: some View {
        Text("We are in the SecondView")
    }
}


private extension MyContentView {
    var navigationBarTitle: String {
        tabSelection == 1 ? "FirstView" : "SecondView"
    }
    
    var navigationBarHidden: Bool {
        tabSelection == 3
    }
    
    @ViewBuilder
    var navigationBarLeadingItems: some View {
        if tabSelection == 1 {
            Text("+")
        }
    }
    
    @ViewBuilder
    var navigationBarTrailingItems: some View {
        if tabSelection == 2 {
            Text("-")
        }
    }
}
