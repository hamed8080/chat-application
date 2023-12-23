//
//  UserActionMenu.swift
//  Talk
//
//  Created by hamed on 11/1/23.
//

import SwiftUI
import TalkViewModels
import ChatModels

struct UserActionMenu: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @EnvironmentObject var contactViewModel: ContactsViewModel
    let participant: Participant

    var body: some View {
        Divider()
        if participant.contactId == nil {
            Button {
                let contact = Contact(cellphoneNumber: participant.cellphoneNumber,
                                      email: participant.email,
                                      firstName: participant.firstName,
                                      lastName: participant.lastName,
                                      user: .init(username: participant.username))
                contactViewModel.addContact = contact
                contactViewModel.showAddOrEditContactSheet = true
            } label: {
                Label("General.add", systemImage: "person.badge.plus")
            }
        }

        Button {
            if participant.blocked == true, let contactId = participant.contactId {
                contactViewModel.unblockWith(contactId)
            } else {
                contactViewModel.block(.init(id: participant.contactId))
            }
        } label: {
            Label(participant.blocked == true ? "General.unblock" : "General.block", systemImage: participant.blocked == true ? "hand.raised.slash" : "hand.raised")
        }

        if EnvironmentValues.isTalkTest {
            Button {

            } label: {
                Label("General.share", systemImage: "square.and.arrow.up")
            }
            .disabled(true)

            Button {

            } label: {
                Label("Thread.export", systemImage: "tray.and.arrow.up")
            }
            .disabled(true)
        }

        if participant.contactId != nil {
            Button(role: .destructive) {
                contactViewModel.delete(.init(id: participant.contactId))
            } label: {
                Label("Contacts.delete", systemImage: "trash")
            }
        }
    }
}

struct UserActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        UserActionMenu(participant: .init(name: "Hamed Hosseini"))
    }
}
