//
//  ContactContentList.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import SwiftUI
import TalkUI
import TalkViewModels
import ChatModels

struct ContactContentList: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    @EnvironmentObject var navVM: NavigationModel
    
    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
            if viewModel.maxContactsCountInServer > 0 {
                HStack(spacing: 4) {
                    Spacer()
                    Text("Contacts.total")
                        .font(.iransansBody)
                        .foregroundColor(.gray)
                    Text("\(viewModel.maxContactsCountInServer)")
                        .font(.iransansBoldBody)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .noSeparators()
            }
            
            SyncView()
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            if viewModel.searchedContacts.count == 0 {
                Button {
                    viewModel.showCreateGroup.toggle()
                } label: {
                    Label("Contacts.createGroup", systemImage: "person.2")
                        .foregroundStyle(Color.main)
                }
                .listRowBackground(Color.bgColor)
                .listRowSeparatorTint(Color.dividerDarkerColor)

                Button {

                } label: {
                    Label("Contacts.createChannel", systemImage: "megaphone")
                        .foregroundStyle(Color.main)
                }
                .listRowBackground(Color.bgColor)
                .listRowSeparatorTint(Color.dividerDarkerColor)

                Button {
                    viewModel.addContactSheet.toggle()
                } label: {
                    Label("Contacts.addContact", systemImage: "person.badge.plus")
                        .foregroundStyle(Color.main)
                }
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
            }
            
            if viewModel.searchedContacts.count > 0 {
                Section {
                    ForEach(viewModel.searchedContacts) { contact in
                        ContactRowContainer(contact: contact, isSearchRow: true)
                    }
                    .padding()
                } header: {
                    StickyHeaderSection(header: "Contacts.searched")
                }
                .listRowInsets(.zero)
            }
            
            Section {
                ForEach(viewModel.contacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: false)
                }
                .padding()
            } header: {
                StickyHeaderSection(header: "Contacts.sortLabel")
            }
            .listRowInsets(.zero)
            
            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.bgColor)
                .listRowSeparator(.hidden)
        }
        .sheet(isPresented: $viewModel.addContactSheet) {
            AddOrEditContactView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: Binding(get: { viewModel.editContact != nil }, set: { _ in })) {
            AddOrEditContactView(editContact: viewModel.editContact)
                .environmentObject(viewModel)
        }
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 44)
        }
        .overlay(alignment: .top) {
            ToolbarView(
                title: "Tab.contacts",
                searchPlaceholder: "General.searchHere",
                leadingViews: leadingViews,
                centerViews: centerViews,
                trailingViews: trailingViews
            ) { searchValue in
                viewModel.searchContactString = searchValue
            }
        }
        .dialog(.init(localized: .init("Contacts.deleteSelectedTitle")), .init(localized: .init("Contacts.deleteSelectedSubTitle")), "trash", $viewModel.deleteDialog) { _ in
            viewModel.deleteSelectedItems()
        }
        .sheet(isPresented: $viewModel.showCreateGroup) {
            CreateGroup()
        }
    }
    
    @ViewBuilder var leadingViews: some View {
        ToolbarButtonItem(imageName: "list.bullet", hint: "General.select") {
            withAnimation {
                viewModel.isInSelectionMode.toggle()
            }
        }
        
        ToolbarButtonItem(imageName: "trash.fill", hint: "General.delete") {
            withAnimation {
                viewModel.deleteDialog.toggle()
            }
        }
        .foregroundStyle(.red)
        .opacity(viewModel.isInSelectionMode ? 1 : 0.2)
        .disabled(!viewModel.isInSelectionMode)
        .scaleEffect(x: viewModel.isInSelectionMode ? 1.0 : 0.002, y: viewModel.isInSelectionMode ? 1.0 : 0.002)
    }
    
    @ViewBuilder var centerViews: some View {
        ConnectionStatusToolbar()
    }
    
    @ViewBuilder var trailingViews: some View {
        EmptyView()
    }
}

struct ContactRowContainer: View {
    @EnvironmentObject var viewModel: ContactsViewModel
    let contact: Contact
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
           return viewModel.contacts.last == contact ? Color.clear : Color.dividerDarkerColor
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.dividerDarkerColor
        }
    }

    var body: some View {
        ContactRow(isInSelectionMode: $viewModel.isInSelectionMode, contact: contact)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(contact.id ?? 0)")
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.bgColor)
            .listRowSeparatorTint(separatorColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button {
                    viewModel.editContact = contact
                } label: {
                    Label("General.edit", systemImage: "pencil")
                }
                .tint(.hint)

                Button {
                    viewModel.block(contact)
                } label: {
                    Label("General.block", systemImage: "hand.raised.slash")
                }
                .tint(Color.redSoft)

                Button {
                    if let index = viewModel.contacts.firstIndex(of: contact) {
                        viewModel.delete(indexSet: IndexSet(integer: index))
                    }
                } label: {
                    Label("General.delete", systemImage: "trash")
                }
                .tint(.red)
            }
            .onAppear {
                if viewModel.contacts.last == contact {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                AppState.shared.openThread(contact: contact)
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
