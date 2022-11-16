//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct ContactContentList: View {
    @EnvironmentObject
    var viewModel: ContactsViewModel

    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
            if viewModel.maxContactsCountInServer > 0 {
                HStack(spacing: 4) {
                    Spacer()
                    Text("Total contacts:".uppercased())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(verbatim: "\(viewModel.maxContactsCountInServer)")
                        .fontWeight(.bold)
                    Spacer()
                }
                .noSeparators()
            }

            if viewModel.searchedContacts.count > 0 {
                Text("Searched contacts")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .noSeparators()
                ForEach(viewModel.searchedContacts, id: \.self) { contact in
                    SearchContactRow(contact: contact, viewModel: viewModel)
                        .noSeparators()
                }
            }

            ForEach(viewModel.contacts, id: \.id) { contact in
                ContactRow(contact: contact, isInEditMode: $viewModel.isInEditMode)
                    .noSeparators()
                    .onAppear {
                        if viewModel.contacts.last == contact {
                            viewModel.loadMore()
                        }
                    }
                    .animation(.spring(), value: viewModel.isInEditMode)
            }
            .onDelete(perform: viewModel.delete)
            .padding(0)
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .background(
            NavigationLink(destination: AddOrEditContactView().environmentObject(viewModel), isActive: $viewModel.navigateToAddOrEditContact) {
                EmptyView()
            }
                .frame(width: 0, height: 0)
                .hidden()
                .noSeparators()
        )
        .searchable(text: $viewModel.searchContactString, placement: .navigationBarDrawer, prompt: "Search...")
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
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
            .onAppear {
                vm.setupPreview()
            }
            .environmentObject(AppState.shared)
    }
}
