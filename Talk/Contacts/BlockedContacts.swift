//
//  BlockedContacts.swift
//  Talk
//
//  Created by hamed on 6/11/23.
//

import Chat
import SwiftUI
import TalkViewModels

struct BlockedContacts: View {
    @EnvironmentObject var viewModel: ContactsViewModel

    var body: some View {
        List(viewModel.blockedContacts, id: \.blockId) { blocked in
            VStack(alignment: .leading) {
                Text((blocked.nickName ?? blocked.contact?.firstName) ?? "")
                ActionButton(iconSfSymbolName: "hand.raised.slash", iconColor: .red) {
                    ChatManager.activeInstance?.contact.unBlock(.init(blockId: blocked.blockId))
                }
            }
        }
        .navigationTitle("Contacts.blockedList")
        .listStyle(.plain)
    }
}

struct BlockedContacts_Previews: PreviewProvider {
    static var previews: some View {
        BlockedContacts()
    }
}
