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
    @EnvironmentObject var contactsVM: ContactsViewModel
    var onCompleted: ([Contact]) -> Void

    var body: some View {
        List {
            if contactsVM.searchedContacts.count > 0 {
                ForEach(contactsVM.searchedContacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: true)
                }
            } else {
                ForEach(contactsVM.contacts) { contact in
                    ContactRowContainer(contact: contact, isSearchRow: false)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SubmitBottomButton(text: "General.add", enableButton: .constant(contactsVM.selectedContacts.count > 0), isLoading: .constant(false)) {
                onCompleted(contactsVM.selectedContacts)
                contactsVM.deselectContacts() // to clear for the next time
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
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
                    .background(Color.App.separator)
                    .foregroundStyle(Color.App.hint)
            }
            .frame(height: 78)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            /// We use ContactRowContainer view because it is essential to force the ineer contactRow View to show radio buttons.
            contactsVM.isInSelectionMode = true
        }
        .onDisappear {
            contactsVM.isInSelectionMode = false
        }
    }
}

struct StartThreadResultModel_Previews: PreviewProvider {
    static var previews: some View {
        AddParticipantsToThreadView() { _ in
        }
        .environmentObject(ContactsViewModel())
        .preferredColorScheme(.dark)
    }
}
