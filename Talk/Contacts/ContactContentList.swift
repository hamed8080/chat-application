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
                    Text("\(viewModel.maxContactsCountInServer)")
                        .font(.iransansBoldBody)
                    Spacer()
                }
                .noSeparators()
            }

            SyncView()

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
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 48)
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
        .dialog(.init(localized: .init("Contacts.deleteSelectedTitle")), .init(localized: .init("Contacts.deleteSelectedSubTitle")), "trash", $deleteDialog) { _ in
            viewModel.deleteSelectedItems()
        }
    }

  @ViewBuilder var leadingViews: some View {
        Button {
            isInSelectionMode.toggle()
        } label: {
            Image(systemName: "filemenu.and.selection")
                .accessibilityHint("General.select")
        }

        NavigationLink {
            BlockedContacts()
        } label: {
            Image(systemName: "hand.raised.slash")
                .accessibilityHint("General.blocked")
        }

        Button {
            deleteDialog.toggle()
        } label: {
            Image(systemName: "trash")
                .accessibilityHint("General.delete")
                .foregroundColor(Color.red)
        }
        .opacity(isInSelectionMode ? 1 : 0.5)
        .disabled(!isInSelectionMode)
    }

    @ViewBuilder var centerViews: some View {
        ConnectionStatusToolbar()
    }

    @ViewBuilder var trailingViews: some View {
        Button {
            modifyContactSheet.toggle()
        } label: {
            Image(systemName: "person.badge.plus")
                .accessibilityHint("Contacts.createNew")
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
