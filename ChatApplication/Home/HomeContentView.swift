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
    var contactsViewModel:ContactsViewModel
    

    
    @State private var seletedTabTag = 2
    
    var body: some View {
        TabView(selection:$seletedTabTag){
            
            ContactContentList(viewModel: contactsViewModel)
                .tabItem {
                    Label("Contacts", systemImage: "person.fill")
                }.tag(1)

            ThreadContentList(viewModel: threadsViewModel)
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                }.tag(2)
            
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(3)
            
        }
    }
}



struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let threadsViewModel = ThreadsViewModel()
        let contactsViewModel = ContactsViewModel()
        HomeContentView(threadsViewModel:threadsViewModel,contactsViewModel:contactsViewModel)
            .onAppear(){
                threadsViewModel.setupPreview()
            }
    }
}
