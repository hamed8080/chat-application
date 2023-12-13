//
//  StartThreadContactPickerView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import AdditiveUI
import Chat
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct StartThreadContactPickerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List {
            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
            if viewModel.searchedContacts.count == 0 {
                Button {
                    dismiss()
                    Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
                        viewModel.createConversationType = .normal
                        viewModel.showConversaitonBuilder.toggle()
                    }
                } label: {
                    Label("Contacts.createGroup", systemImage: "person.2")
                        .foregroundStyle(Color.App.primary)
                }
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparatorTint(Color.App.divider)

                Button {
                    dismiss()
                    Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
                        viewModel.createConversationType = .channel
                        viewModel.showConversaitonBuilder.toggle()
                    }
                } label: {
                    Label("Contacts.createChannel", systemImage: "megaphone")
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
            }

            StickyHeaderSection(header: "Contacts.sortLabel")
                .listRowInsets(.zero)
            ForEach(viewModel.contacts) { contact in
                ContactRowContainer(contact: contact, isSearchRow: false)
            }

            ListLoadingView(isLoading: $viewModel.isLoading)
                .listRowBackground(Color.App.bgPrimary)
                .listRowSeparator(.hidden)
        }
        .environment(\.defaultMinListRowHeight, 24)
        .animation(.easeInOut, value: viewModel.contacts)
        .animation(.easeInOut, value: viewModel.searchedContacts)
        .animation(.easeInOut, value: viewModel.isLoading)
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("General.searchHere", text: $viewModel.searchContactString)
                    .frame(height: 48)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .frame(height: 48)
            .background(.ultraThinMaterial)
        }
    }
}


struct StartThreadContactPickerView_Previews: PreviewProvider {
    static var previews: some View {
        let contactVM = ContactsViewModel()
        StartThreadContactPickerView()
            .environmentObject(contactVM)
            .preferredColorScheme(.dark)
    }
}
