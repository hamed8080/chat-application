//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactContentList:View {
    
    @StateObject
    var viewModel :ContactsViewModel
    
    @EnvironmentObject
    var appState :AppState
    
    @State
    var searchedContact :String = ""
    
    @State
    var enableDeleteButton = false
    
    var body: some View{
        VStack(spacing:0){
            List{
                if viewModel.model.totalCount > 0 {
                    HStack(spacing:4){
                        Spacer()
                        Text("Total contacts:".uppercased())
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(viewModel.model.totalCount)")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .noSeparators()
                }
                
                MultilineTextField("Search contact ...",text: $searchedContact,backgroundColor:Color.gray.opacity(0.2)){submit in
                    hideKeyboard()
                    if searchedContact.isEmpty {
                        viewModel.searchContact(searchedContact)// to reset view
                    }
                }
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
                        SearchContactRow(contact: contact, viewModel: viewModel)
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
                        .customAnimation(.default)
                }
                .onDelete(perform:viewModel.delete)
                .padding(0)
            }
            .listStyle(.plain)
            NavigationLink(destination: AddOrEditContactView(), isActive: $viewModel.navigateToAddOrEditContact){
                EmptyView()
            }
        }
        .navigationTitle(Text("Contacts"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.navigateToAddOrEditContact.toggle()
                    } label: {
                        Label {
                            Text("Create new contacts")
                        } icon: {
                            Image(systemName: "person.badge.plus")
                        }
                    }
            }
            
            ToolbarItemGroup(placement: .navigationBarLeading) {
                
                Button {
                    viewModel.isInEditMode.toggle()
                } label: {
                    Label {
                        Text("Edit")
                    } icon: {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.body.bold())
                    }
                }
                
                Button {
                    viewModel.navigateToAddOrEditContact.toggle()
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                            .font(.body.bold())
                    }
                }
                .opacity(viewModel.isInEditMode ? 1 : 0.5)
                .disabled(!viewModel.isInEditMode)
            }
            ToolbarItem(placement: .principal) {
                if viewModel.connectionStatus != .CONNECTED{
                    Text("\(viewModel.connectionStatus.stringValue) ...")
                        .foregroundColor(Color(named: "text_color_blue"))
                        .font(.subheadline.bold())
                }
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
