//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import SwiftUI
import FanapPodChatSDK

struct ContactContentList:View {
    
    @EnvironmentObject
    var viewModel :ContactsViewModel
    
    @State
    var isKeyboardShown:Bool = false
    
    var body: some View{
        ZStack{
            VStack(spacing:0){
                List{
                    if viewModel.model.maxContactsCountInServer > 0 {
                        HStack(spacing:4){
                            Spacer()
                            Text("Total contacts:".uppercased())
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(verbatim: "\(viewModel.model.maxContactsCountInServer)")
                                .fontWeight(.bold)
                            Spacer()
                        }
                        .noSeparators()
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
                        ContactRow(contact: contact , isInEditMode: $viewModel.isInEditMode)
                            .noSeparators()
                            .onAppear {
                                if viewModel.model.contacts.last == contact{
                                    viewModel.loadMore()
                                }
                            }
                            .animation(.spring(), value:viewModel.isInEditMode)
                    }
                    .onDelete(perform:viewModel.delete)
                    .padding(0)
                }
                .searchable(text: $viewModel.searchContactString, placement: .navigationBarDrawer, prompt: "Search...")
                .animation(.easeInOut, value: viewModel.model.contacts)
                .listStyle(.plain)
                NavigationLink(destination: AddOrEditContactView(), isActive: $viewModel.navigateToAddOrEditContact){
                    EmptyView()
                }
            }
            
            VStack{
                GeometryReader{ reader in
                    LoadingViewAt(isLoading:viewModel.isLoading, reader: reader)
                }
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
                ConnectionStatusToolbar()
            }
        }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        
        ContactContentList()
            .environmentObject(vm)
            .onAppear(){
                vm.setupPreview()
            }
            .environmentObject(AppState.shared)
    }
}
