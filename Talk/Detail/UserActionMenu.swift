//
//  UserActionMenu.swift
//  Talk
//
//  Created by hamed on 11/1/23.
//

import SwiftUI
import TalkViewModels
import ChatModels
import ActionableContextMenu

struct UserActionMenu: View {
    @EnvironmentObject var viewModel: DetailViewModel
    @EnvironmentObject var contactViewModel: ContactsViewModel
    let participant: Participant

    var body: some View {
        Divider()
        if participant.contactId == nil {
            ContextMenuButton(title: "General.add", image: "person.badge.plus") {
                let contact = Contact(cellphoneNumber: participant.cellphoneNumber,
                                      email: participant.email,
                                      firstName: participant.firstName,
                                      lastName: participant.lastName,
                                      user: .init(username: participant.username))
                contactViewModel.addContact = contact
                contactViewModel.showAddOrEditContactSheet = true
            }
        }

        ContextMenuButton(title: participant.blocked == true ? "General.unblock" : "General.block", image: participant.blocked == true ? "hand.raised.slash" : "hand.raised") {
            if participant.blocked == true, let contactId = participant.contactId {
                contactViewModel.unblockWith(contactId)
            } else {
                contactViewModel.block(.init(id: participant.contactId))
            }
        }

        if EnvironmentValues.isTalkTest {
            ContextMenuButton(title: "General.share", image: "square.and.arrow.up") {

            }
            .disabled(true)

            ContextMenuButton(title: "Thread.export", image: "tray.and.arrow.up") {

            }
            .disabled(true)
        }

        if participant.contactId != nil {
            ContextMenuButton(title: "Contacts.delete", image: "trash", iconColor: Color.App.red) {
                contactViewModel.delete(.init(id: participant.contactId))
            }
            .foregroundStyle(Color.App.red)
        }
    }
}

struct UserActionMenu_Previews: PreviewProvider {
    static var previews: some View {
        UserActionMenu(participant: .init(name: "Hamed Hosseini"))
    }
}
