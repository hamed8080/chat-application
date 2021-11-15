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
    
    @State var searchedContact :String = ""
    
    var body: some View{
        GeometryReader{ reader in
            List{
                MultilineTextField("Search contact ...",text: $searchedContact,backgroundColor:Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .noSeparators()
                    .onChange(of: searchedContact) { newValue in
                        viewModel.searchContact(searchedContact)
                    }
                
                if viewModel.model.showSearchedContacts{
                    Text("Searched contacts")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .noSeparators()
                    ForEach(viewModel.model.searchedContacts, id:\.self){ contact in
                        SearchContactRow(contact: contact)
                            .noSeparators()                        
                    }
                }
                
                ForEach(viewModel.model.contacts , id:\.id) { contact in
                    ContactRow(contact: contact , isInEditMode: $viewModel.isInEditMode , viewModel: viewModel)
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
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .global)
                    .onChanged({ value in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                    })
            )
            .padding(.init(top: 1, leading: 0, bottom: 1, trailing: 0))
            .listStyle(PlainListStyle())
            LoadingViewAtBottomOfView(isLoading:viewModel.isLoading ,reader:reader)
            NavigationLink(destination: AddOrEditContactView(), isActive: $viewModel.navigateToAddOrEditContact){
                EmptyView()
            }
        }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        
        ContactContentList(viewModel: vm)
        //            .previewDevice("iPhone 12 Pro Max")
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(AppState.shared)
    }
}
