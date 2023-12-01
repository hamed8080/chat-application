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
                .id(-1)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
            if viewModel.maxContactsCountInServer > 0, EnvironmentValues.isTalkTest {
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

            if EnvironmentValues.isTalkTest {
                SyncView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if viewModel.searchedContacts.count == 0 {
                Button {
                    viewModel.createConversationType = .normal
                    viewModel.showConversaitonBuilder.toggle()
                } label: {
                    Label("Contacts.createGroup", systemImage: "person.2")
                        .foregroundStyle(Color.App.primary)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                Button {
                    viewModel.createConversationType = .channel
                    viewModel.showConversaitonBuilder.toggle()
                } label: {
                    Label("Contacts.createChannel", systemImage: "megaphone")
                        .foregroundStyle(Color.App.primary)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                Button {
                    viewModel.showAddOrEditContactSheet.toggle()
                } label: {
                    Label("Contacts.addContact", systemImage: "person.badge.plus")
                        .foregroundStyle(Color.App.primary)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
            }
            
            if viewModel.searchedContacts.count > 0 {
                StickyHeaderSection(header: "Contacts.searched")
                    .listRowInsets(.zero)
                ForEach(viewModel.searchedContacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: true)
                }
                .padding()
            }

            ForEach(viewModel.contacts) { contact in
                ContactRowContainer(contact: contact, isSearchRow: false)
            }
            .padding()
            .listRowInsets(.zero)
            
            ListLoadingView(isLoading: $viewModel.isLoading)
                .id(-2)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
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
        .sheet(isPresented: $viewModel.showAddOrEditContactSheet) {
            AddOrEditContactView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showConversaitonBuilder) {
            viewModel.showConversaitonBuilder = false
        } content: {
            ConversationBuilder()
        }
    }
    
    @ViewBuilder var leadingViews: some View {
        ToolbarButtonItem(imageName: "list.bullet", hint: "General.select") {
            withAnimation {
                viewModel.isInSelectionMode.toggle()
            }
        }

        if !viewModel.showConversaitonBuilder {
            ToolbarButtonItem(imageName: "trash.fill", hint: "General.delete") {
                withAnimation {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteContactView().environmentObject(viewModel))
                }
            }
            .foregroundStyle(.red)
            .opacity(viewModel.isInSelectionMode ? 1 : 0.2)
            .disabled(!viewModel.isInSelectionMode)
            .scaleEffect(x: viewModel.isInSelectionMode ? 1.0 : 0.002, y: viewModel.isInSelectionMode ? 1.0 : 0.002)
        }
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
    @EnvironmentObject var threadsViewModel: ThreadsViewModel
    let contact: Contact
    let isSearchRow: Bool
    var separatorColor: Color {
        if !isSearchRow {
           return viewModel.contacts.last == contact ? Color.clear : Color.App.divider
        } else {
            return viewModel.searchedContacts.last == contact ? Color.clear : Color.App.divider
        }
    }

    var body: some View {
        ContactRow(isInSelectionMode: $viewModel.isInSelectionMode, contact: contact)
            .id("\(isSearchRow ? "SearchRow" : "Normal")\(contact.id ?? 0)")
            .animation(.spring(), value: viewModel.isInSelectionMode)
            .listRowBackground(Color.App.bgPrimary)
            .listRowSeparatorTint(separatorColor)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !viewModel.isInSelectionMode {
                    Button {
                        viewModel.editContact = contact
                        viewModel.showAddOrEditContactSheet.toggle()
                    } label: {
                        Label("General.edit", systemImage: "pencil")
                    }
                    .tint(Color.App.hint)

                    Button {
                        viewModel.block(contact)
                    } label: {
                        Label("General.block", systemImage: "hand.raised.slash")
                    }
                    .tint(Color.App.red)

                    Button {
                        viewModel.addToSelctedContacts(contact)
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(
                            DeleteContactView()
                                .environmentObject(viewModel)
                                .onDisappear {
                                    viewModel.removeToSelctedContacts(contact)
                                }
                        )
                    } label: {
                        Label("General.delete", systemImage: "trash")
                    }
                    .tint(.red)
                }
            }
            .onAppear {
                if viewModel.contacts.last == contact {
                    viewModel.loadMore()
                }
            }
            .onTapGesture {
                if viewModel.isInSelectionMode {
                    viewModel.toggleSelectedContact(contact: contact)
                } else {
                    viewModel.closeConversationContextMenu = true
                    viewModel.closeBuilder()
                    AppState.shared.openThread(contact: contact)
                }
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
