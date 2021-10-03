//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactContentList:View {
    
    @StateObject var viewModel :ContactsViewModel
    
    @EnvironmentObject var appState :AppState
    
    @State var isInEditMode             = false
    
    @State var showAddContact           = false
    
    @State var title    :String  = "Contacts"
    
    var body: some View{
        GeometryReader{ reader in
            PageWithNavigationBarView(title:$title,
                                      subtitle:$appState.connectionStatusString,
                                      trailingItems: [getTrailingItem()],
                                      leadingItems: [getLeadingItem()]){
                List{
                    ForEach(viewModel.model.contacts , id:\.id) { contact in
                        ContactRow(contact: contact , isInEditMode: $isInEditMode , viewModel: viewModel)
                            .noSeparators()
                            .onAppear {
                                if viewModel.model.contacts.last == contact{
                                    viewModel.loadMore()
                                }
                            }
                            .animation(.default)
                    }
                    .onDelete(perform:viewModel.delete)
                    .padding(0)
                }
                .listStyle(PlainListStyle())
            }
            LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            NavigationLink(destination: AddOrEditContactView(), isActive: $showAddContact){
                EmptyView()
            }
        }
    }
    
    func getLeadingItem()-> NavBarItem{
        NavBarButton(title: "Edit") {
            isInEditMode.toggle()
        }
        .getNavBarItem()
    }
    
    func getTrailingItem()-> NavBarItem{
        if isInEditMode{
            return NavBarButton(title: "Delete") {
                viewModel.deleteSelectedItems()
            }.getNavBarItem()
        }else{
            return NavBarButton(systemImageName: "plus") {
                showAddContact.toggle()
            }.getNavBarItem()
        }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        
        ContactContentList(viewModel: vm)
            .previewDevice("iPhone 12 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(AppState.shared)
    }
}


//struct MyRow:View{
//
//    @State var isExpanded = false
//
//    var body: some View{
//        VStack{
//            VStack{
//                HStack{
//                    Image("avatar")
//                        .resizable()
//                        .frame(width: 64, height: 64)
//                    Text("Test Row with Long Title and really long Title ")
//                    Spacer()
//                }
//                if isExpanded{
//                    Button("Click on me"){
//
//                    }
//                    .foregroundColor(Color.blue)
//                }
//            }
//            .padding(16)
//            .background(Color.primary.opacity(0.08))
//            .cornerRadius(16)
//        }
//        .onTapGesture {
//            withAnimation {
//                isExpanded.toggle()
//            }
//        }
//    }
//}
//
//struct MyList_Previews: PreviewProvider {
//    static var previews: some View {
//
//        MyList()
//            .previewDevice("iPhone 12 Pro Max")
//            .environmentObject(AppState.shared)
//    }
//}
//
//struct MyList :View{
//
//    var body: some View{
//        List{
//            ForEach(1...5 , id:\.self){ content in
//                MyRow()
//            }
//        }
//        .animation(.default)
//        .listStyle(PlainListStyle())
//    }
//}
