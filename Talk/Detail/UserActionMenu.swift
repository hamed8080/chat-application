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
        if participant.contactId == nil {
            Button {
                contactViewModel.addContact(contactValue: participant.username ?? "",
                                            firstName: participant.firstName,
                                            lastName: participant.lastName)
            } label: {
                Label("General.add", systemImage: "person.badge.plus")
            }
        }

        Button {
            contactViewModel.block(.init(id: participant.contactId))
        } label: {
            Label("General.block", systemImage: "hand.raised")
        }

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

        if participant.contactId != nil {
            Button(role: .destructive) {
                contactViewModel.delete(.init(id: participant.contactId))
            } label: {
                Label("General.delete", systemImage: "trash")
            }
        }
    }
}

struct UserActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        UserActionMenu(participant: .init(name: "Hamed Hosseini"))
    }
}
