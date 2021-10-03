//
//  StartThreadContactPickerView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI

struct StartThreadContactPickerView:View {
    
    @StateObject
    var viewModel:StartThreadContactPickerViewModel
    
    @StateObject
    var contactsVM = ContactsViewModel()
    
    @EnvironmentObject var appState:AppState
    
    @State var title    :String  = "New Message"
    @State var subtitle :String  = ""
    @State var isInGroupMode = false
    
    var body: some View{
        GeometryReader{ reader in
            PageWithNavigationBarView(title:$title, subtitle:$appState.connectionStatusString,trailingItems: getTrailingItems()){
                VStack(alignment:.leading,spacing: 0){
                  
                    
                    StartThreadButton(name: "person.2", title: "New Group", color: .blue){
                        isInGroupMode.toggle()
                    }
                    
                    StartThreadButton(name: "megaphone", title: "New Channel", color: .blue){
                        
                    }
                    
                    List {
                        ForEach(contactsVM.model.contacts , id:\.id) { contact in
                            
                            StartThreadContactRow(contact: contact, isInEditMode: $isInGroupMode, viewModel: contactsVM)
                                .onAppear {
                                    if contactsVM.model.contacts.last == contact{
                                        contactsVM.loadMore()
                                    }
                                }
                        }.onDelete(perform: { indexSet in
    //                        guard let thread = indexSet.map({ viewModel.model.threads[$0]}).first else {return}
    //                        viewModel.deleteThread(thread)
                        })
                    }
                    .listStyle(PlainListStyle())
                }
                .padding(0)
               
                
                Spacer()
                
                LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
                
                NavigationLink(destination: ThreadView(viewModel: ThreadViewModel()) ,isActive: $appState.showThread) {
                    EmptyView()
                }
            }
            .onAppear{
                appState.selectedThread = nil
            }
        }
    }
    
    func getTrailingItems()->[NavBarItem]{
        if isInGroupMode{
            return [NavBarButton(title: "Next" , isBold: true) {
                withAnimation {
                    
                }
            }.getNavBarItem()]
        }else{
            return []
        }
    }
}

struct StartThreadButton:View{
    
    var name:String
    var title:String
    var color:Color
    var action: (()->Void)?
    
    @State var isActive = false
    
    var body: some View{
        Button {
            action?()
        } label: {
            HStack{
                Image(systemName: name)
                Text(title)
                Spacer()
            }
        }
        .padding()
        .foregroundColor(.blue)
    }
}


struct StartThreadContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        let vm = StartThreadContactPickerViewModel()
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView(viewModel: vm,contactsVM: contactVM)
            .onAppear(){
                vm.setupPreview()
                contactVM.setupPreview()
            }
            .environmentObject(appState)
    }
}
