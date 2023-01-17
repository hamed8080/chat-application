//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @State var modifyContactSheet = false
    @State var isInSelectionMode = false
    @State var deleteDialog = false

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
                ForEach(viewModel.searchedContacts) { contact in
                    SearchContactRow(contact: contact)
                        .noSeparators()
                }
            }

            ForEach(viewModel.contacts) { contact in
                ContactRow(isInSelectionMode: $isInSelectionMode, contact: contact)
                    .noSeparators()
                    .onAppear {
                        if viewModel.contacts.last == contact {
                            viewModel.loadMore()
                        }
                    }
                    .animation(.spring(), value: isInSelectionMode)
            }
            .onDelete(perform: viewModel.delete)
            .padding(0)
            ListLoadingView(isLoading: $viewModel.isLoading)
        }
        .sheet(isPresented: $modifyContactSheet) {
            AddOrEditContactView()
                .environmentObject(viewModel)
        }
        .searchable(text: $viewModel.searchContactString, placement: .navigationBarDrawer, prompt: "Search...")
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .navigationTitle(Text("Contacts"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    modifyContactSheet.toggle()
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
                    isInSelectionMode.toggle()
                } label: {
                    Label {
                        Text("Selection")
                    } icon: {
                        Image(systemName: "filemenu.and.selection")
                            .font(.body.bold())
                    }
                }

                Button {
                    deleteDialog.toggle()
                } label: {
                    Label {
                        Text("Delete")
                    } icon: {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                            .font(.body.bold())
                    }
                }
                .opacity(isInSelectionMode ? 1 : 0.5)
                .disabled(!isInSelectionMode)
            }
            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .dialog("Delete selected contacts", "Do you want to delete selected contacts?", "trash", $deleteDialog) { _ in
            viewModel.deleteSelectedItems()
        }
    }
}

struct ContactContentList_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ContactsViewModel()
        ContactContentList()
            .environmentObject(vm)
            .environmentObject(AppState.shared)
    }
}
