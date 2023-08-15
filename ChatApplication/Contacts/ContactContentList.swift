//
//  ContactContentList.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import ChatAppUI
import ChatAppViewModels
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
                    Text("Contacts.total")
                        .font(.iransansBody)
                        .foregroundColor(.gray)
                    Text(verbatim: "\(viewModel.maxContactsCountInServer)")
                        .font(.iransansBoldBody)
                    Spacer()
                }
                .noSeparators()
            }

            if viewModel.searchedContacts.count > 0 {
                Text("Contacts.searched")
                    .font(.iransansSubheadline)
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
        .searchable(text: $viewModel.searchContactString, placement: .navigationBarDrawer, prompt: "General.searchHere")
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .navigationTitle("Tab.contacts")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    modifyContactSheet.toggle()
                } label: {
                    Label("Contacts.createNew", systemImage: "person.badge.plus")
                }
            }

            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    isInSelectionMode.toggle()
                } label: {
                    Label("General.select", systemImage: "filemenu.and.selection")
                }

                NavigationLink {
                    BlockedContacts()
                } label: {
                    Label("General.blocked", systemImage: "hand.raised.slash")
                }

                Button {
                    deleteDialog.toggle()
                } label: {
                    Label("General.delete", systemImage: "trash")
                        .foregroundColor(Color.red)
                }
                .opacity(isInSelectionMode ? 1 : 0.5)
                .disabled(!isInSelectionMode)
            }
            ToolbarItem(placement: .principal) {
                ConnectionStatusToolbar()
            }
        }
        .dialog(.init(localized: .init("Contacts.deleteSelectedTitle")), .init(localized: .init("Contacts.deleteSelectedSubTitle")), "trash", $deleteDialog) { _ in
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
