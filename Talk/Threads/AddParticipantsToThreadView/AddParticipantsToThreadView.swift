//
//  AddParticipantsToThreadView.swift
//  Talk
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Chat
import ChatModels
import SwiftUI
import TalkViewModels
import TalkUI

struct AddParticipantsToThreadView: View {
    @StateObject var viewModel: AddParticipantsToViewModel
    @EnvironmentObject var contactsVM: ContactsViewModel
    var onCompleted: ([Contact]) -> Void

    var body: some View {
        List {
            if contactsVM.searchedContacts.count > 0 {
                ForEach(contactsVM.searchedContacts) { contact in
                    StartThreadContactRow(isInMultiSelectMode: .constant(true), contact: contact)
                        .listRowBackground(Color.bgColor)
                        .listRowSeparatorTint(Color.dividerDarkerColor)
                }
            } else {
                ForEach(contactsVM.contacts) { contact in
                    StartThreadContactRow(isInMultiSelectMode: .constant(true), contact: contact)
                        .listRowBackground(Color.bgColor)
                        .listRowSeparatorTint(Color.dividerDarkerColor)
                        .onAppear {
                            if contactsVM.contacts.last == contact {
                                contactsVM.loadMore()
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: contactsVM.contacts.count)
        .animation(.easeInOut, value: contactsVM.searchedContacts.count)
        .safeAreaInset(edge: .bottom) {
            EmptyView()
                .frame(height: 72)
        }
        .safeAreaInset(edge: .top) {
            EmptyView()
                .frame(height: 74)
        }
        .overlay(alignment: .bottom) {
            SubmitBottomButton(text: "General.add", enableButton: .constant(contactsVM.selectedContacts.count > 0), isLoading: .constant(false)) {
                onCompleted(contactsVM.selectedContacts)
            }
        }
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("General.searchHere", text: $contactsVM.searchContactString)
                    .frame(height: 48)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Spacer()
                Text("General.add")
                    .frame(height: 30)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .background(Color.bgSpaceItem)
                    .foregroundStyle(Color.hint)
            }
            .frame(height: 78)
            .background(.ultraThinMaterial)
        }
    }
}

struct StartThreadResultModel_Previews: PreviewProvider {
    static var previews: some View {
        AddParticipantsToThreadView(viewModel: .init()) { _ in
        }
        .environmentObject(ContactsViewModel())
        .preferredColorScheme(.dark)
    }
}
